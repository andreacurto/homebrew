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

func TestCatalogMsgLoadsTools(t *testing.T) {
	m := New()
	m.step = stepTools
	m.tools.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Tools, entries: []catalog.Entry{{Label: "GitHub CLI", Value: "gh"}}})
	mm := updated.(Model)

	if mm.tools.loading || !mm.tools.loaded {
		t.Fatal("dopo catalogMsg lo stato degli strumenti dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "GitHub CLI") {
		t.Error("la view Strumenti non mostra lo strumento caricato")
	}
	if len(mm.tools.chosenLabels()) != 0 {
		t.Error("nessuno strumento deve essere preselezionato")
	}
}

func TestAutoToggle(t *testing.T) {
	m := New()
	if !m.auto {
		t.Fatal("l'aggiornamento automatico dovrebbe essere attivo di default")
	}
	m.step = stepAuto
	updated, _ := m.Update(tea.KeyMsg{Type: tea.KeySpace})
	if updated.(Model).auto {
		t.Error("dopo Seleziona l'aggiornamento automatico dovrebbe essere disattivato")
	}
}

func TestInstallSimulationRunsToDone(t *testing.T) {
	m := New()
	m.step = stepInstall
	m.inst = newInstaller(m) // Homebrew + Configurazione terminale + Auto-update (default)

	// La schermata di avanzamento mostra le fasi base (mai "Homebrew": è tutto Donkey).
	v := m.View()
	if strings.Contains(v, "Homebrew") {
		t.Error("la view Installazione non deve citare Homebrew")
	}
	if !strings.Contains(v, "Preparazione dell'ambiente") || !strings.Contains(v, "Configurazione terminale") {
		t.Error("la view Installazione non elenca le fasi base")
	}
	if m.inst.done {
		t.Fatal("l'installazione non dovrebbe essere già conclusa")
	}

	// Avanza con i tick simulati finché non è tutto completato (guard anti-loop).
	var model tea.Model = m
	for i := 0; i < 100 && !model.(Model).inst.done; i++ {
		model, _ = model.Update(installTickMsg{})
	}
	mm := model.(Model)
	if !mm.inst.done {
		t.Fatal("dopo i tick l'installazione dovrebbe essere conclusa")
	}
	if !strings.Contains(mm.View(), "Tutto pronto") {
		t.Error("la schermata finale non mostra il messaggio di completamento")
	}

	// A installazione conclusa, Invio chiude il wizard.
	_, cmd := mm.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if cmd == nil {
		t.Error("Invio sulla schermata 'Fatto' dovrebbe uscire dal wizard")
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
