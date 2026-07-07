package setup

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// installTickMsg segna il completamento (simulato) di un sotto-passo: l'installer
// avanza e la fase corrente prosegue. Per ora è tutto finto — nessun comando
// reale gira.
type installTickMsg struct{}

// Ritmo della simulazione. Le raccolte (app/font…) avanzano di un passo per voce;
// i passi singoli (preparazione, tema, terminale…) hanno più sotto-passi solo per
// far durare un attimo lo spinner. Tarabili.
const (
	collectionDelay = 120 * time.Millisecond
	singletonTicks  = 6
	singletonDelay  = 90 * time.Millisecond
)

// Agganci TEMPORANEI di sola simulazione per valutare gli stati di esito nella
// schermata finale. Vanno rimossi quando si collegheranno i comandi reali.
//   - simulateFontWarning: fa fallire un font (esito ▲ avviso sulla riga Font).
//   - simulateToolsError: fa fallire tutti gli strumenti (esito ✗ errore).
const (
	simulateFontWarning = true
	simulateToolsError  = false
)

// instState è lo stato di una fase rispetto al puntatore di avanzamento.
type instState int

const (
	instPending instState = iota
	instRunning
	instDone
)

// instOutcome è l'esito di una fase conclusa.
type instOutcome int

const (
	outSuccess instOutcome = iota
	outWarning             // raccolta completata solo in parte
	outError               // fase non riuscita (o raccolta tutta fallita)
)

// instPhase è un blocco della checklist.
//   - name:  etichetta d'azione mostrata durante l'installazione ("Installazione App")
//   - recap: etichetta breve per la tabella finale ("App"), come nel pre-installazione
//   - items: etichette degli elementi (vuoto per le fasi singole)
//   - failed: elementi non installati (sottoinsieme di items); per una fase singola,
//     se non vuoto la fase è considerata fallita
type instPhase struct {
	name   string
	recap  string
	items  []string
	failed []string
	ticks  int
	delay  time.Duration
}

// outcome deduce l'esito della fase dagli elementi falliti.
func (ph instPhase) outcome() instOutcome {
	if len(ph.failed) == 0 {
		return outSuccess
	}
	if len(ph.items) == 0 || len(ph.failed) >= len(ph.items) {
		return outError
	}
	return outWarning
}

// installer esegue la checklist in modo sequenziale e simulato: pi è la fase
// corrente, prog i sotto-passi già completati in quella fase.
type installer struct {
	phases []instPhase
	pi     int
	prog   int
	done   bool
}

// newInstaller compone la checklist dalle scelte del wizard. La preparazione e
// la configurazione del terminale ci sono sempre; il resto è condizionale.
// Nessuna fase cita Homebrew: per l'utente è tutto "Donkey".
func newInstaller(m Model) installer {
	single := func(name, recap string) instPhase {
		return instPhase{name: name, recap: recap, ticks: singletonTicks, delay: singletonDelay}
	}
	collection := func(name, recap string, items []string) instPhase {
		return instPhase{name: name, recap: recap, items: items, ticks: len(items), delay: collectionDelay}
	}

	ph := []instPhase{single("Installazione Donkey", "Donkey")}
	if items := m.apps.chosenLabels(); len(items) > 0 {
		ph = append(ph, collection("Installazione App", "App", items))
	}
	if items := m.tools.chosenLabels(); len(items) > 0 {
		tools := collection("Installazione Strumenti terminale", "Strumenti terminale", items)
		if simulateToolsError {
			tools.failed = append([]string(nil), items...) // simula: tutti gli strumenti falliti
		}
		ph = append(ph, tools)
	}
	if items := m.fonts.chosenLabels(); len(items) > 0 {
		fonts := collection("Installazione Font", "Font terminale", items)
		if simulateFontWarning {
			fonts.failed = []string{items[len(items)-1]} // simula: un font non installato
		}
		ph = append(ph, fonts)
	}
	if m.theme.selectionValue() != "" {
		ph = append(ph, single("Configurazione tema", "Tema terminale"))
	}
	ph = append(ph, single("Configurazione terminale", "Terminale"))
	if m.auto {
		ph = append(ph, single("Configurazione aggiornamenti automatici", "Aggiornamenti automatici"))
	}
	return installer{phases: ph}
}

// tick programma il prossimo sotto-passo dopo il ritardo della fase corrente.
func (in installer) tick() tea.Cmd {
	if in.pi >= len(in.phases) {
		return nil
	}
	d := in.phases[in.pi].delay
	return tea.Tick(d, func(time.Time) tea.Msg { return installTickMsg{} })
}

