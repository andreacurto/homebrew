package setup

import (
	"strings"
	"testing"

	"github.com/andreacurto/donkey/internal/catalog"
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
	if !strings.Contains(v, "Benvenuto") || !strings.Contains(v, "Donkey") {
		t.Error("la welcome view non contiene brand/benvenuto")
	}
}

func TestCatalogMsgLoadsApps(t *testing.T) {
	m := New()
	m.step = stepApps
	m.loading = true

	updated, _ := m.Update(catalogMsg{entries: []catalog.Entry{{Label: "Figma", Value: "figma"}}})
	mm := updated.(Model)

	if mm.loading || !mm.appsLoaded {
		t.Fatal("dopo catalogMsg lo stato dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Figma") {
		t.Error("la view App non mostra l'app caricata")
	}
}
