package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// pickerAction è l'esito della gestione input di un picker: l'orchestratore
// (Model) decide a quale step andare.
type pickerAction int

const (
	pickStay pickerAction = iota
	pickNext
	pickBack
)

// picker è una schermata di selezione su un catalogo live (App, Font, temi).
// Si appoggia a bubbles/list per voci e paginazione; il footer lo disegna Donkey.
type picker struct {
	catalog   string // nome del catalogo (catalog.Apps, catalog.Fonts)
	crumb     string // terzo livello dell'header (es. "App", "Font terminale")
	prompt    string // testo sopra la lista
	desc      string // descrizione multi-riga sotto il prompt (ash); "" se assente
	note      string // riga informativa/link sotto la descrizione (ash); "" se assente
	single    bool   // selezione singola (radio) anziché multipla (checkbox)
	noneLabel string // se valorizzato, voce "nessuno" (Value "") in cima alla lista

	width, height int
	loaded        bool
	loading       bool
	err           error

	list     list.Model
	selected map[string]bool // chiave: Value (solo multi-selezione)
}

func newPicker(catalogName, crumb, prompt, note string, single bool) picker {
	return picker{
		catalog: catalogName, crumb: crumb, prompt: prompt, note: note, single: single,
		width: 80, height: 24,
	}
}

// load scarica il catalogo associato; il messaggio è instradato per nome.
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

func (p *picker) setSize(w, h int) {
	p.width, p.height = w, h
	p.resize()
}

func (p picker) listW() int {
	if w := p.width - 4; w > 20 {
		return w
	}
	return 20
}

// chrome stima le righe non-lista (header, prompt, descrizione, note, footer…).
func (p picker) chrome() int {
	c := 10
	if p.note != "" {
		c++
	}
	if p.desc != "" {
		c += strings.Count(p.desc, "\n") + 1
	}
	return c
}

// availableRows è lo spazio verticale per la lista (tolto il "chrome").
func (p picker) availableRows() int {
	if r := p.height - p.chrome(); r > 4 {
		return r
	}
	return 4
}

// resize adatta la lista al contenuto: se le voci ci stanno tutte, niente
// paginazione e altezza pari alle voci (così il footer non resta lontano);
// altrimenti paginazione e altezza piena.
func (p *picker) resize() {
	if !p.loaded {
		return
	}
	n := len(p.list.Items())
	if avail := p.availableRows(); n <= avail {
		p.list.SetShowPagination(false)
		p.list.SetSize(p.listW(), max(n, 1))
	} else {
		p.list.SetShowPagination(true)
		p.list.SetSize(p.listW(), avail)
	}
}

// setResult registra l'esito del download e costruisce la lista bubbles.
func (p *picker) setResult(entries []catalog.Entry, err error) {
	p.loading = false
	p.err = err
	if err != nil {
		return
	}

	// Voce "nessuno" in cima (es. "Nessun tema"), selezionata di default.
	if p.noneLabel != "" {
		entries = append([]catalog.Entry{{Label: p.noneLabel}}, entries...)
	}

	items := make([]list.Item, len(entries))
	w := 0
	for i, e := range entries {
		items[i] = entryItem{e}
		if l := lipgloss.Width(e.Label); l > w {
			w = l
		}
	}
	p.selected = make(map[string]bool, len(entries))

	l := list.New(items, delegate{single: p.single, selected: p.selected, labelW: w + 2}, p.listW(), p.availableRows())
	l.SetShowTitle(false)
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	l.DisableQuitKeybindings()
	styleList(&l)

	p.list = l
	p.loaded = true
	p.resize()
}

// update gestisce l'input: intercetta le azioni Donkey, inoltra il resto alla
// lista bubbles (navigazione, pagine).
func (p *picker) update(msg tea.Msg) (tea.Cmd, pickerAction) {
	if p.loading || p.err != nil {
		if k, ok := msg.(tea.KeyMsg); ok && k.String() == "esc" {
			return nil, pickBack
		}
		return nil, pickStay
	}
	if k, ok := msg.(tea.KeyMsg); ok {
		switch k.String() {
		case " ":
			if !p.single {
				p.toggle()
			}
			return nil, pickStay
		case "a", "A":
			if !p.single {
				p.toggleAll()
			}
			return nil, pickStay
		case "enter":
			return nil, pickNext
		case "esc":
			return nil, pickBack
		}
	}
	var cmd tea.Cmd
	p.list, cmd = p.list.Update(msg)
	return cmd, pickStay
}

func (p *picker) toggle() {
	if it, ok := p.list.SelectedItem().(entryItem); ok {
		p.selected[it.e.Value] = !p.selected[it.e.Value]
	}
}

