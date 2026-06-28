// Donkey — allestisci il tuo Mac, tienilo fresco.
package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/tui/menu"
	"github.com/andreacurto/donkey/internal/tui/setup"
)

const version = "2.0.0-dev"

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "version", "-v", "--version":
			fmt.Println("donkey v" + version)
			return
		case "help", "-h", "--help":
			help()
			return
		case "setup":
			run(setup.New())
			return
		}
	}
	run(menu.New())
}

// run avvia un programma Bubble Tea a schermo intero.
func run(m tea.Model) {
	if _, err := tea.NewProgram(m, tea.WithAltScreen()).Run(); err != nil {
		fmt.Fprintln(os.Stderr, "errore:", err)
		os.Exit(1)
	}
}

func help() {
	fmt.Print(`donkey — allestisci il tuo Mac, tienilo fresco

Uso:
  dk            apre il menù principale
  dk setup      avvia l'onboarding
  dk version    mostra la versione
  dk help       mostra questo aiuto

I sottocomandi (app, terminal, update, autoupdate, status, uninstall)
arriveranno nei prossimi passi della roadmap.
`)
}
