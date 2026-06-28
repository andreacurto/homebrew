// Package style centralizza palette, simboli e stili Lipgloss della TUI di Donkey.
// È l'unica fonte del look: cambiare qui si propaga a tutta l'interfaccia.
package style

import (
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/lipgloss"
)

// Palette Donkey (ispirata a Donkey Kong arcade). Nomi univoci, stile Tailwind.
var (
	Cream      = lipgloss.Color("#F3E9D2") // testo di base
	Ash        = lipgloss.Color("#838383") // testi secondari (muted)
	Coral      = lipgloss.Color("#FE3850") // brand + selezione attiva
	Cheddar    = lipgloss.Color("#F1A90E") // alert / slogan
	Aquamarine = lipgloss.Color("#01C5B4") // comando aperto
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
	Logo    = lipgloss.NewStyle().Foreground(Coral).Bold(true)      // brand "Donkey"
	Bullet  = lipgloss.NewStyle().Foreground(Ash)                   // il "•" tra nome e slogan/schermata
	Tagline = lipgloss.NewStyle().Foreground(Cheddar)               // slogan
	URL     = lipgloss.NewStyle().Foreground(Ash)                   // info secondaria
	Heading = lipgloss.NewStyle().Foreground(Aquamarine).Bold(true) // nome del comando/vista aperta

	// Voci di menù/liste: il titolo passa da base a selezione; la descrizione da muted a base.
	ItemTitle    = lipgloss.NewStyle().Foreground(Cream)
	ItemTitleSel = lipgloss.NewStyle().Foreground(Coral).Bold(true)
	ItemDesc     = lipgloss.NewStyle().Foreground(Ash)
	ItemDescSel  = lipgloss.NewStyle().Foreground(Cream)

	Cursor = lipgloss.NewStyle().Foreground(Coral).Bold(true)
	Footer = lipgloss.NewStyle().Foreground(Ash)
	Alert  = lipgloss.NewStyle().Foreground(Cheddar)
	Error  = lipgloss.NewStyle().Foreground(Coral)
	Screen = lipgloss.NewStyle().Padding(1, 2)
)

// MonkeySpinner è lo spinner brandizzato: tre scimmiette + la faccia.
var MonkeySpinner = spinner.Spinner{
	Frames: []string{"🙈", "🙉", "🙊", "🐵"},
	FPS:    time.Second / 5,
}

// NewSpinner crea uno spinner già impostato sullo stile Donkey.
func NewSpinner() spinner.Model {
	s := spinner.New()
	s.Spinner = MonkeySpinner
	return s
}

// Brand compone l'header "🐒 Donkey • <destra>", presente in tutte le schermate.
func Brand(right string, rightStyle lipgloss.Style) string {
	return "🐒 " + Logo.Render("Donkey") + Bullet.Render(" • ") + rightStyle.Render(right)
}
