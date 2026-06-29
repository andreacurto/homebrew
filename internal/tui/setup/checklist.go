package setup

import (
	"strings"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// checklist è una lista a selezione multipla con checkbox.
type checklist struct {
	items    []catalog.Entry
	cursor   int
	selected map[int]bool
}

func newChecklist(items []catalog.Entry) checklist {
	return checklist{items: items, selected: make(map[int]bool, len(items))}
}

func (c *checklist) up() {
	if c.cursor > 0 {
		c.cursor--
	}
}

func (c *checklist) down() {
	if c.cursor < len(c.items)-1 {
		c.cursor++
	}
}

func (c *checklist) toggle() {
	if len(c.items) > 0 {
		c.selected[c.cursor] = !c.selected[c.cursor]
	}
}

// toggleAll seleziona tutte le voci; se sono già tutte selezionate, le deseleziona.
func (c *checklist) toggleAll() {
	selectAll := len(c.chosen()) < len(c.items)
	for i := range c.items {
		c.selected[i] = selectAll
	}
}

// chosen ritorna le voci selezionate, nell'ordine del catalogo.
func (c checklist) chosen() []catalog.Entry {
	var out []catalog.Entry
	for i, e := range c.items {
		if c.selected[i] {
			out = append(out, e)
		}
	}
	return out
}

// labelWidth allinea le descrizioni: largo quanto l'etichetta più lunga + respiro.
const labelWidth = 20

func (c checklist) view() string {
	var b strings.Builder
	for i, e := range c.items {
		// Checkbox: ■ (selezionata, coral) / □ (no, ash).
		box := style.ItemDesc.Render(style.SymCheckOff)
		if c.selected[i] {
			box = style.ItemTitleSel.Render(style.SymCheckOn)
		}
		// Riga sotto cursore: etichetta in coral e descrizione in crema;
		// altrimenti etichetta crema e descrizione ash.
		marker := "  "
		labelStyle := style.ItemTitle
		descStyle := style.ItemDesc
		if i == c.cursor {
			marker = style.SymCursor + " "
			labelStyle = style.ItemTitleSel
			descStyle = style.ItemDescSel
		}
		b.WriteString(style.Cursor.Render(marker))
		b.WriteString(box)
		b.WriteString(" ")
		b.WriteString(labelStyle.Width(labelWidth).Render(e.Label))
		if e.Desc != "" {
			b.WriteString(descStyle.Render(e.Desc))
		}
		b.WriteString("\n")
	}
	return b.String()
}
