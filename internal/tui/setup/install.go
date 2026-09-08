package setup

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/andreacurto/donkey/internal/tui/style"
)

// installStepMsg segna il completamento di un sotto-passo *simulato*: l'installer
// avanza e la fase corrente prosegue. Vale solo per le fasi ancora finte.
type installStepMsg struct{}

// installPhaseDoneMsg porta l'esito di una fase *reale*, che si conclude tutta
// insieme quando il comando ritorna. index identifica la fase: un messaggio in
// ritardo, riferito a una fase già chiusa, viene scartato.
type installPhaseDoneMsg struct {
	index int
	res   phaseResult
}

// phaseResult è l'esito di una fase reale: lo produce il comando che l'ha
// eseguita, non lo deduce la checklist guardando le etichette.
//   - text:   dicitura nella tabella finale; vuoto = quella standard
//   - detail: riga di dettaglio nel riepilogo; vuoto = quella standard
//   - log:    output del comando. Non viene mai disegnato: serve a un futuro
//     registro, e tenerlo fuori dalle viste è ciò che impedisce al nome vero
//     del core di finire a schermo.
type phaseResult struct {
	outcome instOutcome
	failed  []string
	text    string
	detail  string
	log     string
}

// Ritmo della simulazione. Le raccolte (app/font…) avanzano di un passo per voce;
// i passi singoli (preparazione, tema, terminale…) hanno più sotto-passi solo per
// far durare un attimo lo spinner. Tarabili.
const (
	collectionDelay = 120 * time.Millisecond
	singletonTicks  = 6
	singletonDelay  = 90 * time.Millisecond
)

// Aggancio TEMPORANEO di sola simulazione: fa fallire un font, così si vede
// l'esito ▲ nella schermata finale. Va rimosso quando i font si installeranno
// davvero. L'equivalente per gli strumenti non serve più: da quando la fase
// core è reale, l'esito ✗ si ottiene senza fingerlo.
const simulateFontWarning = true

// instState è lo stato di una fase rispetto al puntatore di avanzamento.
type instState int

const (
	instPending instState = iota
	instRunning
	instDone
)

// instOutcome è l'esito di una fase conclusa.
type instOutcome int

const (
	outSuccess instOutcome = iota
	outWarning             // raccolta completata solo in parte
	outError               // fase non riuscita (o raccolta tutta fallita)
)

// instPhase è un blocco della checklist.
//   - name:  etichetta d'azione mostrata durante l'installazione ("Installazione App")
//   - recap: etichetta breve per la tabella finale ("App"), come nel pre-installazione
//   - items: etichette degli elementi (vuoto per le fasi singole)
//   - failed: elementi non installati (sottoinsieme di items); per una fase singola,
//     se non vuoto la fase è considerata fallita
//   - config: fase di configurazione (non installazione) → esito "Configurazione …"
//   - run:  se valorizzato la fase è **reale**: un comando la esegue tutta e ne
//     restituisce l'esito. Se è nil la fase è simulata e avanza a sotto-passi.
//   - res:  l'esito di una fase reale conclusa (nil finché non è conclusa)
type instPhase struct {
	name   string
	recap  string
	items  []string
	failed []string
	config bool
	ticks  int
	delay  time.Duration

	run func(index int) tea.Cmd
	res *phaseResult
}

// outcome è l'esito della fase: quello dichiarato dal comando se la fase è
// reale, altrimenti dedotto dagli elementi falliti.
func (ph instPhase) outcome() instOutcome {
	if ph.res != nil {
		return ph.res.outcome
	}
	if len(ph.failed) == 0 {
		return outSuccess
	}
	if len(ph.items) == 0 || len(ph.failed) >= len(ph.items) {
		return outError
	}
	return outWarning
}

// installer esegue la checklist in modo sequenziale: pi è la fase corrente,
// prog i sotto-passi già completati in quella fase (solo per le fasi simulate;
// una fase reale si conclude tutta insieme).
type installer struct {
	phases []instPhase
	pi     int
	prog   int
	done   bool
}

