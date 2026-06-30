package setup

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/tui/style"
)

func TestWelcomeView(t *testing.T) {
	v := New().View()
	if !strings.Contains(v, "Donkey") || !strings.Contains(v, style.RepoURL) {
		t.Error("la welcome view non contiene brand/URL del repo")
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

	updated, _ := m.Update(catalogMsg{target: catalog.Fonts, entries: []catalog.Entry{{Label: "Fira Code", Value: "font-fira-code-nerd-font"}}})
	mm := updated.(Model)

	if mm.fonts.loading || !mm.fonts.loaded {
		t.Fatal("dopo catalogMsg lo stato dei font dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Fira Code") {
		t.Error("la view Font non mostra il font caricato")
	}
}

func TestCatalogMsgLoadsThemes(t *testing.T) {
	m := New()
	m.step = stepTheme
	m.theme.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Themes, entries: []catalog.Entry{{Label: "Atomic", Value: "atomic"}}})
	mm := updated.(Model)

	if mm.theme.loading || !mm.theme.loaded {
		t.Fatal("dopo catalogMsg lo stato del tema dovrebbe essere caricato")
	}
	v := mm.View()
	if !strings.Contains(v, "Atomic") || !strings.Contains(v, "Nessun tema") {
		t.Error("la view Tema deve mostrare il tema caricato e la voce 'Nessun tema'")
	}
	if mm.theme.selectionLabel() != "Nessun tema" {
		t.Errorf("default = %q, atteso 'Nessun tema' (prima voce)", mm.theme.selectionLabel())
	}
}

func TestPickerToggle(t *testing.T) {
	p := newPicker(catalog.Apps, "App", "x", "", false)
	p.setResult([]catalog.Entry{{Label: "A", Value: "a"}, {Label: "B", Value: "b"}}, nil)

	if p.selectedCount() != 0 {
		t.Fatalf("conteggio iniziale = %d, atteso 0", p.selectedCount())
	}
	p.update(tea.KeyMsg{Type: tea.KeySpace}) // seleziona la voce sotto il cursore (A)
	if p.selectedCount() != 1 {
		t.Fatalf("dopo il toggle = %d, atteso 1", p.selectedCount())
	}
	p.update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("a")}) // seleziona tutte
	if p.selectedCount() != 2 {
		t.Fatalf("dopo 'seleziona tutto' = %d, atteso 2", p.selectedCount())
	}
}
