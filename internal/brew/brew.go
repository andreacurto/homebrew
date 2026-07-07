// Package brew è il confine tra Donkey e Homebrew: un wrapper sottile che esegue
// i comandi brew e ne cattura l'output. La TUI non lancia mai brew direttamente
// (AGENTS §3): passa da qui. L'esecuzione è dietro un Runner, così i test girano
// con un runner falso, senza toccare il sistema.
package brew

import (
	"os"
	"os/exec"
	"strings"
)

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
}

// New crea un Client con un Runner esplicito (usato nei test).
func New(r Runner) *Client { return &Client{run: r} }

// NewDefault crea un Client che esegue davvero i comandi via os/exec.
func NewDefault() *Client { return New(execRunner{}) }

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
