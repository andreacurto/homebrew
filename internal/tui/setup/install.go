package setup

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// installTickMsg segna il completamento (simulato) del task corrente: l'installer
// avanza al successivo. Per ora è tutto finto — nessun comando reale gira.
type installTickMsg struct{}

// Ritmo della simulazione: le voci di una raccolta (app/font…) scorrono veloci,
// i passi singoli (Homebrew, terminale…) pesano di più. Tarabili.
const (
	collectionDelay = 120 * time.Millisecond
	singletonDelay  = 600 * time.Millisecond
)

// instState è lo stato di una fase rispetto al puntatore di avanzamento.
type instState int

const (
	instPending instState = iota
	instRunning
	instDone
)

// instPhase è un blocco della checklist di installazione. Una fase "collection"
// (App, Strumenti, Font) ha più voci, mostra un contatore e la voce corrente;
// una fase singola (Homebrew, Tema, Terminale, Auto-update) è un passo solo.
type instPhase struct {
	name       string
	items      []string // etichette dei sotto-passi; per le singole una voce fittizia
	collection bool
}

// installer esegue la checklist in modo sequenziale e simulato: il puntatore
// (pi, ii) indica la fase e la voce attualmente in lavorazione.
type installer struct {
	phases []instPhase
	pi, ii int  // fase corrente, voce corrente
	done   bool // tutte le fasi completate
}

// newInstaller compone la checklist dalle scelte del wizard. Homebrew e la
// configurazione del terminale ci sono sempre; il resto è condizionale.
func newInstaller(m Model) installer {
	single := func(name string) instPhase { return instPhase{name: name, items: []string{""}} }
	collection := func(name string, items []string) instPhase {
		return instPhase{name: name, items: items, collection: true}
	}

	ph := []instPhase{single("Homebrew")}
	if labels := m.apps.chosenLabels(); len(labels) > 0 {
		ph = append(ph, collection("App", labels))
	}
	if labels := m.tools.chosenLabels(); len(labels) > 0 {
		ph = append(ph, collection("Strumenti terminale", labels))
	}
	if labels := m.fonts.chosenLabels(); len(labels) > 0 {
		ph = append(ph, collection("Font terminale", labels))
	}
	if m.theme.selectionValue() != "" {
		ph = append(ph, single("Tema terminale"))
	}
	ph = append(ph, single("Configurazione terminale"))
	if m.auto {
		ph = append(ph, single("Aggiornamenti automatici"))
	}
	return installer{phases: ph}
}

// tick programma il completamento del task corrente dopo un ritardo simulato.
func (in installer) tick() tea.Cmd {
	delay := singletonDelay
	if in.pi < len(in.phases) && in.phases[in.pi].collection {
		delay = collectionDelay
	}
	return tea.Tick(delay, func(time.Time) tea.Msg { return installTickMsg{} })
}

// advance segna come completata la voce corrente e sposta il puntatore alla
// prossima; esaurite tutte le fasi, l'installazione è finita.
func (in *installer) advance() {
	in.ii++
	if in.ii >= len(in.phases[in.pi].items) {
		in.pi++
		in.ii = 0
	}
	if in.pi >= len(in.phases) {
		in.done = true
	}
}

// stateOf classifica una fase rispetto al puntatore di avanzamento.
func (in installer) stateOf(p int) instState {
	switch {
	case in.done || p < in.pi:
		return instDone
	case p == in.pi:
		return instRunning
	default:
		return instPending
	}
}

// render disegna la checklist ibrida: una riga per fase con marcatore e (per le
// raccolte) contatore; sotto la fase attiva, la voce in lavorazione.
func (in installer) render(spin spinner.Model) string {
	var b strings.Builder
	for p := range in.phases {
		ph := in.phases[p]
		st := in.stateOf(p)

		var marker, name string
		switch st {
		case instDone:
			marker = style.ItemDesc.Render(style.SymSuccess)
			name = style.ItemDesc.Render(ph.name)
		case instRunning:
			marker = spin.View()
			name = style.ItemTitleSel.Render(ph.name)
		default:
			marker = style.ItemDesc.Render(style.SymOff)
			name = style.ItemDesc.Render(ph.name)
		}

		line := "  " + marker + " " + name
		if ph.collection {
			total := len(ph.items)
			done := 0
			switch st {
			case instDone:
				done = total
			case instRunning:
				done = in.ii
			}
			line += style.Footer.Render(fmt.Sprintf("  %d/%d", done, total))
		}
		b.WriteString(line + "\n")

		// Sotto la raccolta attiva, il nome della voce che sta "installando".
		if st == instRunning && ph.collection && in.ii < len(ph.items) {
			b.WriteString("      " + style.Cursor.Render(style.SymCursor) + " " +
				style.ItemTitle.Render(ph.items[in.ii]) + "\n")
		}
	}
	return strings.TrimRight(b.String(), "\n")
}
