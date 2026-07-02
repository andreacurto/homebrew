package setup

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// summaryView mostra una tabella pulita di tutte le scelte fatte nel wizard.
func (m Model) summaryView() string {
	theme := "Nessuno"
	if m.theme.selectionValue() != "" {
		theme = m.theme.selectionLabel()
	}
	auto := "No"
	if m.auto {
		auto = "Sì"
	}

	rows := [][2]string{
		{"App da installare", summaryCount(m.apps.selectedCount(), "Nessuna", "selezionate")},
		{"Strumenti terminale", summaryCount(m.tools.selectedCount(), "Nessuno", "selezionati")},
		{"Font terminale", summaryCount(m.fonts.selectedCount(), "Nessuno", "selezionati")},
		{"Tema terminale", theme},
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
	cmd := lipgloss.NewStyle().Foreground(style.Aquamarine).Bold(true)
	b.WriteString(style.ItemTitle.Render("Al termine dell'installazione potrai personalizzare in qualsiasi"))
	b.WriteString("\n")
	b.WriteString(style.ItemTitle.Render("momento Donkey lanciando il comando ") +
		cmd.Render("dk") +
		style.ItemTitle.Render(" da terminale."))
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
			b.WriteString(labelCell + ln + "\n")
		} else {
			b.WriteString(pad + ln + "\n")
		}
	}
	return b.String()
}

// summaryCount mostra sempre e solo il conteggio (mai l'elenco per nome), o la
// dicitura "nessuno/a" se non è stato selezionato niente.
func summaryCount(n int, none, plural string) string {
	if n == 0 {
		return none
	}
	return fmt.Sprintf("%d %s", n, plural)
}

func yesNo(v bool) string {
	if v {
		return "Sì"
	}
	return "No"
}
