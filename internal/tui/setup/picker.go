package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// pickerAction è l'esito della gestione tasti di un picker: l'orchestratore
// (Model) decide a quale step andare.
type pickerAction int

const (
	pickStay pickerAction = iota
	pickNext
	pickBack
)

// picker è una schermata di selezione multipla su un catalogo live (App, Font).
// Comportamento identico tra i due: lista, spinner di caricamento, errore.
type picker struct {
	catalog string // nome del catalogo (catalog.Apps, catalog.Fonts)
	crumb   string // terzo livello dell'header (es. "App", "Font")
	prompt  string // testo sopra la lista
	loaded  bool
	loading bool
	err     error
	list    checklist
}

func newPicker(catalogName, crumb, prompt string) picker {
	return picker{catalog: catalogName, crumb: crumb, prompt: prompt}
}

// load scarica il catalogo associato; il messaggio è instradato per nome catalogo.
func (p picker) load() tea.Cmd {
	name := p.catalog
	return func() tea.Msg {
		e, err := catalog.Fetch(name)
		return catalogMsg{target: name, entries: e, err: err}
	}
}

// begin avvia il caricamento la prima volta che si entra nella schermata.
func (p *picker) begin() tea.Cmd {
	if p.loaded || p.err != nil {
		return nil
	}
	p.loading = true
	return p.load()
}

// setResult registra l'esito del download.
func (p *picker) setResult(entries []catalog.Entry, err error) {
	p.loading = false
	p.err = err
	if err == nil {
		p.list = newChecklist(entries)
		p.loaded = true
	}
}

// handleKey gestisce la navigazione interna alla lista.
func (p *picker) handleKey(k string) pickerAction {
	if p.loading {
		if k == "esc" {
			return pickBack
		}
		return pickStay
	}
	switch k {
	case "up", "k":
		p.list.up()
	case "down", "j":
		p.list.down()
	case " ":
		p.list.toggle()
	case "a", "A":
		p.list.toggleAll()
	case "enter":
		if p.err == nil {
			return pickNext
		}
	case "esc":
		return pickBack
	}
	return pickStay
}

func (p picker) view(spin spinner.Model) string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, p.crumb))
	b.WriteString("\n\n")

	switch {
	case p.loading:
		b.WriteString(spin.View() + " " + style.ItemDesc.Render("Carico il catalogo…"))
		b.WriteString("\n\n")
		b.WriteString(backQuitHints())

	case p.err != nil:
		b.WriteString(style.Error.Render(style.SymError + " Impossibile caricare il catalogo."))
		b.WriteString("\n")
		b.WriteString(style.ItemDesc.Render(p.err.Error()))
		b.WriteString("\n\n")
		b.WriteString(backQuitHints())

	default:
		b.WriteString(style.ItemTitle.Render(p.prompt))
		b.WriteString("\n\n")
		b.WriteString(p.list.view())
		b.WriteString("\n")
		b.WriteString(style.Hints(
			style.FootKey{Key: "↑↓"},
			style.FootKey{Key: "Spazio", Desc: "seleziona"},
			style.FootKey{Key: "A", Desc: "seleziona tutto"},
			style.FootKey{Key: "Invio", Desc: "avanti"},
			style.FootKey{Key: "Esc", Desc: "indietro"},
			style.FootKey{Key: "Q", Desc: "esci"},
		))
		b.WriteString(style.Footer.Render(fmt.Sprintf("    (%d selezionate)", len(p.list.chosen()))))
	}
	return style.Screen.Render(b.String())
}

// backQuitHints è la barra comandi minima delle schermate di caricamento/errore.
func backQuitHints() string {
	return style.Hints(
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	)
}
