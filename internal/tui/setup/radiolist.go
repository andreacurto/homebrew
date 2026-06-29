package setup

import (
	"strings"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// radiolist è una lista a selezione singola: la voce sotto il cursore è quella scelta.
type radiolist struct {
	items  []catalog.Entry
	cursor int
}

func newRadiolist(items []catalog.Entry) *radiolist {
	return &radiolist{items: items}
}

func (r *radiolist) up() {
	if r.cursor > 0 {
		r.cursor--
	}
}

func (r *radiolist) down() {
	if r.cursor < len(r.items)-1 {
		r.cursor++
	}
}

// selection ritorna la voce scelta (quella sotto il cursore).
func (r radiolist) selection() (catalog.Entry, bool) {
	if len(r.items) == 0 {
		return catalog.Entry{}, false
	}
	return r.items[r.cursor], true
}

func (r *radiolist) handleKey(k string) pickerAction {
	switch k {
	case "up", "k":
		r.up()
	case "down", "j":
		r.down()
	case "enter":
		return pickNext
	case "esc":
		return pickBack
	}
	return pickStay
}

func (r radiolist) view() string {
	var b strings.Builder
	for i, e := range r.items {
		// Radio: ● (scelto, sotto cursore) / ○ (non scelto).
		marker := "  "
		labelStyle := style.ItemTitle
		radio := style.ItemDesc.Render(style.SymOff)
		if i == r.cursor {
			marker = style.SymCursor + " "
			labelStyle = style.ItemTitleSel
			radio = style.ItemTitleSel.Render(style.SymOn)
		}
		b.WriteString(style.Cursor.Render(marker))
		b.WriteString(radio)
		b.WriteString(" ")
		b.WriteString(labelStyle.Render(e.Label))
		b.WriteString("\n")
	}
	return b.String()
}

func (r radiolist) hints() string {
	return style.Hints(
		style.FootKey{Key: "↑↓"},
		style.FootKey{Key: "Invio", Desc: "avanti"},
		style.FootKey{Key: "Esc", Desc: "indietro"},
		style.FootKey{Key: "Q", Desc: "esci"},
	)
}

func (r radiolist) summary() string { return "" }
