package brew

import (
	"errors"
	"strings"
	"testing"
)

// fakeRunner registra le chiamate e simula esiti/output per comando.
type fakeRunner struct {
	calls []string
	fail  map[string]bool   // chiave (comando completo) → deve fallire
	out   map[string]string // chiave → output simulato
}

func newFake() *fakeRunner {
	return &fakeRunner{fail: map[string]bool{}, out: map[string]string{}}
}

func (f *fakeRunner) Run(name string, args ...string) Result {
	key := strings.TrimSpace(name + " " + strings.Join(args, " "))
	f.calls = append(f.calls, key)
	res := Result{Output: f.out[key]}
	if f.fail[key] {
		res.Err = errors.New("comando fallito: " + key)
	}
	return res
}

func TestPresent(t *testing.T) {
	f := newFake()
	if !New(f).Present() {
		t.Error("con brew --version a buon fine, Present dovrebbe essere true")
	}
	f.fail["brew --version"] = true
	if New(f).Present() {
		t.Error("se brew --version fallisce, Present dovrebbe essere false")
	}
	if got := f.calls[0]; got != "brew --version" {
		t.Errorf("comando = %q, atteso 'brew --version'", got)
	}
}

func TestInstall(t *testing.T) {
	f := newFake()
	c := New(f)

	if r := c.Install("figma"); !r.Ok() {
		t.Error("install di un pacchetto valido dovrebbe riuscire")
	}
	if got := f.calls[len(f.calls)-1]; got != "brew install figma" {
		t.Errorf("comando = %q, atteso 'brew install figma'", got)
	}

	f.fail["brew install rotto"] = true
	f.out["brew install rotto"] = "Error: No available formula"
	r := c.Install("rotto")
	if r.Ok() {
		t.Error("install fallita dovrebbe riportare errore")
	}
	if !strings.Contains(r.Output, "No available formula") {
		t.Errorf("l'output dell'errore dovrebbe essere catturato, ho %q", r.Output)
	}
}

func TestInstalled(t *testing.T) {
	f := newFake()
	c := New(f)
	f.fail["brew list mancante"] = true

	if !c.Installed("presente") {
		t.Error("brew list a buon fine → pacchetto installato")
	}
	if c.Installed("mancante") {
		t.Error("brew list fallito → pacchetto non installato")
	}
}

func TestInstallHomebrew(t *testing.T) {
	f := newFake()
	New(f).InstallHomebrew()
	if len(f.calls) != 1 || !strings.HasPrefix(f.calls[0], "/bin/bash -c") {
		t.Errorf("InstallHomebrew dovrebbe invocare /bin/bash -c, ho %v", f.calls)
	}
	if !strings.Contains(f.calls[0], "NONINTERACTIVE=1") {
		t.Error("lo script di Homebrew deve girare in modo non interattivo")
	}
}

// In modalità prova la pausa serve solo a far vedere lo spinner: nei test la
// azzeriamo, altrimenti ogni comando costerebbe mezzo secondo.
func init() { dryDelay = 0 }

func TestDryRunNeverExecutes(t *testing.T) {
	c := NewDry(false) // Mac immaginato senza il core

	if !c.DryRun() {
		t.Error("NewDry deve segnalarsi come modalità prova")
	}
	if c.Present() {
		t.Error("senza core, Present() deve essere falso")
	}
	if !c.InstallHomebrew().Ok() {
		t.Fatal("l'installazione del core in prova deve riuscire")
	}
	if !c.Present() {
		t.Error("dopo l'installazione, Present() deve essere vero")
	}
	if c.Installed("spotify") {
		t.Error("in prova nessun pacchetto risulta installato")
	}
	if r := c.Install("spotify"); !r.Ok() || !strings.Contains(r.Output, "modalità prova") {
		t.Errorf("l'installazione in prova deve riuscire e dichiararsi tale: %+v", r)
	}
}

func TestDryRunCorePresent(t *testing.T) {
	c := NewDry(true) // Mac immaginato col core già installato

	if !c.Present() {
		t.Error("con corePresent, Present() deve essere vero senza installare nulla")
	}
}

func TestFromEnv(t *testing.T) {
	cases := []struct {
		env     string
		dry     bool
		present bool
	}{
		{"1", true, false},
		{"true", true, false},
		{"ON", true, false},
		{"present", true, true},
		{"", false, false},
		{"boh", false, false},
	}

	for _, tc := range cases {
		t.Run("DONKEY_DRY_RUN="+tc.env, func(t *testing.T) {
			t.Setenv(dryEnv, tc.env)
			c := FromEnv()
			if c.DryRun() != tc.dry {
				t.Fatalf("DryRun() = %v, atteso %v", c.DryRun(), tc.dry)
			}
			// Present() si interroga solo in prova: sul runner reale eseguirebbe brew.
			if tc.dry && c.Present() != tc.present {
				t.Errorf("Present() = %v, atteso %v", c.Present(), tc.present)
			}
		})
	}
}
