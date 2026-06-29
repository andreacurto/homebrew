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
	step        step
	spin        spinner.Model
	loading     bool
	loadErr     error
	apps        checklist
	appsLoaded  bool
	confirmQuit bool // mostra la conferma d'uscita (Esc da qualunque schermata)
	quitting    bool
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
	k := key.String()

	if k == "ctrl+c" {
		m.quitting = true
		return m, tea.Quit
	}

	// La conferma d'uscita ha la precedenza su tutto.
	if m.confirmQuit {
		switch k {
		case "s", "S":
			m.quitting = true
			return m, tea.Quit
		case "n", "N", "esc", "q", "Q":
			m.confirmQuit = false
		}
		return m, nil
	}

	// Q apre la conferma d'uscita da qualunque schermata.
	if k == "q" || k == "Q" {
		m.confirmQuit = true
		return m, nil
	}

	switch m.step {
	case stepWelcome:
		if k == "enter" {
			m.step = stepApps
			if !m.appsLoaded && m.loadErr == nil {
				m.loading = true
				return m, loadApps()
			}
		}

	case stepApps:
		if m.loading {
			if k == "esc" {
				m.step = stepWelcome
			}
			return m, nil
		}
		switch k {
		case "up", "k":
			m.apps.up()
		case "down", "j":
			m.apps.down()
		case " ":
			m.apps.toggle()
		case "a", "A":
			m.apps.toggleAll()
		case "enter":
			if m.loadErr == nil {
				m.step = stepNext
			}
		case "esc":
			m.step = stepWelcome
		}

	case stepNext:
		if k == "esc" {
			m.step = stepApps
		}
	}
	return m, nil
}

// View disegna la schermata corrente.
func (m Model) View() string {
	if m.quitting {
		return ""
	}
	if m.confirmQuit {
		return m.confirmView()
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
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(
		"Donkey si prende cura del tuo Mac in un attimo. Installa le app che\n" +
			"vuoi, personalizza il terminale e aggiorna tutto da solo. Tu decidi\n" +
			"cosa, lui fa tutto il resto."))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Quando sei pronto premi Invio per iniziare 🐵"))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "inizia"},
		style.FootKey{Key: "Q", Desc: "esci"},
	))
	return style.Screen.Render(b.String())
}

func (m Model) appsView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "App"))
	b.WriteString("\n\n")

	switch {
	case m.loading:
		b.WriteString(m.spin.View() + " " + style.ItemDesc.Render("Carico il catalogo…"))
		b.WriteString("\n\n")
		b.WriteString(style.Hints(
			style.FootKey{Key: "Esc", Desc: "indietro"},
			style.FootKey{Key: "Q", Desc: "esci"},
		))

	case m.loadErr != nil:
		b.WriteString(style.Error.Render(style.SymError + " Impossibile caricare il catalogo."))
		b.WriteString("\n")
		b.WriteString(style.ItemDesc.Render(m.loadErr.Error()))
		b.WriteString("\n\n")
		b.WriteString(style.Hints(
			style.FootKey{Key: "Esc", Desc: "indietro"},
			style.FootKey{Key: "Q", Desc: "esci"},
		))

	default:
		b.WriteString(style.ItemDesc.Render("Scegli le app da installare:"))
		b.WriteString("\n\n")
		b.WriteString(m.apps.view())
		b.WriteString("\n")
		b.WriteString(style.Hints(
			style.FootKey{Key: "↑↓"},
			style.FootKey{Key: "Spazio", Desc: "seleziona"},
			style.FootKey{Key: "A", Desc: "seleziona tutto"},
			style.FootKey{Key: "Invio", Desc: "avanti"},
			style.FootKey{Key: "Esc", Desc: "indietro"},
			style.FootKey{Key: "Q", Desc: "esci"},
		))
		b.WriteString(style.Footer.Render(fmt.Sprintf("    (%d selezionate)", len(m.apps.chosen()))))
	}
	return style.Screen.Render(b.String())
}

func (m Model) nextView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(fmt.Sprintf("Hai scelto %d app. 👍", len(m.apps.chosen()))))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Il resto del wizard (font, terminale, auto-update,\nriepilogo, installazione) arriva nei prossimi passi."))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	))
	return style.Screen.Render(b.String())
}

func (m Model) confirmView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.Alert.Render(style.SymWarning + " Vuoi davvero uscire dal setup?"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("Le scelte fatte finora andranno perse."))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "S", Desc: "esci"},
		style.FootKey{Key: "N", Desc: "resta"},
	))
	return style.Screen.Render(b.String())
}
