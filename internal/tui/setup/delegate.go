package setup

import (
	"fmt"
	"io"

	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

// entryItem adatta una voce di catalogo all'interfaccia list.Item di bubbles.
type entryItem struct{ e catalog.Entry }

func (i entryItem) FilterValue() string { return i.e.Label }

// delegate disegna una riga della lista: checkbox (multi) o radio (single),
// nello stile Donkey. Condivide la mappa di selezione con il picker.
type delegate struct {
	single   bool
	selected map[string]bool
	labelW   int
}

func (d delegate) Height() int                         { return 1 }
func (d delegate) Spacing() int                        { return 0 }
func (d delegate) Update(tea.Msg, *list.Model) tea.Cmd { return nil }

func (d delegate) Render(w io.Writer, m list.Model, index int, item list.Item) {
	it, ok := item.(entryItem)
	if !ok {
		return
	}
	here := index == m.Index()

	marker := "  "
	labelStyle := style.ItemTitle
	descStyle := style.ItemDesc
	if here {
		marker = style.SymCursor + " "
		labelStyle = style.ItemTitleSel
		descStyle = style.ItemDescSel
	}

	var box string
	if d.single {
		box = style.ItemDesc.Render(style.SymOff)
		if here {
			box = style.ItemTitleSel.Render(style.SymOn)
		}
	} else {
		box = style.ItemDesc.Render(style.SymCheckOff)
		if d.selected[it.e.Value] {
			box = style.ItemTitleSel.Render(style.SymCheckOn)
		}
	}

	row := style.Cursor.Render(marker) + box + " " + labelStyle.Width(d.labelW).Render(it.e.Label)
	if it.e.Desc != "" {
		// La descrizione inline non deve mai sforare la larghezza della lista:
		// la taglio (con …); quella completa la mostra il riquadro dettaglio.
		if avail := m.Width() - d.labelW - 5; avail > 4 {
			row += descStyle.Render(clip(it.e.Desc, avail))
		}
	}
	fmt.Fprint(w, row)
}

// clip taglia s a max celle, aggiungendo … se necessario.
func clip(s string, max int) string {
	if max <= 0 {
		return ""
	}
	if lipgloss.Width(s) <= max {
		return s
	}
	r := []rune(s)
	for len(r) > 1 && lipgloss.Width(string(r))+1 > max {
		r = r[:len(r)-1]
	}
	return string(r) + "…"
}
