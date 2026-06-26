package catalog

import (
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	in := `# commento da ignorare
1Password|1password

  Figma | figma
riga-senza-separatore
|valore-senza-etichetta
etichetta-senza-valore|
`
	got, err := Parse(strings.NewReader(in))
	if err != nil {
		t.Fatalf("Parse ha restituito errore: %v", err)
	}

	want := []Entry{
		{Label: "1Password", Value: "1password"},
		{Label: "Figma", Value: "figma"},
	}
	if len(got) != len(want) {
		t.Fatalf("ottenute %d voci, attese %d: %+v", len(got), len(want), got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("voce %d = %+v, attesa %+v", i, got[i], want[i])
		}
	}
}

// Verifica il fetch da sorgente locale (override DONKEY_CATALOG_URL) sui
// cataloghi reali del repo.
func TestFetchLocal(t *testing.T) {
	t.Setenv("DONKEY_CATALOG_URL", "../../config")

	apps, err := Fetch(Apps)
	if err != nil {
		t.Fatalf("Fetch(%q): %v", Apps, err)
	}
	if len(apps) == 0 {
		t.Fatal("catalogo app vuoto")
	}

	var found bool
	for _, e := range apps {
		if e.Value == "figma" {
			found = true
		}
	}
	if !found {
		t.Error("la voce Figma non è presente nel catalogo app")
	}
}
