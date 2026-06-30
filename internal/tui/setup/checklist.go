package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// visibleRows è il numero di voci mostrate a schermo; le altre scorrono.
const visibleRows = 12

// checklist è una lista a selezione multipla con checkbox, scorrimento e
// ricerca live. La barra di ricerca è sempre visibile; "/" le dà il focus,
// Invio o ↓ riportano il focus alla lista per selezionare.
type checklist struct {
	items       []catalog.Entry
	filtered    []int           // indici di items che passano il filtro corrente
	cursor      int             // posizione in filtered
	selected    map[string]bool // chiave: Value (stabile anche sotto filtro)
	labelW      int             // larghezza colonna nomi: si adatta al nome più lungo
	searchFocus bool            // il focus è sul campo di ricerca
	query       string          // testo della ricerca
}

func newChecklist(items []catalog.Entry) *checklist {
	w := 0
	for _, e := range items {
		if l := lipgloss.Width(e.Label); l > w {
			w = l
		}
	}
	c := &checklist{
		items:    items,
		selected: make(map[string]bool, len(items)),
		labelW:   w + 2, // due spazi di respiro prima della descrizione
	}
	c.applyFilter()
	return c
}

// applyFilter ricostruisce l'elenco visibile in base a query (sottostringa, case-insensitive).
func (c *checklist) applyFilter() {
	q := strings.ToLower(strings.TrimSpace(c.query))
	c.filtered = c.filtered[:0]
	for i, e := range c.items {
		if q == "" || strings.Contains(strings.ToLower(e.Label), q) {
			c.filtered = append(c.filtered, i)
		}
	}
	if c.cursor >= len(c.filtered) {
		c.cursor = len(c.filtered) - 1
	}
	if c.cursor < 0 {
		c.cursor = 0
	}
}

func (c *checklist) up() {
	if c.cursor > 0 {
		c.cursor--
	}
}

func (c *checklist) down() {
	if c.cursor < len(c.filtered)-1 {
		c.cursor++
	}
}

// current ritorna l'indice in items della voce sotto il cursore (-1 se vuoto).
func (c checklist) current() int {
	if len(c.filtered) == 0 {
		return -1
	}
	return c.filtered[c.cursor]
}

func (c *checklist) toggle() {
	if i := c.current(); i >= 0 {
		v := c.items[i].Value
		c.selected[v] = !c.selected[v]
	}
}

// toggleAll seleziona tutte le voci visibili; se sono già tutte selezionate, le deseleziona.
func (c *checklist) toggleAll() {
	all := true
	for _, i := range c.filtered {
		if !c.selected[c.items[i].Value] {
			all = false
			break
		}
	}
	for _, i := range c.filtered {
		c.selected[c.items[i].Value] = !all
	}
}

// chosen ritorna le voci selezionate, nell'ordine del catalogo.
func (c checklist) chosen() []catalog.Entry {
	var out []catalog.Entry
	for _, e := range c.items {
		if c.selected[e.Value] {
			out = append(out, e)
		}
	}
	return out
}

func (c *checklist) handleKey(k string) pickerAction {
	if c.searchFocus {
		return c.handleSearchKey(k)
	}
	switch k {
	case "up", "k":
		c.up()
	case "down", "j":
		c.down()
	case " ":
		c.toggle()
	case "a", "A":
		c.toggleAll()
	case "/":
		c.searchFocus = true
	case "enter":
		return pickNext
	case "esc":
		return pickBack
	}
	return pickStay
}

// handleSearchKey gestisce i tasti col focus sul campo di ricerca: le lettere
// compongono la query (filtro live), Invio/↓ tornano alla lista, Esc annulla.
func (c *checklist) handleSearchKey(k string) pickerAction {
	switch k {
	case "esc":
		c.searchFocus = false
		c.query = ""
		c.applyFilter()
	case "enter", "down":
		c.searchFocus = false
	case "backspace":
		if r := []rune(c.query); len(r) > 0 {
			c.query = string(r[:len(r)-1])
			c.applyFilter()
		}
	default:
		// Un solo carattere stampabile: lo aggiungo alla ricerca.
		if len([]rune(k)) == 1 {
			c.query += k
			c.applyFilter()
		}
	}
	return pickStay
}

// window calcola la finestra [start, end) di voci visibili attorno al cursore.
func (c checklist) window() (int, int) {
	n := len(c.filtered)
	if n <= visibleRows {
		return 0, n
	}
	start := c.cursor - visibleRows/2
	if start < 0 {
		start = 0
	}
	if start > n-visibleRows {
		start = n - visibleRows
	}
	return start, start + visibleRows
}

// searchView disegna il campo di ricerca, sempre visibile e stile input.
func (c checklist) searchView() string {
	var inner string
	switch {
	case c.searchFocus:
		inner = style.SearchText.Render("Cerca: " + c.query + "▏")
	case c.query != "":
		inner = style.SearchText.Render("Cerca: " + c.query)
	default:
		inner = style.SearchHint.Render("Cerca…  ( / )")
	}
	return style.SearchBox.Render(inner)
}

func (c checklist) view() string {
	var b strings.Builder

	b.WriteString(c.searchView())
	b.WriteString("\n\n")

	if len(c.filtered) == 0 {
		b.WriteString(style.ItemDesc.Render("  Nessun risultato."))
		b.WriteString("\n")
		return b.String()
	}

	start, end := c.window()
	if start > 0 {
		b.WriteString(style.ItemDesc.Render(fmt.Sprintf("  ↑ altri %d sopra", start)))
		b.WriteString("\n")
	}
	for vi := start; vi < end; vi++ {
		e := c.items[c.filtered[vi]]
		// Checkbox: ■ (selezionata, coral) / □ (no, ash).
		box := style.ItemDesc.Render(style.SymCheckOff)
		if c.selected[e.Value] {
			box = style.ItemTitleSel.Render(style.SymCheckOn)
		}
		// Riga sotto cursore: etichetta in coral e descrizione in crema;
		// altrimenti etichetta crema e descrizione ash.
		marker := "  "
		labelStyle := style.ItemTitle
		descStyle := style.ItemDesc
		if vi == c.cursor {
			marker = style.SymCursor + " "
			labelStyle = style.ItemTitleSel
			descStyle = style.ItemDescSel
		}
		b.WriteString(style.Cursor.Render(marker))
		b.WriteString(box)
		b.WriteString(" ")
		b.WriteString(labelStyle.Width(c.labelW).Render(e.Label))
		if e.Desc != "" {
			b.WriteString(descStyle.Render(e.Desc))
		}
		b.WriteString("\n")
	}
	if end < len(c.filtered) {
		b.WriteString(style.ItemDesc.Render(fmt.Sprintf("  ↓ altri %d sotto", len(c.filtered)-end)))
		b.WriteString("\n")
	}
	return b.String()
}

func (c checklist) hints() string {
	if c.searchFocus {
		return style.Hints(
			style.FootKey{Key: "scrivi", Desc: "filtra"},
			style.FootKey{Key: "Invio o ↓", Desc: "vai alla lista"},
			style.FootKey{Key: "Esc", Desc: "annulla"},
		)
	}
	return style.Hints(
		style.FootKey{Key: "↑↓"},
		style.FootKey{Key: "Spazio", Desc: "seleziona"},
		style.FootKey{Key: "A", Desc: "seleziona tutto"},
		style.FootKey{Key: "/", Desc: "cerca"},
		style.FootKey{Key: "Invio", Desc: "avanti"},
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	)
}

func (c checklist) summary() string {
	return style.Footer.Render(fmt.Sprintf("    (%d selezionate)", len(c.chosen())))
}
