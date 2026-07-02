// Package setup implementa il wizard di onboarding di Donkey (vedi AGENTS.md §2.1).
package setup

import (
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

type step int

const (
	stepWelcome step = iota
	stepApps
	stepTools
	stepFonts
	stepTheme
	stepAuto
	stepSummary
	stepInstall // placeholder: l'installazione vera arriva nel prossimo passo
)

// catalogMsg trasporta l'esito del download di un catalogo, instradato per nome.
type catalogMsg struct {
	target  string
	entries []catalog.Entry
	err     error
}

// Model è lo stato del wizard di setup.
type Model struct {
	step          step
	spin          spinner.Model
	width, height int
	apps          picker
	tools         picker
	fonts         picker
	theme         picker
	auto          bool      // aggiornamento automatico in background (homebrew-autoupdate)
	inst          installer // checklist di installazione (per ora simulata)
	confirmQuit   bool      // mostra la conferma d'uscita (Q da qualunque schermata)
	quitting      bool
}

// New crea il modello del wizard.
func New() Model {
	m := Model{
		spin:  style.NewSpinner(),
		apps:  newPicker(catalog.Apps, "App", "Scegli le app da installare:", "", false),
		tools: newPicker(catalog.Tools, "Strumenti terminale", "Scegli gli strumenti terminale da installare:", "", false),
		fonts: newPicker(catalog.Fonts, "Font terminale", "Scegli i font da installare:",
			"Vedi tutti i fonts su https://www.nerdfonts.com/font-downloads", false),
		theme: newPicker(catalog.Themes, "Tema terminale", "Scegli il tema del terminale:",
			"Vedi tutti i temi su https://ohmyposh.dev/docs/themes", true),
	}
	m.apps.descMax = 60               // descrizione inline su una riga, tagliata con …
	m.tools.descMax = 60              // idem per gli strumenti
	m.tools.countWord = "selezionati" // gli strumenti (m.), le app (f.)
	m.fonts.countWord = "selezionati" // i font (m.)
	m.theme.noneLabel = "Nessun tema" // prima voce, selezionata di default
	m.theme.desc = "Un tema Oh My Posh dà stile al tuo terminale: colori, icone e informazioni utili."
	m.auto = true // aggiornamento automatico consigliato di default
	return m
}

// Init avvia lo spinner.
func (m Model) Init() tea.Cmd {
	return m.spin.Tick
}

// Update gestisce input, animazioni, ridimensionamento e caricamento cataloghi.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.apps.setSize(msg.Width, msg.Height)
		m.tools.setSize(msg.Width, msg.Height)
		m.fonts.setSize(msg.Width, msg.Height)
		m.theme.setSize(msg.Width, msg.Height)
		return m, nil
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spin, cmd = m.spin.Update(msg)
		return m, cmd
	case catalogMsg:
		switch msg.target {
		case catalog.Apps:
			m.apps.setResult(msg.entries, msg.err)
		case catalog.Tools:
			m.tools.setResult(msg.entries, msg.err)
		case catalog.Fonts:
			m.fonts.setResult(msg.entries, msg.err)
		case catalog.Themes:
			m.theme.setResult(msg.entries, msg.err)
		}
		return m, nil
	case installTickMsg:
		m.inst.advance()
		if m.inst.done {
			return m, nil
		}
		return m, m.inst.tick()
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

	// Q apre la conferma d'uscita da qualunque schermata, tranne mentre
	// l'installazione è in corso: lì non c'è un ritorno indietro pulito.
	if k == "q" || k == "Q" {
		if m.step == stepInstall && !m.inst.done {
			return m, nil
		}
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
		cmd, act := m.apps.update(key)
		switch act {
		case pickNext:
			m.step = stepTools
			return m, m.tools.begin()
		case pickBack:
			m.step = stepWelcome
		}
		return m, cmd

	case stepTools:
		cmd, act := m.tools.update(key)
		switch act {
		case pickNext:
			m.step = stepFonts
			return m, m.fonts.begin()
		case pickBack:
			m.step = stepApps
		}
		return m, cmd

	case stepFonts:
		cmd, act := m.fonts.update(key)
		switch act {
		case pickNext:
			m.step = stepTheme
			return m, m.theme.begin()
		case pickBack:
			m.step = stepTools
		}
		return m, cmd

	case stepTheme:
		cmd, act := m.theme.update(key)
		switch act {
		case pickNext:
			m.step = stepAuto
		case pickBack:
			m.step = stepFonts
		}
		return m, cmd

	case stepAuto:
		switch k {
		case "left", "right", "h", "l", " ":
			m.auto = !m.auto
		case "enter":
			m.step = stepSummary
		case "esc":
			m.step = stepTheme
		}

	case stepSummary:
		switch k {
		case "enter":
			m.step = stepInstall
			m.inst = newInstaller(m)
			return m, m.inst.tick()
		case "esc":
			m.step = stepAuto
		}

	case stepInstall:
		// A installazione conclusa, Invio chiude il wizard; mentre installa
		// non si torna indietro (solo Q, gestita sopra, con conferma).
		if m.inst.done && k == "enter" {
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
	if m.confirmQuit {
		return m.confirmView()
	}
	switch m.step {
	case stepWelcome:
		return m.welcomeView()
	case stepApps:
		return m.apps.view(m.spin)
	case stepTools:
		return m.tools.view(m.spin)
	case stepFonts:
		return m.fonts.view(m.spin)
	case stepTheme:
		return m.theme.view(m.spin)
	case stepAuto:
		return m.autoView()
	case stepSummary:
		return m.summaryView()
	default:
		return m.installView()
	}
}

func (m Model) welcomeView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, ""))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(
		"Donkey si prende cura del tuo Mac in un attimo.\n" +
			"Installa le app che vuoi, personalizza il terminale e mantiene tutto aggiornato.\n" +
			"Tu scegli, lui fa tutto il resto 🐒"))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "Inizia"},
		style.FootKey{Key: "Q", Desc: "Esci"},
	))
	return style.Screen.Render(b.String())
}