// advance completa un sotto-passo; esaurita la fase passa alla successiva, ed
// esaurite tutte le fasi l'installazione è conclusa.
func (in *installer) advance() {
	if in.pi >= len(in.phases) {
		in.done = true
		return
	}
	in.prog++
	if in.prog >= in.phases[in.pi].ticks {
		in.pi++
		in.prog = 0
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

// render disegna la checklist in corso: una riga per fase con marcatore e nome.
// Niente percentuali: la fase in corso è lo spinner, l'esito è ✓/▲/✗.
//   - ✓ aquamarine + nome crema = fatto
//   - ▲ cheddar    + nome crema = fatto con avviso
//   - ✗ coral      + nome crema = non riuscito
//   - spinner      + nome coral = in lavorazione
//   - ○ ash        + nome ash   = in attesa
func (in installer) render(spin spinner.Model) string {
	var b strings.Builder
	for i, ph := range in.phases {
		switch in.stateOf(i) {
		case instRunning:
			marker := lipgloss.NewStyle().Width(2).Render(spin.View())
			name := lipgloss.NewStyle().Foreground(style.Coral).Bold(true).Render(ph.name)
			b.WriteString("  " + marker + " " + name + "\n")
		case instDone:
			sym, col := outcomeMarker(ph.outcome())
			name := lipgloss.NewStyle().Foreground(style.Cream).Render(ph.name)
			b.WriteString("  " + markerCell(sym, col) + " " + name + "\n")
		default:
			name := lipgloss.NewStyle().Foreground(style.Ash).Render(ph.name)
			b.WriteString("  " + markerCell(style.SymOff, style.Ash) + " " + name + "\n")
		}
	}
	return strings.TrimRight(b.String(), "\n")
}

// recapTable disegna la tabella finale: etichetta breve (ash) a sinistra, esito
// colorato a destra. Nessuna indentazione, nessun conteggio: solo lo stato.
func (in installer) recapTable() string {
	labelW := 0
	for _, ph := range in.phases {
		if w := lipgloss.Width(ph.recap); w > labelW {
			labelW = w
		}
	}
	labelW += 3

	var b strings.Builder
	for _, ph := range in.phases {
		o := ph.outcome()
		sym, col := outcomeMarker(o)
		esito := lipgloss.NewStyle().Foreground(col).Render(sym + " " + outcomeText(o))
		label := style.ItemDesc.Width(labelW).Render(ph.recap)
		b.WriteString(label + esito + "\n")
	}
	return strings.TrimRight(b.String(), "\n")
}

// recapDetails elenca, per ogni fase non riuscita del tutto o in parte, cosa
// esattamente non è stato installato. Avvisi in cheddar, errori in coral.
// Stringa vuota se è filato tutto liscio.
func (in installer) recapDetails() string {
	var lines []string
	for _, ph := range in.phases {
		switch ph.outcome() {
		case outWarning:
			lines = append(lines, style.Alert.Render(fmt.Sprintf(
				"%s %s — non è stato possibile installare: %s",
				style.SymWarning, ph.recap, strings.Join(ph.failed, ", "))))
		case outError:
			if len(ph.items) > 0 {
				lines = append(lines, style.Error.Render(fmt.Sprintf(
					"%s %s — non è stato possibile installare: %s",
					style.SymError, ph.recap, strings.Join(ph.failed, ", "))))
			} else {
				lines = append(lines, style.Error.Render(fmt.Sprintf(
					"%s %s — operazione non riuscita", style.SymError, ph.recap)))
			}
		}
	}
	return strings.Join(lines, "\n")
}

// outcomeMarker: simbolo e colore dell'esito.
func outcomeMarker(o instOutcome) (string, lipgloss.Color) {
	switch o {
	case outWarning:
		return style.SymWarning, style.Cheddar
	case outError:
		return style.SymError, style.Coral
	default:
		return style.SymSuccess, style.Aquamarine
	}
}

// outcomeText: la dicitura di esito mostrata nella tabella finale.
func outcomeText(o instOutcome) string {
	switch o {
	case outWarning:
		return "Installazione completata con avvisi"
	case outError:
		return "Impossibile completare l'installazione"
	default:
		return "Installazione completata"
	}
}

// markerCell rende un simbolo largo 2 celle, così i marcatori a carattere singolo
// (✓ ○ ▲ ✗) restano allineati con lo spinner (emoji largo 2).
func markerCell(sym string, col lipgloss.Color) string {
	return lipgloss.NewStyle().Foreground(col).Width(2).Render(sym)
}
