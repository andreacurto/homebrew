// Package menu implementa il menù principale navigabile di Donkey.
package menu

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/tui/style"
)

type entry struct {
	title string
	desc  string
}

// Le voci del menù principale (vedi AGENTS.md §2.2).
var entries = []entry{
	{"App", "Installa o disinstalla singole app"},
	{"Terminale", "Personalizza il terminale con tema, font e autocompletamento"},
	{"Update manuale", "Aggiorna ora app e librerie"},
	{"Update automatico", "Gestisci l'aggiornamento automatico di app e librerie"},
	{"Status", "Lo stato di Donkey a colpo d'occhio"},
}

// Model è lo stato del menù principale.
type Model struct {
	cursor   int
	chosen   string // se valorizzato, mostra il placeholder della voce scelta
	quitting bool
	spin     spinner.Model
}

// New crea il modello del menù.
func New() Model {
	return Model{spin: style.NewSpinner()}
}

// Init avvia lo spinner.
func (m Model) Init() tea.Cmd {
	return m.spin.Tick
}

// Update gestisce input da tastiera e animazioni.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		return m.handleKey(msg)
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m Model) handleKey(key tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch key.String() {
	case "ctrl+c", "q":
		m.quitting = true
		return m, tea.Quit
	case "esc":
		if m.chosen != "" {
			m.chosen = "" // dalla vista placeholder si torna al menù
			return m, nil
		}
		m.quitting = true
		return m, tea.Quit
	}

	// Nella vista placeholder ignoriamo la navigazione.
	if m.chosen != "" {
		return m, nil
	}

	switch key.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(entries)-1 {
			m.cursor++
		}
	case "enter":
		m.chosen = entries[m.cursor].title
	}
	return m, nil
}

// View disegna la schermata corrente.
func (m Model) View() string {
	if m.quitting {
		return ""
	}
	if m.chosen != "" {
		return m.placeholderView()
	}
	return m.menuView()
}

func (m Model) menuView() string {
	var b strings.Builder
	b.WriteString(style.Brand("Il tuo Mac, pronto all'uso senza pensieri.", style.Tagline))
	b.WriteString("\n\n")

	for i, e := range entries {
		marker := "  "
		titleStyle := style.ItemTitle
		descStyle := style.ItemDesc
		if i == m.cursor {
			marker = style.SymCursor + " "
			titleStyle = style.ItemTitleSel
			descStyle = style.ItemDescSel
		}
		b.WriteString(style.Cursor.Render(marker))
		b.WriteString(titleStyle.Width(24).Render(fmt.Sprintf("%d. %s", i+1, e.title)))
		b.WriteString(descStyle.Render(e.desc))
		b.WriteString("\n")
	}

	b.WriteString("\n")
	b.WriteString(style.Footer.Render("↑↓ · Invio · U Disinstalla · V Versione · Q Esci"))
	return style.Screen.Render(b.String())
}

func (m Model) placeholderView() string {
	var b strings.Builder
	b.WriteString(style.Brand(m.chosen, style.Heading))
	b.WriteString("\n\n")
	b.WriteString(m.spin.View())
	b.WriteString(" ")
	b.WriteString(style.ItemDesc.Render("Questa vista arriverà presto."))
	b.WriteString("\n\n")
	b.WriteString(style.Footer.Render("Esc · torna al menù    Q · esci"))
	return style.Screen.Render(b.String())
}