func (m Model) autoView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "Aggiornamenti automatici"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Vuoi che Donkey tenga tutto aggiornato in automatico?"))
	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render(
		"Una volta alla settimana, solo con il Mac in carica, Donkey\n" +
			"aggiorna le app e pulisce il sistema da solo."))
	b.WriteString("\n\n")
	b.WriteString("  " + yesNoToggle(m.auto))
	b.WriteString("\n\n")
	b.WriteString(toggleHints())
	return style.Screen.Render(b.String())
}

// yesNoToggle disegna l'interruttore "● Sì   ○ No" con l'opzione attiva in coral.
func yesNoToggle(yes bool) string {
	if yes {
		return style.ItemTitleSel.Render(style.SymOn+" Sì") + "        " + style.ItemDesc.Render(style.SymOff+" No")
	}
	return style.ItemDesc.Render(style.SymOff+" Sì") + "        " + style.ItemTitleSel.Render(style.SymOn+" No")
}

// toggleHints è la barra comandi delle schermate a interruttore (Suggerimenti, Aggiornamenti).
func toggleHints() string {
	return style.Hints(
		style.FootKey{Key: "Spazio", Desc: "Seleziona"},
		style.FootKey{Key: "Invio", Desc: "Avanti"},
		style.FootKey{Key: "Esc", Desc: "Indietro"},
		style.FootKey{Key: "Q", Desc: "Esci"},
	)
}

func (m Model) installView() string {
	if m.inst.done {
		return m.doneView()
	}
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "Installazione"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Ok, iniziamo! Il tuo Mac sarà pronto tra un momento."))
	b.WriteString("\n\n")
	b.WriteString(m.inst.render(m.spin))
	return style.Screen.Render(b.String())
}

// doneView è la schermata finale: installazione conclusa, invito a usare dk.
func (m Model) doneView() string {
	cmd := lipgloss.NewStyle().Foreground(style.Aquamarine).Bold(true)
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "Fatto"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render(style.SymSuccess + " Tutto pronto! Il tuo Mac è pronto all'uso. 🐵"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Lancia ") + cmd.Render("dk") +
		style.ItemTitle.Render(" da terminale quando vuoi per personalizzare Donkey."))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "Esci"},
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
		style.FootKey{Key: "Invio", Desc: "Esci"},
		style.FootKey{Key: "Esc", Desc: "Resta"},
	))
	return style.Screen.Render(b.String())
}
