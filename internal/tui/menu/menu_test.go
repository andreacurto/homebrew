package menu

import (
	"strings"
	"testing"
)

// La View del menù deve contenere il brand, tutte le voci e il footer, senza panico.
func TestMenuViewContainsEntries(t *testing.T) {
	view := New().View()

	if !strings.Contains(view, "Donkey") {
		t.Error("la view non contiene il brand")
	}
	for _, e := range entries {
		if !strings.Contains(view, e.title) {
			t.Errorf("la view non contiene la voce %q", e.title)
		}
	}
	if !strings.Contains(view, "esci") {
		t.Error("la view non contiene il footer")
	}
}
