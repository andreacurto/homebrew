// Package setup implementa il wizard di onboarding di Donkey (vedi AGENTS.md §2.1).
package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

type step int

const (
	stepWelcome step = iota
	stepApps
	stepNext // placeholder: il resto del wizard arriva nei prossimi passi
)

// catalogMsg trasporta l'esito del download di un catalogo.
type catalogMsg struct {
	entries []catalog.Entry
	err     error
}

func loadApps() tea.Cmd {
	return func() tea.Msg {
		e, err := catalog.Fetch(catalog.Apps)
		return catalogMsg{entries: e, err: err}
	}
}

// Model è lo stato del wizard di setup.
type Model struct {
	step       step
	spin       spinner.Model
	loading    bool
	loadErr    error
	apps       checklist
	appsLoaded bool
	quitting   bool
}

// New crea il modello del wizard.
func New() Model {
	return Model{spin: style.NewSpinner()}
}

// Init avvia lo spinner.
func (m Model) Init() tea.Cmd {
	return m.spin.Tick
}

// Update gestisce input, animazioni e caricamento cataloghi.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd
	case catalogMsg:
		m.loading = false
		if msg.err != nil {
			m.loadErr = msg.err
			return m, nil
		}
		m.apps = newChecklist(msg.entries)
		m.appsLoaded = true
		return m, nil
	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m Model) handleKey(key tea.KeyMsg) (tea.Model, tea.Cmd) {
	if key.String() == "ctrl+c" {
		m.quitting = true
		return m, tea.Quit
	}

	switch m.step {
	case stepWelcome:
		switch key.String() {
		case "enter":
			m.step = stepApps
			if !m.appsLoaded && m.loadErr == nil {
				m.loading = true
				return m, loadApps()
			}
		case "esc", "q":
			m.quitting = true
			return m, tea.Quit
		}

	case stepApps:
		if m.loading {
			if key.String() == "esc" {
				m.step = stepWelcome
			}
			return m, nil
		}
		switch key.String() {
		case "up", "k":
			m.apps.up()
		case "down", "j":
			m.apps.down()
		case " ":
			m.apps.toggle()
		case "enter":
			if m.loadErr == nil {
				m.step = stepNext
			}
		case "esc":
			m.step = stepWelcome
		}

	case stepNext:
		switch key.String() {
		case "esc":
			m.step = stepApps
		case "q":
			m.quitting = true
			return m, tea.Quit
		}
	}
	return m, nil
}

// View disegna la schermata corrente.
func (m Model) View() string {
	if m.quitting {
		return ""
	}
	switch m.step {
	case stepWelcome:
		return m.welcomeView()
	case stepApps:
		return m.appsView()
	default:
		return m.nextView()
	}
}

func (m Model) welcomeView() string {
	var b strings.Builder
	b.WriteString(style.Brand("Setup", style.Heading))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Benvenuto! In pochi passi preparo il tuo Mac:"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("  • Homebrew e gli strumenti base"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("  • le app e i font che scegli"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("  • il terminale (tema e autocompletamento)"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("  • l'aggiornamento automatico, se vuoi"))
	b.WriteString("\n\n")
	b.WriteString(style.Footer.Render("Invio · inizia    Esc · esci"))
	return style.Screen.Render(b.String())
}

func (m Model) appsView() string {
	var b strings.Builder
	b.WriteString(style.Brand("Setup · App", style.Heading))
	b.WriteString("\n\n")

	switch {
	case m.loading:
		b.WriteString(m.spin.View() + " " + style.ItemDesc.Render("Carico il catalogo…"))
		b.WriteString("\n\n")
		b.WriteString(style.Footer.Render("Esc · indietro"))

	case m.loadErr != nil:
		b.WriteString(style.Error.Render(style.SymError + " Impossibile caricare il catalogo."))
		b.WriteString("\n")
		b.WriteString(style.ItemDesc.Render(m.loadErr.Error()))
		b.WriteString("\n\n")
		b.WriteString(style.Footer.Render("Esc · indietro"))

	default:
		b.WriteString(style.ItemDesc.Render("Scegli le app da installare:"))
		b.WriteString("\n\n")
		b.WriteString(m.apps.view())
		b.WriteString("\n")
		b.WriteString(style.Footer.Render(fmt.Sprintf(
			"↑↓ · Spazio seleziona · Invio continua · Esc indietro    (%d selezionate)",
			len(m.apps.chosen()),
		)))
	}
	return style.Screen.Render(b.String())
}

func (m Model) nextView() string {
	var b strings.Builder
	b.WriteString(style.Brand("Setup", style.Heading))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(fmt.Sprintf("Hai scelto %d app. 👍", len(m.apps.chosen()))))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Il resto del wizard (font, terminale, auto-update,\nriepilogo, installazione) arriva nei prossimi passi."))
	b.WriteString("\n\n")
	b.WriteString(style.Footer.Render("Esc · indietro    Q · esci"))
	return style.Screen.Render(b.String())
}
