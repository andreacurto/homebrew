package setup

import (
	"strings"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// auLabelW allinea i controlli a destra delle etichette.
const auLabelW = 32

// autoUpdate è il pannello impostazioni dell'aggiornamento automatico
// (wrapper su homebrew-autoupdate). Una riga per impostazione, navigabile.
type autoUpdate struct {
	cursor    int
	enabled   bool // master: aggiornamento automatico attivo
	weekly    bool // frequenza: true = 1 settimana, false = 1 giorno
	upgrade   bool // --upgrade: aggiorna pacchetti e app
	cleanup   bool // --cleanup: pulizia dopo l'aggiornamento
	acOnly    bool // --ac-only: solo a corrente
	immediate bool // --immediate: a ogni avvio del Mac
}

func newAutoUpdate() autoUpdate {
	return autoUpdate{enabled: true, weekly: true, upgrade: true, cleanup: true}
}

// rowCount: solo il master se disattivo, altrimenti master + 5 opzioni.
func (a autoUpdate) rowCount() int {
	if a.enabled {
		return 6
	}
	return 1
}

func (a *autoUpdate) up() {
	if a.cursor > 0 {
		a.cursor--
	}
}

func (a *autoUpdate) down() {
	if a.cursor < a.rowCount()-1 {
		a.cursor++
	}
}

// change cambia il valore della riga sotto il cursore.
func (a *autoUpdate) change() {
	switch a.cursor {
	case 0:
		a.enabled = !a.enabled
		if !a.enabled {
			a.cursor = 0
		}
	case 1:
		a.weekly = !a.weekly
	case 2:
		a.upgrade = !a.upgrade
	case 3:
		a.cleanup = !a.cleanup
	case 4:
		a.acOnly = !a.acOnly
	case 5:
		a.immediate = !a.immediate
	}
}

func (a *autoUpdate) handleKey(k string) pickerAction {
	switch k {
	case "up", "k":
		a.up()
	case "down", "j":
		a.down()
	case " ", "left", "right", "h", "l":
		a.change()
	case "enter":
		return pickNext
	case "esc":
		return pickBack
	}
	return pickStay
}

func (a autoUpdate) view() string {
	var b strings.Builder
	b.WriteString(a.row(0, "Aggiornamento automatico", siNo(a.enabled)))
	if !a.enabled {
		b.WriteString("\n\n")
		b.WriteString(style.ItemDesc.Render("  L'aggiornamento automatico è disattivato."))
		return b.String()
	}
	b.WriteString("\n")
	b.WriteString(a.row(1, "Frequenza", freq(a.weekly)))
	b.WriteString("\n")
	b.WriteString(a.row(2, "Aggiorna pacchetti e app", check(a.upgrade)))
	b.WriteString("\n")
	b.WriteString(a.row(3, "Pulizia dopo l'aggiornamento", check(a.cleanup)))
	b.WriteString("\n")
	b.WriteString(a.row(4, "Solo quando sei a corrente", check(a.acOnly)))
	b.WriteString("\n")
	b.WriteString(a.row(5, "Esegui a ogni avvio del Mac", check(a.immediate)))
	return b.String()
}

// row disegna una riga "etichetta … controllo", evidenziata se sotto il cursore.
func (a autoUpdate) row(i int, label, control string) string {
	marker := "  "
	ls := style.ItemTitle
	if i == a.cursor {
		marker = style.SymCursor + " "
		ls = style.ItemTitleSel
	}
	return style.Cursor.Render(marker) + ls.Width(auLabelW).Render(label) + control
}

func check(on bool) string {
	if on {
		return style.ItemTitleSel.Render(style.SymCheckOn)
	}
	return style.ItemDesc.Render(style.SymCheckOff)
}

func siNo(yes bool) string {
	si := style.SymOff + " Sì"
	no := style.SymOff + " No"
	if yes {
		return style.ItemTitleSel.Render(style.SymOn+" Sì") + "   " + style.ItemDesc.Render(no)
	}
	return style.ItemDesc.Render(si) + "   " + style.ItemTitleSel.Render(style.SymOn+" No")
}

func freq(weekly bool) string {
	g, w := "1 giorno", "1 settimana"
	if weekly {
		return style.ItemDesc.Render(g) + "   " + style.ItemTitleSel.Render(w)
	}
	return style.ItemTitleSel.Render(g) + "   " + style.ItemDesc.Render(w)
}
