// Package menu implementa il menù principale navigabile di Donkey.
package menu

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

type entry struct {
	title string
	desc  string
}

// Le voci del menù principale (vedi AGENTS.md §2.2).
var entries = []entry{
	{"App", "Installa o disinstalla singole app"},
	{"Terminal", "Tema, font e autocompletamento"},
	{"Update", "Aggiorna e fai ordine in Homebrew"},
	{"Auto-update", "Gestisci l'aggiornamento automatico"},
	{"Status", "Lo stato del tuo Mac a colpo d'occhio"},
}

// Model è lo stato del menù principale.
type Model struct {
	cursor   int
	chosen   string // se valorizzato, mostra il placeholder della voce scelta
	quitting bool
}

// New crea il modello del menù.
func New() Model { return Model{} }

// Init soddisfa tea.Model.
func (m Model) Init() tea.Cmd { return nil }

// Update gestisce gli input da tastiera.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	key, ok := msg.(tea.KeyMsg)
	if !ok {
		return m, nil
	}

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
	b.WriteString(header())
	b.WriteString("\n\n")

	for i, e := range entries {
		marker := "  "
		titleStyle := style.ItemTitle
		if i == m.cursor {
			marker = "▸ "
			titleStyle = style.ItemTitleSel
		}
		b.WriteString(style.Cursor.Render(marker))
		b.WriteString(titleStyle.Width(20).Render(fmt.Sprintf("%d. %s", i+1, e.title)))
		b.WriteString(style.ItemDesc.Render(e.desc))
		b.WriteString("\n")
	}

	b.WriteString("\n")
	b.WriteString(style.Footer.Render("↑↓ · Invio · U Disinstalla · V Versione · Q Esci"))
	return style.Screen.Render(b.String())
}

func (m Model) placeholderView() string {
	var b strings.Builder
	b.WriteString(style.Heading.Render(m.chosen))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Questa vista arriverà presto."))
	b.WriteString("\n\n")
	b.WriteString(style.Footer.Render("Esc · torna al menù    Q · esci"))
	return style.Screen.Render(b.String())
}

func header() string {
	logo := style.Logo.Render("Donkey")
	tagline := style.Tagline.Render("Allestisci il tuo Mac. Tienilo fresco.")
	url := style.URL.Render("github.com/andreacurto/donkey")
	return lipgloss.JoinVertical(lipgloss.Left, logo, tagline, url)
}
