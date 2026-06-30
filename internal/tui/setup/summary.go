package setup

import (
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// Larghezze delle due colonne del riepilogo.
const (
	sumLabelW = 18
	sumValueW = 58
)

// summaryView mostra una tabella pulita di tutte le scelte fatte nel wizard.
func (m Model) summaryView() string {
	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "Riepilogo"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Ecco cosa Donkey farà sul tuo Mac:"))
	b.WriteString("\n\n")

	theme := "Nessuno"
	if m.theme.selectionValue() != "" {
		theme = m.theme.selectionLabel()
	}
	auto := "No"
	if m.auto {
		auto = "Sì · 1 volta a settimana"
	}

	b.WriteString(summaryRow("App", joinOrNone(m.apps.chosenLabels(), "Nessuna")))
	b.WriteString(summaryRow("Font terminale", joinOrNone(m.fonts.chosenLabels(), "Nessuno")))
	b.WriteString(summaryRow("Tema terminale", theme))
	b.WriteString(summaryRow("Suggerimenti", yesNo(m.suggest)))
	b.WriteString(summaryRow("Aggiornamenti", auto))

	b.WriteString("\n")
	b.WriteString(style.ItemDesc.Render("Premi Invio per installare, o torna indietro per modificare."))
	b.WriteString("\n\n")
	b.WriteString(style.Hints(
		style.FootKey{Key: "Invio", Desc: "Installa"},
		style.FootKey{Key: "Esc", Desc: "Indietro"},
		style.FootKey{Key: "Q", Desc: "Esci"},
	))
	return style.Screen.Render(b.String())
}

// summaryRow disegna una riga della tabella: etichetta (ash) a sinistra e
// valore (crema) a destra, con a-capo a rientro sotto la colonna del valore.
func summaryRow(label, value string) string {
	wrapped := lipgloss.NewStyle().Width(sumValueW).Render(value)
	lines := strings.Split(wrapped, "\n")
	labelCell := style.ItemDesc.Width(sumLabelW).Render(label)
	pad := strings.Repeat(" ", sumLabelW)

	var b strings.Builder
	for i, ln := range lines {
		ln = style.ItemTitle.Render(strings.TrimRight(ln, " "))
		if i == 0 {
			b.WriteString("  " + labelCell + ln + "\n")
		} else {
			b.WriteString("  " + pad + ln + "\n")
		}
	}
	return b.String()
}

func joinOrNone(labels []string, none string) string {
	if len(labels) == 0 {
		return none
	}
	return strings.Join(labels, " · ")
}

func yesNo(v bool) string {
	if v {
		return "Sì"
	}
	return "No"
}
