package menu

import (
	"strings"
	"testing"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// La View del menù deve contenere tutte le voci e il footer, senza panico.
func TestMenuViewContainsEntries(t *testing.T) {
	view := New().View()
	for _, e := range entries {
		if !strings.Contains(view, e.title) {
			t.Errorf("la view non contiene la voce %q", e.title)
		}
	}
	if !strings.Contains(view, "Esci") {
		t.Error("la view non contiene il footer")
	}
}

// Il logo incorporato deve essere non vuoto e comparire nel menù.
func TestMenuViewHasLogo(t *testing.T) {
	if style.DonkeyLogo() == "" {
		t.Fatal("DonkeyLogo() è vuoto: embed del logo fallito?")
	}
	// Nella view il logo è indentato; cerchiamo un suo codice colore (marrone DK),
	// intatto a metà riga.
	if !strings.Contains(New().View(), "140;84;36") {
		t.Error("la view del menù non contiene il logo")
	}
}
