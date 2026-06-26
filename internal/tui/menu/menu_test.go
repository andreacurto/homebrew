package menu

import (
	"strings"
	"testing"
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