// newInstaller compone la checklist dalle scelte del wizard. La preparazione e
// la configurazione del terminale ci sono sempre; il resto è condizionale.
// Nessuna fase cita Homebrew: per l'utente è tutto "Donkey".
func newInstaller(m Model) installer {
	single := func(name, recap string) instPhase {
		return instPhase{name: name, recap: recap, ticks: singletonTicks, delay: singletonDelay}
	}
	collection := func(name, recap string, items []string) instPhase {
		return instPhase{name: name, recap: recap, items: items, ticks: len(items), delay: collectionDelay}
	}

	ph := []instPhase{single("Installazione Donkey core", "Donkey core")}
	if items := m.apps.chosenLabels(); len(items) > 0 {
		ph = append(ph, collection("Installazione App", "App", items))
	}
	if items := m.tools.chosenLabels(); len(items) > 0 {
		ph = append(ph, collection("Installazione Strumenti terminale", "Strumenti terminale", items))
	}
	if items := m.fonts.chosenLabels(); len(items) > 0 {
		fonts := collection("Installazione Font", "Font terminale", items)
		if simulateFontWarning {
			fonts.failed = []string{items[len(items)-1]} // simula: un font non installato
		}
		ph = append(ph, fonts)
	}
	// La configurazione del terminale (zshrc: autocompletamento, alias e, se scelto,
	// il tema) è sempre presente. Il tema non è più una fase a sé.
	term := single("Configurazione terminale", "Configurazione terminale")
	term.config = true
	ph = append(ph, term)
	if m.auto {
		au := single("Configurazione aggiornamenti automatici", "Aggiornamenti automatici")
		au.config = true
		ph = append(ph, au)
	}
	return installer{phases: ph}
}

// next programma il prossimo passo: il comando della fase, se è reale, oppure
// il timer della simulazione. È l'unico punto che conosce la differenza.
func (in installer) next() tea.Cmd {
	if in.pi >= len(in.phases) {
		return nil
	}
	ph := in.phases[in.pi]
	if ph.run != nil {
		return ph.run(in.pi)
	}
	return tea.Tick(ph.delay, func(time.Time) tea.Msg { return installStepMsg{} })
}

// realNow indica se la fase in corso è reale: serve a scartare i tick simulati
// che non le competono.
func (in installer) realNow() bool {
	return in.pi < len(in.phases) && in.phases[in.pi].run != nil
}

// complete chiude *l'intera* fase reale corrente con l'esito ricevuto. È il
// gemello di advance() per le fasi che non hanno sotto-passi.
func (in *installer) complete(res phaseResult) {
	if in.pi >= len(in.phases) {
		in.done = true
		return
	}
	ph := &in.phases[in.pi]
	ph.failed = res.failed
	ph.res = &res

	in.pi++
	in.prog = 0
	if in.pi >= len(in.phases) {
		in.done = true
	}
}

// advance completa un sotto-passo *simulato*; esaurita la fase passa alla
// successiva, ed esaurite tutte le fasi l'installazione è conclusa.
func (in *installer) advance() {
	if in.pi >= len(in.phases) {
		in.done = true
		return
	}
	in.prog++
	if in.prog >= in.phases[in.pi].ticks {
		in.pi++
		in.prog = 0
	}
	if in.pi >= len(in.phases) {
		in.done = true
	}
}

// stateOf classifica una fase rispetto al puntatore di avanzamento.
func (in installer) stateOf(p int) instState {
	switch {
	case in.done || p < in.pi:
		return instDone
	case p == in.pi:
		return instRunning
	default:
		return instPending
	}
}

// render disegna la checklist in corso: una riga per fase con marcatore e nome.
// Niente percentuali: la fase in corso è lo spinner, l'esito è ✓/▲/✗.
//   - ✓ aquamarine + nome crema = fatto
//   - ▲ cheddar    + nome crema = fatto con avviso
//   - ✗ coral      + nome crema = non riuscito
//   - spinner      + nome coral = in lavorazione
//   - ○ ash        + nome ash   = in attesa
func (in installer) render(spin spinner.Model) string {
	var b strings.Builder
	for i, ph := range in.phases {
		switch in.stateOf(i) {
		case instRunning:
			marker := lipgloss.NewStyle().Width(2).Render(spin.View())
			name := lipgloss.NewStyle().Foreground(style.Coral).Bold(true).Render(ph.name)
			b.WriteString("  " + marker + " " + name + "\n")
		case instDone:
			sym, col := outcomeMarker(ph.outcome())
			name := lipgloss.NewStyle().Foreground(style.Cream).Render(ph.name)
			b.WriteString("  " + markerCell(sym, col) + " " + name + "\n")
		default:
			name := lipgloss.NewStyle().Foreground(style.Ash).Render(ph.name)
			b.WriteString("  " + markerCell(style.SymOff, style.Ash) + " " + name + "\n")
		}
	}
	return strings.TrimRight(b.String(), "\n")
}

