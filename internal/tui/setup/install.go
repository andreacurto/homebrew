package setup

import (
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// installTickMsg segna il completamento (simulato) di un sotto-passo: l'installer
// avanza e la barra della fase corrente si riempie. Per ora è tutto finto —
// nessun comando reale gira.
type installTickMsg struct{}

// Ritmo della simulazione. Le raccolte (app/font…) avanzano di un passo per voce;
// i passi singoli (preparazione, tema, terminale…) hanno più sotto-passi solo per
// far scorrere la barra in modo fluido. Tarabili.
const (
	collectionDelay = 120 * time.Millisecond
	singletonTicks  = 6
	singletonDelay  = 90 * time.Millisecond
	barWidth        = 20
)

// simulateFontWarning è un aggancio TEMPORANEO di sola simulazione: fa concludere
// la fase Font con un avviso (▲) per poter valutare quello stato nella UX. Va
// rimosso quando si collegheranno i comandi reali.
const simulateFontWarning = true

// instState è lo stato di una fase rispetto al puntatore di avanzamento.
type instState int

const (
	instPending instState = iota
	instRunning
	instDone
)

// instPhase è un blocco della checklist. ticks è il numero di sotto-passi che
// riempiono la barra; warn segna un esito con avviso non bloccante.
type instPhase struct {
	name  string
	ticks int
	delay time.Duration
	warn  bool
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
	single := func(name string) instPhase {
		return instPhase{name: name, ticks: singletonTicks, delay: singletonDelay}
	}
	collection := func(name string, n int) instPhase {
		return instPhase{name: name, ticks: n, delay: collectionDelay}
	}

	ph := []instPhase{single("Preparazione dell'ambiente")}
	if n := len(m.apps.chosenLabels()); n > 0 {
		ph = append(ph, collection("Installazione App", n))
	}
	if n := len(m.tools.chosenLabels()); n > 0 {
		ph = append(ph, collection("Installazione Strumenti terminale", n))
	}
	if n := len(m.fonts.chosenLabels()); n > 0 {
		font := collection("Installazione Font", n)
		font.warn = simulateFontWarning
		ph = append(ph, font)
	}
	if m.theme.selectionValue() != "" {
		ph = append(ph, single("Configurazione tema"))
	}
	ph = append(ph, single("Configurazione terminale"))
	if m.auto {
		ph = append(ph, single("Attivazione aggiornamenti automatici"))
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

// render disegna la checklist: una riga per fase con marcatore, nome e barra.
//   - ✓ aquamarine + nome crema  = fatto
//   - ▲ cheddar   + nome crema   = fatto con avviso
//   - spinner     + nome coral   = in lavorazione (barra parziale)
//   - ○ ash       + nome ash     = in attesa
func (in installer) render(spin spinner.Model) string {
	nameW := 0
	for _, ph := range in.phases {
		if w := lipgloss.Width(ph.name); w > nameW {
			nameW = w
		}
	}

	var b strings.Builder
	for i, ph := range in.phases {
		st := in.stateOf(i)

		var marker, bar string
		var nameStyle lipgloss.Style
		switch st {
		case instDone:
			if ph.warn {
				marker = markerCell(style.SymWarning, style.Cheddar)
				bar = progressBar(1, style.Cheddar)
			} else {
				marker = markerCell(style.SymSuccess, style.Aquamarine)
				bar = progressBar(1, style.Aquamarine)
			}
			nameStyle = lipgloss.NewStyle().Foreground(style.Cream)
		case instRunning:
			marker = lipgloss.NewStyle().Width(2).Render(spin.View())
			bar = progressBar(float64(in.prog)/float64(ph.ticks), style.Coral)
			nameStyle = lipgloss.NewStyle().Foreground(style.Coral).Bold(true)
		default:
			marker = markerCell(style.SymOff, style.Ash)
			bar = progressBar(0, style.Ash)
			nameStyle = lipgloss.NewStyle().Foreground(style.Ash)
		}

		name := nameStyle.Width(nameW).Render(ph.name)
		b.WriteString("  " + marker + " " + name + "   " + bar + "\n")
	}
	return strings.TrimRight(b.String(), "\n")
}

// markerCell rende un simbolo largo 2 celle, così i marcatori a carattere singolo
// (✓ ○ ▲) restano allineati con lo spinner (emoji largo 2).
func markerCell(sym string, col lipgloss.Color) string {
	return lipgloss.NewStyle().Foreground(col).Width(2).Render(sym)
}

// progressBar disegna una barra piena/vuota larga barWidth: la parte piena nel
// colore passato, il binario in ash.
func progressBar(pct float64, fill lipgloss.Color) string {
	n := int(pct*float64(barWidth) + 0.5)
	if n > barWidth {
		n = barWidth
	}
	filled := lipgloss.NewStyle().Foreground(fill).Render(strings.Repeat("█", n))
	track := lipgloss.NewStyle().Foreground(style.Ash).Render(strings.Repeat("░", barWidth-n))
	return filled + track
}
