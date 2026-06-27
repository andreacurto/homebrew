// Package style centralizza palette, simboli e stili Lipgloss della TUI di Donkey.
// È l'unica fonte del look: cambiare qui si propaga a tutta l'interfaccia.
package style

import "github.com/charmbracelet/lipgloss"

// Palette Donkey (ispirata a Donkey Kong arcade). Nomi univoci, stile Tailwind.
var (
	Cream   = lipgloss.Color("#F3E9D2") // testo di base
	Ash     = lipgloss.Color("#838383") // testi secondari (muted)
	Coral   = lipgloss.Color("#FF3D2A") // brand / logo
	Gold    = lipgloss.Color("#F4BA15") // alert / slogan
	Magenta = lipgloss.Color("#EC3193") // selezione attiva
	Sky     = lipgloss.Color("#29B6F6") // comando aperto
)

// Simboli centralizzati (icone della UI).
const (
	SymCursor   = "❖"
	SymSuccess  = "✓"
	SymError    = "✗"
	SymInfo     = "◆"
	SymCheckOn  = "■"
	SymCheckOff = "□"
	SymOn       = "●"
	SymOff      = "○"
	SymWarning  = "▲"
)

// Assegnazione semantica: ruolo nella TUI → colore della palette.
var (
	Logo    = lipgloss.NewStyle().Foreground(Coral).Bold(true) // brand
	Tagline = lipgloss.NewStyle().Foreground(Gold)             // slogan
	URL     = lipgloss.NewStyle().Foreground(Ash)              // info secondaria
	Heading = lipgloss.NewStyle().Foreground(Sky).Bold(true)   // titolo del comando aperto

	// Voci di menù: il titolo passa da base a selezione; la descrizione da muted a base.
	ItemTitle    = lipgloss.NewStyle().Foreground(Cream)
	ItemTitleSel = lipgloss.NewStyle().Foreground(Magenta).Bold(true)
	ItemDesc     = lipgloss.NewStyle().Foreground(Ash)
	ItemDescSel  = lipgloss.NewStyle().Foreground(Cream)

	Cursor = lipgloss.NewStyle().Foreground(Magenta).Bold(true)
	Footer = lipgloss.NewStyle().Foreground(Ash)
	Alert  = lipgloss.NewStyle().Foreground(Gold)
	Screen = lipgloss.NewStyle().Padding(1, 2)
)
