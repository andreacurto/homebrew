package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// maxSummaryNames: oltre questa soglia il riepilogo mostra il conteggio invece
// dell'elenco, così la tabella resta compatta anche con molte selezioni.
const maxSummaryNames = 8

// summaryView mostra una tabella pulita di tutte le scelte fatte nel wizard.
func (m Model) summaryView() string {
	theme := "Nessuno"
	if m.theme.selectionValue() != "" {
		theme = m.theme.selectionLabel()
	}
	auto := "No"
	if m.auto {
		auto = "Sì · 1 volta a settimana"
	}

	rows := [][2]string{
		{"App da installare", summaryList(m.apps.chosenLabels(), "Nessuna", "app selezionate")},
		{"Font terminale", summaryList(m.fonts.chosenLabels(), "Nessuno", "font selezionati")},
		{"Tema terminale", theme},
		{"Suggerimenti automatici terminale", yesNo(m.suggest)},
		{"Aggiornamenti automatici", auto},
	}

	labelW := 0
	for _, r := range rows {
		if l := lipgloss.Width(r[0]); l > labelW {
			labelW = l
		}
	}
	labelW += 3
	width := m.width
	if width == 0 {
		width = 90
	}
	valueW := width - labelW - 6
	if valueW < 20 {
		valueW = 20
	}

	var b strings.Builder
	b.WriteString(style.Header("Setup", style.Heading, "Riepilogo"))
	b.WriteString("\n\n")
	b.WriteString(style.ItemTitle.Render("Ecco cosa farà Donkey sul tuo Mac:"))
	b.WriteString("\n\n")
	for _, r := range rows {
		b.WriteString(summaryRow(r[0], r[1], labelW, valueW))
	}
	b.WriteString("\n")
	cmd := lipgloss.NewStyle().Foreground(style.Cheddar).Bold(true)
	b.WriteString(style.ItemDesc.Render("Dopo l'installazione, utilizzando il comando ") +
		cmd.Render("donkey") +
		style.ItemDesc.Render(" (o ") +
		cmd.Render("dk") +
		style.ItemDesc.Render(" in forma\nabbreviata) potrai personalizzare Donkey in qualsiasi momento."))
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
func summaryRow(label, value string, labelW, valueW int) string {
	wrapped := lipgloss.NewStyle().Width(valueW).Render(value)
	lines := strings.Split(wrapped, "\n")
	labelCell := style.ItemDesc.Width(labelW).Render(label)
	pad := strings.Repeat(" ", labelW)

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

// summaryList: elenco per nome se le voci sono poche, altrimenti conteggio.
func summaryList(labels []string, none, plural string) string {
	switch n := len(labels); {
	case n == 0:
		return none
	case n <= maxSummaryNames:
		return strings.Join(labels, " · ")
	default:
		return fmt.Sprintf("%d %s", n, plural)
	}
}

func yesNo(v bool) string {
	if v {
		return "Sì"
	}
	return "No"
}
