package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/key"
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
// Si appoggia a bubbles/list per impaginazione, scorrimento e help.
type picker struct {
	catalog string // nome del catalogo (catalog.Apps, catalog.Fonts)
	crumb   string // terzo livello dell'header (es. "App", "Font terminale")
	prompt  string // testo sopra la lista
	note    string // riga informativa sotto il prompt (ash); "" se assente
	single  bool   // selezione singola (radio) anziché multipla (checkbox)

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
	if p.loaded {
		p.list.SetSize(p.listW(), p.listH())
	}
}

func (p picker) listW() int {
	if w := p.width - 4; w > 20 {
		return w
	}
	return 20
}

func (p picker) listH() int {
	// Spazio per header, prompt, note e respiro attorno alla lista.
	if h := p.height - 9; h > 4 {
		return h
	}
	return 4
}

// setResult registra l'esito del download e costruisce la lista bubbles.
func (p *picker) setResult(entries []catalog.Entry, err error) {
	p.loading = false
	p.err = err
	if err != nil {
		return
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

	l := list.New(items, delegate{single: p.single, selected: p.selected, labelW: w + 2}, p.listW(), p.listH())
	l.SetShowTitle(false)
	l.SetShowStatusBar(false)
	l.SetFilteringEnabled(false)
	l.DisableQuitKeybindings()
	l.SetShowHelp(true)
	l.AdditionalShortHelpKeys = p.extraKeys
	l.AdditionalFullHelpKeys = p.extraKeys
	styleList(&l)

	p.list = l
	p.loaded = true
}

// extraKeys sono le scorciatoie specifiche di Donkey mostrate nell'help della lista.
func (p picker) extraKeys() []key.Binding {
	var ks []key.Binding
	if !p.single {
		ks = append(ks,
			key.NewBinding(key.WithKeys(" "), key.WithHelp("spazio", "seleziona")),
			key.NewBinding(key.WithKeys("a"), key.WithHelp("a", "tutte")),
		)
	}
	return append(ks,
		key.NewBinding(key.WithKeys("enter"), key.WithHelp("invio", "avanti")),
		key.NewBinding(key.WithKeys("esc"), key.WithHelp("esc", "indietro")),
		key.NewBinding(key.WithKeys("q"), key.WithHelp("q", "esci")),
	)
}

// update gestisce l'input: intercetta le azioni Donkey, inoltra il resto alla
// lista bubbles (navigazione, pagine, toggle help con "?").
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

// selectionLabel: etichetta della voce sotto il cursore (per la scelta singola).
func (p picker) selectionLabel() string {
	if it, ok := p.list.SelectedItem().(entryItem); ok {
		return it.e.Label
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
		b.WriteString(style.Error.Render(style.SymError + " Impossibile caricare il catalogo."))
		b.WriteString("\n")
		b.WriteString(style.ItemDesc.Render(p.err.Error()))
		b.WriteString("\n\n")
		b.WriteString(backQuitHints())

	default:
		head := style.ItemTitle.Render(p.prompt)
		if !p.single {
			head += "   " + style.Footer.Render(fmt.Sprintf("(%d selezionate)", p.selectedCount()))
		}
		b.WriteString(head)
		b.WriteString("\n")
		if p.note != "" {
			b.WriteString(style.URL.Render(p.note))
			b.WriteString("\n")
		}
		b.WriteString("\n")
		b.WriteString(p.list.View())
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

// styleList applica la palette Donkey e l'help in italiano alla lista bubbles.
func styleList(l *list.Model) {
	l.Styles.PaginationStyle = lipgloss.NewStyle().PaddingLeft(2)
	l.Styles.HelpStyle = lipgloss.NewStyle().PaddingLeft(2).PaddingTop(1)
	l.Paginator.ActiveDot = lipgloss.NewStyle().Foreground(style.Coral).Render("●")
	l.Paginator.InactiveDot = lipgloss.NewStyle().Foreground(style.Ash).Render("○")

	hs := &l.Help.Styles
	hs.ShortKey = lipgloss.NewStyle().Foreground(style.Cream)
	hs.ShortDesc = lipgloss.NewStyle().Foreground(style.Ash)
	hs.ShortSeparator = lipgloss.NewStyle().Foreground(style.Ash)
	hs.FullKey = hs.ShortKey
	hs.FullDesc = hs.ShortDesc
	hs.FullSeparator = hs.ShortSeparator
	hs.Ellipsis = lipgloss.NewStyle().Foreground(style.Ash)

	l.KeyMap.CursorUp.SetHelp("↑", "su")
	l.KeyMap.CursorDown.SetHelp("↓", "giù")
	l.KeyMap.NextPage.SetHelp("→", "pagina")
	l.KeyMap.PrevPage.SetHelp("←", "pagina")
	l.KeyMap.GoToStart.SetHelp("g", "inizio")
	l.KeyMap.GoToEnd.SetHelp("G", "fine")
	l.KeyMap.ShowFullHelp.SetHelp("?", "più")
	l.KeyMap.CloseFullHelp.SetHelp("?", "meno")
}
