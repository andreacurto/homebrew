// Package style centralizza palette, simboli e stili Lipgloss della TUI di Donkey.
// È l'unica fonte del look: cambiare qui si propaga a tutta l'interfaccia.
package style

import (
	"strings"
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

	// Campo di ricerca: box stile input, bordo e testo cheddar.
	SearchBox  = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(Cheddar).Padding(0, 1).Width(40)
	SearchText = lipgloss.NewStyle().Foreground(Cheddar)
	SearchHint = lipgloss.NewStyle().Foreground(Ash)
	Alert      = lipgloss.NewStyle().Foreground(Cheddar)
	Error      = lipgloss.NewStyle().Foreground(Coral)
	Screen     = lipgloss.NewStyle().Padding(1, 2)
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

// RepoURL è l'indirizzo del progetto, mostrato sotto il brand in ogni schermata.
const RepoURL = "github.com/andreacurto/donkey"

// Header compone l'intestazione comune a tutte le schermate:
//
//	🐵 Donkey • <secondo livello> [• <terzo livello>]
//	github.com/andreacurto/donkey
//
// secondStyle veste il secondo livello (slogan nel menù, nome vista altrove);
// third, se non vuoto, aggiunge un terzo livello breadcrumb sempre in ash.
func Header(second string, secondStyle lipgloss.Style, third string) string {
	line := "🐵 " + Logo.Render("Donkey") + Bullet.Render(" • ") + secondStyle.Render(second)
	if third != "" {
		line += Bullet.Render(" • ") + URL.Render(third)
	}
	return line + "\n" + URL.Render(RepoURL)
}

// FootKey è una voce della barra comandi: un tasto con descrizione opzionale.
// Se Desc è vuota mostra solo il tasto (es. le frecce di navigazione).
type FootKey struct {
	Key  string
	Desc string
}

var (
	footKeyStyle = lipgloss.NewStyle().Foreground(Cream) // il tasto risalta
	footSepStyle = lipgloss.NewStyle().Foreground(Ash)   // descrizione e separatori
)

// Hints compone la barra comandi in fondo alle schermate. Il tasto risalta,
// la descrizione (dopo un dash lungo) è muted, i comandi sono divisi da "│":
//
//	↑↓  │  Invio — avanti  │  Esc — indietro  │  Q — esci
func Hints(keys ...FootKey) string {
	parts := make([]string, 0, len(keys))
	for _, k := range keys {
		s := footKeyStyle.Render(k.Key)
		if k.Desc != "" {
			s += footSepStyle.Render(" — " + k.Desc)
		}
		parts = append(parts, s)
	}
	return strings.Join(parts, footSepStyle.Render("  │  "))
}
