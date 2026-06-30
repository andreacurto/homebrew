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
	stepFonts
	stepNext // placeholder: il resto del wizard arriva nei prossimi passi
)

// catalogMsg trasporta l'esito del download di un catalogo, instradato per nome.
type catalogMsg struct {
	target  string
	entries []catalog.Entry
	err     error
}

// Model è lo stato del wizard di setup.
type Model struct {
	step        step
	spin        spinner.Model
	apps        picker
	fonts       picker
	confirmQuit bool // mostra la conferma d'uscita (Q da qualunque schermata)
	quitting    bool
}

// New crea il modello del wizard.
func New() Model {
	return Model{
		spin: style.NewSpinner(),
		apps: newPicker(catalog.Apps, "App", "Scegli le app da installare:", "", false),
		fonts: newPicker(catalog.Fonts, "Font terminale", "Scegli i font da installare:",
			"Vedi la lista completa su https://www.nerdfonts.com/font-downloads", false),
	}
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
		switch msg.target {
		case catalog.Apps:
			m.apps.setResult(msg.entries, msg.err)
		case catalog.Fonts:
			m.fonts.setResult(msg.entries, msg.err)
		}
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
		case "enter":
			m.quitting = true
			return m, tea.Quit
		case "esc":
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
			return m, m.apps.begin()
		}

	case stepApps:
		switch m.apps.handleKey(k) {
		case pickNext:
			m.step = stepFonts
			return m, m.fonts.begin()
		case pickBack:
			m.step = stepWelcome
		}

	case stepFonts:
		switch m.fonts.handleKey(k) {
		case pickNext:
			m.step = stepNext
		case pickBack:
			m.step = stepApps
		}

	case stepNext:
		if k == "esc" {
			m.step = stepFonts
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
		return m.apps.view(m.spin)
	case stepFonts:
		return m.fonts.view(m.spin)
	default:
		return m.nextView()
	}
}

func (m Model) welcomeView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(
		"Donkey si prende cura del tuo Mac in un attimo.\n" +
			"Installa le app che vuoi, personalizza il terminale e mantiene tutto aggiornato.\n" +
			"Tu decidi, lui fa tutto il resto."))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Quando sei pronto premi Invio per iniziare 🐒"))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "inizia"},
		style.FootKey{Key: "Q", Desc: "esci"},
	))
	return style.Screen.Render(b.String())
}

func (m Model) nextView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(fmt.Sprintf(
		"Hai scelto %d app e %d font. 👍",
		m.apps.selectedCount(), m.fonts.selectedCount(),
	)))
	b.WriteString("\n\n")
	b.WriteString(style.ItemDesc.Render("Il resto del wizard (terminale, auto-update,\nriepilogo, installazione) arriva nei prossimi passi."))
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
	b.WriteString(style.Alert.Render(style.SymWarning + " Vuoi davvero uscire?"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("Le scelte fatte finora andranno perse."))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "esci"},
		style.FootKey{Key: "Esc", Desc: "resta"},
	))
	return style.Screen.Render(b.String())
}
