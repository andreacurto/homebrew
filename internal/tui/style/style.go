// Package style centralizza la palette e gli stili Lipgloss della TUI di Donkey.
// È l'unica fonte del look: cambiare i colori qui si propaga a tutta l'interfaccia.
package style

import "github.com/charmbracelet/lipgloss"

// Palette (256-color). Unico punto in cui vivono i colori.
var (
	Primary = lipgloss.Color("10")  // verde brillante
	Accent  = lipgloss.Color("14")  // cyan
	Text    = lipgloss.Color("252") // testo chiaro
	Muted   = lipgloss.Color("244") // grigio
	Danger  = lipgloss.Color("9")   // rosso
)

// Stili riusabili, derivati dalla palette.
var (
	Logo         = lipgloss.NewStyle().Foreground(Primary).Bold(true)
	Tagline      = lipgloss.NewStyle().Foreground(Muted)
	URL          = lipgloss.NewStyle().Foreground(Accent)
	Heading      = lipgloss.NewStyle().Foreground(Accent).Bold(true)
	ItemTitle    = lipgloss.NewStyle().Foreground(Text)
	ItemTitleSel = lipgloss.NewStyle().Foreground(Primary).Bold(true)
	ItemDesc     = lipgloss.NewStyle().Foreground(Muted)
	Cursor       = lipgloss.NewStyle().Foreground(Primary).Bold(true)
	Footer       = lipgloss.NewStyle().Foreground(Muted)
	Error        = lipgloss.NewStyle().Foreground(Danger)
	Screen       = lipgloss.NewStyle().Padding(1, 2)
)
