package setup

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/andreacurto/donkey/internal/brew"
	"github.com/andreacurto/donkey/internal/state"
)

// coreRunner è un esecutore finto: registra i comandi e decide se il core
// risulta presente, prima e dopo l'installazione. Nessun comando viene eseguito.
type coreRunner struct {
	calls        []string
	present      bool   // il core risulta presente da subito
	presentAfter bool   // …e dopo che lo script è girato
	installFails bool   // lo script d'installazione fallisce
	output       string // output restituito dai comandi
	installed    bool
}

func (r *coreRunner) Run(name string, args ...string) brew.Result {
	call := strings.TrimSpace(name + " " + strings.Join(args, " "))
	r.calls = append(r.calls, call)

	res := brew.Result{Output: r.output}
	switch {
	case name != "brew": // lo script d'installazione del core
		r.installed = true
		if r.installFails {
			res.Err = os.ErrInvalid
		}
	case len(args) > 0 && args[0] == "--version":
		ok := r.present
		if r.installed {
			ok = r.presentAfter
		}
		if !ok {
			res.Err = os.ErrNotExist
		}
	}
	return res
}

// depsFor mette insieme un esecutore finto e un registro in una cartella usa e getta.
func depsFor(t *testing.T, r *coreRunner) (Deps, *state.Store) {
	t.Helper()
	s := state.New(filepath.Join(t.TempDir(), "donkey"))
	return Deps{Brew: brew.New(r), Store: s}, s
}

// manifestOf legge il registro dal disco; ok è falso se non esiste.
func manifestOf(t *testing.T, s *state.Store) (m state.Manifest, ok bool) {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(s.Dir(), "manifest.json"))
	if os.IsNotExist(err) {
		return m, false
	}
	if err != nil {
		t.Fatalf("lettura del registro: %v", err)
	}
	if err := json.Unmarshal(data, &m); err != nil {
		t.Fatalf("registro illeggibile: %v", err)
	}
	return m, true
}

func TestInstallCoreAlreadyPresent(t *testing.T) {
	r := &coreRunner{present: true}
	d, store := depsFor(t, r)

	res := installCore(d)

	if res.outcome != outSuccess {
		t.Errorf("esito = %d, atteso success", res.outcome)
	}
	if !strings.Contains(res.text, "Già presente") {
		t.Errorf("dicitura = %q, attesa quella di 'già presente'", res.text)
	}
	if len(r.calls) != 1 {
		t.Errorf("chiamate = %v, attesa la sola verifica", r.calls)
	}
	// Il core c'era già: non è Donkey ad averlo aggiunto, quindi non si annota.
	if _, ok := manifestOf(t, store); ok {
		t.Error("se il core c'era già il registro non deve essere scritto")
	}
}

func TestInstallCoreInstallsAndRecords(t *testing.T) {
	r := &coreRunner{present: false, presentAfter: true}
	d, store := depsFor(t, r)

	res := installCore(d)

	if res.outcome != outSuccess {
		t.Fatalf("esito = %d, atteso success", res.outcome)
	}
	if !r.installed {
		t.Error("lo script d'installazione del core non è stato invocato")
	}
	m, ok := manifestOf(t, store)
	if !ok {
		t.Fatal("il registro non è stato scritto")
	}
	if !m.HomebrewByDonkey {
		t.Error("il registro deve annotare che è stato Donkey a installare il core")
	}
}

func TestInstallCoreFailure(t *testing.T) {
	r := &coreRunner{installFails: true, output: "curl: impossibile scaricare"}
	d, store := depsFor(t, r)

	res := installCore(d)

	if res.outcome != outError {
		t.Errorf("esito = %d, atteso error", res.outcome)
	}
	if len(res.failed) != 1 || res.failed[0] != coreRecap {
		t.Errorf("failed = %v, atteso [%q]", res.failed, coreRecap)
	}
	if res.log == "" {
		t.Error("l'output del comando va conservato nel log")
	}
	if _, ok := manifestOf(t, store); ok {
		t.Error("un'installazione fallita non deve scrivere il registro")
	}
}

func TestInstallCoreScriptOkButStillAbsent(t *testing.T) {
	// Lo script si conclude senza errori ma il core resta irraggiungibile:
	// è la ri-verifica a doverlo cogliere.
	r := &coreRunner{present: false, presentAfter: false}
	d, store := depsFor(t, r)

	res := installCore(d)

	if res.outcome != outError {
		t.Errorf("esito = %d, atteso error: la ri-verifica deve cogliere il core assente", res.outcome)
	}
	if _, ok := manifestOf(t, store); ok {
		t.Error("senza un core funzionante il registro non va scritto")
	}
}

func TestInstallCoreRegistryUnwritable(t *testing.T) {
	// Un file al posto della cartella rende il registro non scrivibile.
	dir := filepath.Join(t.TempDir(), "donkey")
	if err := os.WriteFile(dir, []byte("non sono una cartella"), 0o644); err != nil {
		t.Fatal(err)
	}
	d := Deps{
		Brew:  brew.New(&coreRunner{present: false, presentAfter: true}),
		Store: state.New(dir),
	}

	res := installCore(d)

	if res.outcome != outWarning {
		t.Errorf("esito = %d, atteso warning: il core c'è, l'annotazione no", res.outcome)
	}
	if res.detail == "" {
		t.Error("il caso va spiegato con una riga di dettaglio, altrimenti il riepilogo è muto")
	}
}

func TestInstallCoreNilBrew(t *testing.T) {
	res := installCore(Deps{}) // niente panico

	if res.outcome != outError {
		t.Errorf("esito = %d, atteso error", res.outcome)
	}
}

func TestInstallCoreNeverNamesHomebrew(t *testing.T) {
	// Anche quando l'output del comando lo nomina, nulla di ciò che finisce a
	// schermo deve citarlo: l'output vive solo nel log, che non viene disegnato.
	cases := map[string]*coreRunner{
		"già presente": {present: true, output: "Homebrew 4.2.0"},
		"installato":   {presentAfter: true, output: "Homebrew installato in /opt/homebrew"},
		"fallito":      {installFails: true, output: "Error: Homebrew non è stato installato"},
	}

	for name, r := range cases {
		t.Run(name, func(t *testing.T) {
			d, _ := depsFor(t, r)
			res := installCore(d)

			visible := res.text + " " + res.detail + " " + strings.Join(res.failed, " ")
			if strings.Contains(strings.ToLower(visible), "brew") {
				t.Errorf("il testo mostrato all'utente cita il core per nome: %q", visible)
			}
		})
	}
}
