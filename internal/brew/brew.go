// Package brew è il confine tra Donkey e Homebrew: un wrapper sottile che esegue
// i comandi brew e ne cattura l'output. La TUI non lancia mai brew direttamente
// (AGENTS §3): passa da qui. L'esecuzione è dietro un Runner, così i test girano
// con un runner falso, senza toccare il sistema.
package brew

import (
	"errors"
	"os"
	"os/exec"
	"strings"
	"time"
)

// dryEnv è la variabile d'ambiente che attiva la modalità prova.
const dryEnv = "DONKEY_DRY_RUN"

// Result è l'esito di un comando: output combinato (stdout+stderr, utile per il
// pannello errori) ed eventuale errore.
type Result struct {
	Output string
	Err    error
}

// Ok indica che il comando è andato a buon fine.
func (r Result) Ok() bool { return r.Err == nil }

// Runner esegue un comando esterno. La TUI ne inietta uno finto nei test.
type Runner interface {
	Run(name string, args ...string) Result
}

// Client è il wrapper su brew.
type Client struct {
	run Runner
	dry bool // modalità prova: nessun comando viene eseguito davvero
}

// New crea un Client con un Runner esplicito (usato nei test).
func New(r Runner) *Client { return &Client{run: r} }

// NewDefault crea un Client che esegue davvero i comandi via os/exec.
func NewDefault() *Client { return New(execRunner{}) }

// NewDry crea un Client in modalità prova: il Mac non viene toccato.
// corePresent decide lo stato di partenza del Mac immaginato.
func NewDry(corePresent bool) *Client {
	return &Client{run: &dryRunner{core: corePresent}, dry: true}
}

// FromEnv crea il Client adatto all'ambiente, leggendo DONKEY_DRY_RUN:
//
//	1 | true | on → prova, Mac senza il core
//	present       → prova, Mac col core già presente
//	altro o vuoto → comandi reali
//
// Serve a sviluppare e collaudare il flusso senza installare nulla.
func FromEnv() *Client {
	switch strings.ToLower(strings.TrimSpace(os.Getenv(dryEnv))) {
	case "1", "true", "on", "yes":
		return NewDry(false)
	case "present":
		return NewDry(true)
	default:
		return NewDefault()
	}
}

// DryRun indica se il Client è in modalità prova: la TUI lo segnala a schermo,
// così una prova non viene scambiata per un'installazione vera.
func (c *Client) DryRun() bool { return c.dry }

// Present indica se Homebrew è disponibile (comando eseguibile).
func (c *Client) Present() bool {
	return c.run.Run("brew", "--version").Ok()
}

// Installed indica se un pacchetto (formula o cask) è già installato: evita
// reinstallazioni inutili durante il setup.
func (c *Client) Installed(pkg string) bool {
	return c.run.Run("brew", "list", pkg).Ok()
}

// Install installa un pacchetto. brew capisce da sé se è formula o cask, quindi
// la stessa chiamata vale per app, strumenti e font.
func (c *Client) Install(pkg string) Result {
	return c.run.Run("brew", "install", pkg)
}

// Uninstall rimuove un pacchetto (serve a dk app e all'uninstall).
func (c *Client) Uninstall(pkg string) Result {
	return c.run.Run("brew", "uninstall", pkg)
}

// Tap aggiunge un tap (es. domt4/autoupdate per l'auto-aggiornamento).
func (c *Client) Tap(name string) Result {
	return c.run.Run("brew", "tap", name)
}

// Run è la via di fuga a basso livello per comandi non coperti dai metodi sopra.
func (c *Client) Run(args ...string) Result {
	return c.run.Run("brew", args...)
}

// InstallHomebrew esegue lo script ufficiale in modo non interattivo. È l'unica
// operazione che non passa dal comando brew (che ancora non esiste).
func (c *Client) InstallHomebrew() Result {
	const script = `NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
	return c.run.Run("/bin/bash", "-c", script)
}

// execRunner è il Runner reale: esegue il comando con l'ambiente giusto (PATH di
// Homebrew, niente auto-update implicito) e ne cattura l'output combinato.
type execRunner struct{}

func (execRunner) Run(name string, args ...string) Result {
	cmd := exec.Command(name, args...)
	cmd.Env = brewEnv()
	out, err := cmd.CombinedOutput()
	return Result{Output: string(out), Err: err}
}

// brewEnv prepende i percorsi di Homebrew al PATH (Apple Silicon e Intel) e
// disattiva l'auto-update implicito prima di ogni install (più veloce, niente
// blocchi — come nel 1.x).
func brewEnv() []string {
	path := "/opt/homebrew/bin:/usr/local/bin:" + os.Getenv("PATH")
	env := os.Environ()
	out := make([]string, 0, len(env)+1)
	for _, e := range env {
		if strings.HasPrefix(e, "PATH=") {
			continue
		}
		out = append(out, e)
	}
	return append(out, "PATH="+path, "HOMEBREW_NO_AUTO_UPDATE=1")
}

// dryDelay è la pausa per comando in modalità prova: senza, le fasi lampeggiano
// e non si vede nulla. È una var e non una const così i test la azzerano.
var dryDelay = 500 * time.Millisecond

// errDryAbsent è l'errore con cui la modalità prova risponde "non c'è".
var errDryAbsent = errors.New("modalità prova: non installato")

// dryRunner è il Runner della modalità prova: immagina un Mac invece di
// toccarlo. Nessun comando viene eseguito.
//   - `brew --version` fallisce finché il core non è stato "installato"
//   - lo script del core lo installa nel Mac immaginato
//   - `brew list` dice sempre che manca, così si percorrono i rami d'installazione
//   - tutto il resto riesce
type dryRunner struct{ core bool }

func (d *dryRunner) Run(name string, args ...string) Result {
	time.Sleep(dryDelay)

	cmd := strings.TrimSpace(name + " " + strings.Join(args, " "))
	out := "modalità prova: " + cmd

	switch {
	case name != "brew": // lo script d'installazione del core
		d.core = true
		return Result{Output: out}
	case len(args) > 0 && args[0] == "--version":
		if !d.core {
			return Result{Output: out, Err: errDryAbsent}
		}
	case len(args) > 0 && args[0] == "list":
		return Result{Output: out, Err: errDryAbsent}
	}
	return Result{Output: out}
}
