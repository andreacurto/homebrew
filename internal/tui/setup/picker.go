package setup

import (
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

// listBody è il corpo selezionabile di un picker: multi-scelta (checklist) o
// singola scelta (radiolist). Gestisce i tasti e disegna lista, footer e riepilogo.
type listBody interface {
	handleKey(k string) pickerAction
	view() string    // righe della lista
	hints() string   // barra comandi
	summary() string // testo extra dopo la barra (es. conteggio); "" se assente
}

// picker è una schermata di selezione su un catalogo live (App, Font).
// Scaffolding comune (caricamento, errore, header); il corpo è multi o singola scelta.
type picker struct {
	catalog string // nome del catalogo (catalog.Apps, catalog.Fonts)
	crumb   string // terzo livello dell'header (es. "App", "Font terminale")
	prompt  string // testo sopra la lista
	note    string // riga informativa sotto il prompt (ash); "" se assente
	single  bool   // selezione singola (radio) anziché multipla (checkbox)
	loaded  bool
	loading bool
	err     error
	body    listBody
}

func newPicker(catalogName, crumb, prompt, note string, single bool) picker {
	return picker{catalog: catalogName, crumb: crumb, prompt: prompt, note: note, single: single}
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

// setResult registra l'esito del download e costruisce il corpo adatto.
func (p *picker) setResult(entries []catalog.Entry, err error) {
	p.loading = false
	p.err = err
	if err != nil {
		return
	}
	if p.single {
		p.body = newRadiolist(entries)
	} else {
		p.body = newChecklist(entries)
	}
	p.loaded = true
}

// handleKey delega al corpo, gestendo a parte gli stati di caricamento/errore.
func (p *picker) handleKey(k string) pickerAction {
	if p.loading || p.err != nil {
		if k == "esc" {
			return pickBack
		}
		return pickStay
	}
	return p.body.handleKey(k)
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
		b.WriteString("\n")
		if p.note != "" {
			b.WriteString(style.URL.Render(p.note))
			b.WriteString("\n")
		}
		b.WriteString("\n")
		b.WriteString(p.body.view())
		b.WriteString("\n")
		b.WriteString(p.body.hints())
		b.WriteString(p.body.summary())
	}
	return style.Screen.Render(b.String())
}

// selectedCount: voci selezionate (multi) o 1 se c'è una scelta (single).
func (p picker) selectedCount() int {
	switch t := p.body.(type) {
	case *checklist:
		return len(t.chosen())
	case *radiolist:
		if _, ok := t.selection(); ok {
			return 1
		}
	}
	return 0
}

// selectionLabel: etichetta della scelta singola (vuota se non a scelta singola).
func (p picker) selectionLabel() string {
	if r, ok := p.body.(*radiolist); ok {
		if e, ok := r.selection(); ok {
			return e.Label
		}
	}
	return ""
}

// backQuitHints è la barra comandi minima delle schermate di caricamento/errore.
func backQuitHints() string {
	return style.Hints(
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	)
}
