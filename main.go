// Donkey — allestisci il tuo Mac, tienilo fresco.
package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/tui/menu"
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
		}
	}

	if _, err := tea.NewProgram(menu.New(), tea.WithAltScreen()).Run(); err != nil {
		fmt.Fprintln(os.Stderr, "errore:", err)
		os.Exit(1)
	}
}

func help() {
	fmt.Print(`donkey — allestisci il tuo Mac, tienilo fresco

Uso:
  dk            apre il menù principale
  dk version    mostra la versione
  dk help       mostra questo aiuto

I sottocomandi (app, terminal, update, autoupdate, status, setup, uninstall)
arriveranno nei prossimi passi della roadmap.
`)
}
