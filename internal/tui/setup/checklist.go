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

// checklist è una lista a selezione multipla con checkbox e scorrimento.
type checklist struct {
	items    []catalog.Entry
	cursor   int
	selected map[string]bool // chiave: Value
	labelW   int             // larghezza colonna nomi: si adatta al nome più lungo
}

func newChecklist(items []catalog.Entry) *checklist {
	w := 0
	for _, e := range items {
		if l := lipgloss.Width(e.Label); l > w {
			w = l
		}
	}
	return &checklist{
		items:    items,
		selected: make(map[string]bool, len(items)),
		labelW:   w + 2, // due spazi di respiro prima della descrizione
	}
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
		v := c.items[c.cursor].Value
		c.selected[v] = !c.selected[v]
	}
}

// toggleAll seleziona tutte le voci; se sono già tutte selezionate, le deseleziona.
func (c *checklist) toggleAll() {
	all := true
	for _, e := range c.items {
		if !c.selected[e.Value] {
			all = false
			break
		}
	}
	for _, e := range c.items {
		c.selected[e.Value] = !all
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
	switch k {
	case "up", "k":
		c.up()
	case "down", "j":
		c.down()
	case " ":
		c.toggle()
	case "a", "A":
		c.toggleAll()
	case "enter":
		return pickNext
	case "esc":
		return pickBack
	}
	return pickStay
}

// window calcola la finestra [start, end) di voci visibili attorno al cursore.
func (c checklist) window() (int, int) {
	n := len(c.items)
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

func (c checklist) view() string {
	start, end := c.window()

	var rows strings.Builder
	for i := start; i < end; i++ {
		e := c.items[i]
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
		if i == c.cursor {
			marker = style.SymCursor + " "
			labelStyle = style.ItemTitleSel
			descStyle = style.ItemDescSel
		}
		rows.WriteString(style.Cursor.Render(marker))
		rows.WriteString(box)
		rows.WriteString(" ")
		rows.WriteString(labelStyle.Width(c.labelW).Render(e.Label))
		if e.Desc != "" {
			rows.WriteString(descStyle.Render(e.Desc))
		}
		if i < end-1 {
			rows.WriteString("\n")
		}
	}

	// Lista corta: nessuna scrollbar (non c'è nulla da scorrere).
	if len(c.items) <= visibleRows {
		return rows.String()
	}
	// Scrollbar laterale, staccata dalle voci: non sposta il layout e non
	// "sporca" gli elementi con scritte in cima/fondo.
	bar := scrollbar(len(c.items), visibleRows, start)
	return lipgloss.JoinHorizontal(lipgloss.Top, rows.String(), "   ", bar)
}

// scrollbar disegna una colonna alta `window` righe con un cursore (thumb)
// proporzionale alla posizione nella lista.
func scrollbar(total, window, start int) string {
	thumb := window * window / total
	if thumb < 1 {
		thumb = 1
	}
	pos := 0
	if max := total - window; max > 0 {
		pos = (window - thumb) * start / max
	}
	var b strings.Builder
	for i := 0; i < window; i++ {
		if i >= pos && i < pos+thumb {
			b.WriteString(style.ScrollThumb.Render("█"))
		} else {
			b.WriteString(style.ScrollTrack.Render("│"))
		}
		if i < window-1 {
			b.WriteString("\n")
		}
	}
	return b.String()
}

func (c checklist) hints() string {
	return style.Hints(
		style.FootKey{Key: "↑↓"},
		style.FootKey{Key: "Spazio", Desc: "seleziona"},
		style.FootKey{Key: "A", Desc: "seleziona tutto"},
		style.FootKey{Key: "Invio", Desc: "avanti"},
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	)
}

func (c checklist) summary() string {
	return style.Footer.Render(fmt.Sprintf("    (%d selezionate)", len(c.chosen())))
}