// recapTable disegna la tabella finale: etichetta breve (ash) a sinistra, esito
// colorato a destra. Nessuna indentazione, nessun conteggio: solo lo stato.
func (in installer) recapTable() string {
	labelW := 0
	for _, ph := range in.phases {
		if w := lipgloss.Width(ph.recap); w > labelW {
			labelW = w
		}
	}
	labelW += 3

	var b strings.Builder
	for _, ph := range in.phases {
		o := ph.outcome()
		sym, col := outcomeMarker(o)
		text := outcomeText(o, ph.config)
		if ph.res != nil && ph.res.text != "" {
			text = ph.res.text // una fase reale sa dire meglio com'è andata
		}
		esito := lipgloss.NewStyle().Foreground(col).Render(sym + " " + text)
		label := style.ItemDesc.Width(labelW).Render(ph.recap)
		b.WriteString(label + esito + "\n")
	}
	return strings.TrimRight(b.String(), "\n")
}

// recapDetails elenca, per ogni fase non riuscita del tutto o in parte, cosa
// esattamente non è stato installato, in forma stringata:
//
//	Font terminale: installazione 'Zed Mono' non riuscita
//
// Avvisi in cheddar, errori in coral. Stringa vuota se è filato tutto liscio.
func (in installer) recapDetails() string {
	var lines []string
	for _, ph := range in.phases {
		o := ph.outcome()

		// Una fase reale può dettare la propria riga: senza, un avviso su una
		// fase singola finirebbe a stampare un elenco vuoto.
		if ph.res != nil && ph.res.detail != "" {
			st := style.Alert
			if o == outError {
				st = style.Error
			}
			lines = append(lines, st.Render(ph.res.detail))
			continue
		}

		switch o {
		case outWarning:
			lines = append(lines, style.Alert.Render(fmt.Sprintf(
				"%s: installazione %s non riuscita", ph.recap, quotedList(ph.failed))))
		case outError:
			if len(ph.items) > 0 {
				lines = append(lines, style.Error.Render(fmt.Sprintf(
					"%s: installazione %s non riuscita", ph.recap, quotedList(ph.failed))))
			} else {
				noun := "installazione"
				if ph.config {
					noun = "configurazione"
				}
				lines = append(lines, style.Error.Render(fmt.Sprintf(
					"%s: %s non riuscita", ph.recap, noun)))
			}
		}
	}
	return strings.Join(lines, "\n")
}

// quotedList formatta gli elementi tra apici, separati da virgola: 'A', 'B'.
func quotedList(items []string) string {
	q := make([]string, len(items))
	for i, it := range items {
		q[i] = "'" + it + "'"
	}
	return strings.Join(q, ", ")
}

// outcomeMarker: simbolo e colore dell'esito.
func outcomeMarker(o instOutcome) (string, lipgloss.Color) {
	switch o {
	case outWarning:
		return style.SymWarning, style.Cheddar
	case outError:
		return style.SymError, style.Coral
	default:
		return style.SymSuccess, style.Aquamarine
	}
}

// outcomeText: la dicitura di esito mostrata nella tabella finale. Le fasi di
// configurazione (terminale, aggiornamenti) usano "Configurazione …".
func outcomeText(o instOutcome, config bool) string {
	noun := "Installazione"
	if config {
		noun = "Configurazione"
	}
	switch o {
	case outWarning:
		return noun + " completata con avvisi"
	case outError:
		if config {
			return "Impossibile completare la configurazione"
		}
		return "Impossibile completare l'installazione"
	default:
		return noun + " completata"
	}
}

// markerCell rende un simbolo largo 2 celle, così i marcatori a carattere singolo
// (✓ ○ ▲ ✗) restano allineati con lo spinner (emoji largo 2).
func markerCell(sym string, col lipgloss.Color) string {
	return lipgloss.NewStyle().Foreground(col).Width(2).Render(sym)
}