func (p *picker) toggleAll() {
	all := true
	for _, item := range p.list.Items() {
		if it, ok := item.(entryItem); ok && !p.selected[it.e.Value] {
			all = false
			break
		}
	}
	for _, item := range p.list.Items() {
		if it, ok := item.(entryItem); ok {
			p.selected[it.e.Value] = !all
		}
	}
}

// selectedCount: voci selezionate (multi) o 1 se c'è una scelta (single).
func (p picker) selectedCount() int {
	if p.single {
		if _, ok := p.list.SelectedItem().(entryItem); ok {
			return 1
		}
		return 0
	}
	n := 0
	for _, on := range p.selected {
		if on {
			n++
		}
	}
	return n
}

// chosenLabels: etichette delle voci selezionate, nell'ordine della lista.
func (p picker) chosenLabels() []string {
	var out []string
	for _, item := range p.list.Items() {
		if it, ok := item.(entryItem); ok && p.selected[it.e.Value] {
			out = append(out, it.e.Label)
		}
	}
	return out
}

// selectionLabel: etichetta della voce sotto il cursore (per la scelta singola).
func (p picker) selectionLabel() string {
	if it, ok := p.list.SelectedItem().(entryItem); ok {
		return it.e.Label
	}
	return ""
}

// selectionValue: valore della voce sotto il cursore ("" per la voce "nessuno").
func (p picker) selectionValue() string {
	if it, ok := p.list.SelectedItem().(entryItem); ok {
		return it.e.Value
	}
	return ""
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
		b.WriteString(style.Error.Render("Impossibile caricare il catalogo."))
		b.WriteString("\n")
		b.WriteString(style.ItemDesc.Render(p.err.Error()))
		b.WriteString("\n\n")
		b.WriteString(backQuitHints())

	default:
		head := style.ItemTitle.Render(p.prompt)
		if p.single {
			head += "   " + style.Footer.Render(fmt.Sprintf("(%s selezionato)", p.selectionLabel()))
		} else {
			head += "   " + style.Footer.Render(fmt.Sprintf("(%d selezionate)", p.selectedCount()))
		}
		b.WriteString(head)
		b.WriteString("\n")
		if p.desc != "" {
			b.WriteString(style.ItemDesc.Render(p.desc))
			b.WriteString("\n")
		}
		if p.note != "" {
			b.WriteString(renderNote(p.note))
			b.WriteString("\n")
		}
		b.WriteString("\n")
		b.WriteString(strings.TrimRight(p.list.View(), "\n"))
		b.WriteString("\n\n")
		b.WriteString(p.footer())
	}
	return style.Screen.Render(b.String())
}

// footer compone la barra comandi nello stile Donkey. Le voci inutili (frecce
// pagina su lista a pagina singola, seleziona su single) vengono omesse.
func (p picker) footer() string {
	keys := []style.FootKey{{Key: "↑ ↓"}}
	if p.list.Paginator.TotalPages > 1 {
		keys = append(keys, style.FootKey{Key: "← →", Desc: "Naviga pagine"})
	}
	if !p.single {
		keys = append(keys,
			style.FootKey{Key: "Spazio", Desc: "Seleziona"},
			style.FootKey{Key: "A", Desc: "Seleziona tutto"},
		)
	}
	keys = append(keys,
		style.FootKey{Key: "Invio", Desc: "Avanti"},
		style.FootKey{Key: "Esc", Desc: "Indietro"},
		style.FootKey{Key: "Q", Desc: "Esci"},
	)
	return style.Hints(keys...)
}

// renderNote disegna la nota sotto il prompt sottolineando la sola parte URL.
func renderNote(note string) string {
	if i := strings.Index(note, "http"); i >= 0 {
		return style.URL.Render(note[:i]) + style.Link.Render(note[i:])
	}
	return style.URL.Render(note)
}

// backQuitHints è la barra comandi minima delle schermate di caricamento/errore.
func backQuitHints() string {
	return style.Hints(
		style.FootKey{Key: "Esc", Desc: "Indietro"},
		style.FootKey{Key: "Q", Desc: "Esci"},
	)
}

// styleList applica la palette Donkey alla lista: paginazione spaziata
// (cheddar attiva, ash le altre) e help integrato spento (lo disegna Donkey).
func styleList(l *list.Model) {
	l.SetShowHelp(false)
	l.Styles.PaginationStyle = lipgloss.NewStyle().PaddingLeft(2)
	l.Paginator.ActiveDot = lipgloss.NewStyle().Foreground(style.Cheddar).Render("●") + " "
	l.Paginator.InactiveDot = lipgloss.NewStyle().Foreground(style.Ash).Render("●") + " "
	l.KeyMap.GoToStart.SetEnabled(false)
	l.KeyMap.GoToEnd.SetEnabled(false)
}
