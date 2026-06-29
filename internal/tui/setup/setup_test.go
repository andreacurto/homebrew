package setup

import (
	"strings"
	"testing"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

func TestChecklistChosen(t *testing.T) {
	items := []catalog.Entry{
		{Label: "A", Value: "a"},
		{Label: "B", Value: "b"},
		{Label: "C", Value: "c"},
	}
	c := newChecklist(items)
	c.toggle() // seleziona A
	c.down()
	c.down()
	c.toggle() // seleziona C

	got := c.chosen()
	if len(got) != 2 || got[0].Value != "a" || got[1].Value != "c" {
		t.Fatalf("chosen = %+v, attese A e C", got)
	}
}

func TestWelcomeView(t *testing.T) {
	v := New().View()
	if !strings.Contains(v, "Donkey") || !strings.Contains(v, style.RepoURL) {
		t.Error("la welcome view non contiene brand/URL del repo")
	}
}

func TestChecklistToggleAll(t *testing.T) {
	items := []catalog.Entry{
		{Label: "A", Value: "a"},
		{Label: "B", Value: "b"},
	}
	c := newChecklist(items)
	c.toggleAll() // tutte
	if len(c.chosen()) != 2 {
		t.Fatalf("toggleAll dovrebbe selezionare tutte, scelte = %d", len(c.chosen()))
	}
	c.toggleAll() // nessuna
	if len(c.chosen()) != 0 {
		t.Fatalf("toggleAll dovrebbe deselezionare tutte, scelte = %d", len(c.chosen()))
	}
}

func TestCatalogMsgLoadsApps(t *testing.T) {
	m := New()
	m.step = stepApps
	m.apps.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Apps, entries: []catalog.Entry{{Label: "Figma", Value: "figma"}}})
	mm := updated.(Model)

	if mm.apps.loading || !mm.apps.loaded {
		t.Fatal("dopo catalogMsg lo stato delle app dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Figma") {
		t.Error("la view App non mostra l'app caricata")
	}
}

func TestCatalogMsgLoadsFonts(t *testing.T) {
	m := New()
	m.step = stepFonts
	m.fonts.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Fonts, entries: []catalog.Entry{{Label: "Meslo LG Nerd Font", Value: "font-meslo-lg-nerd-font"}}})
	mm := updated.(Model)

	if mm.fonts.loading || !mm.fonts.loaded {
		t.Fatal("dopo catalogMsg lo stato dei font dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Meslo") {
		t.Error("la view Font non mostra il font caricato")
	}
}
