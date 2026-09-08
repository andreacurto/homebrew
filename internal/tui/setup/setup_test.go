package setup

import (
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/brew"
	"github.com/andreacurto/donkey/internal/catalog"
	"github.com/andreacurto/donkey/internal/state"
	"github.com/andreacurto/donkey/internal/tui/style"
)

func TestWelcomeView(t *testing.T) {
	v := New().View()
	if !strings.Contains(v, "Donkey") || !strings.Contains(v, style.RepoURL) {
		t.Error("la welcome view non contiene brand/URL del repo")
	}
}

func TestCatalogMsgLoadsApps(t *testing.T) {
	m := New()
	m.step = stepApps
	m.apps.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Apps, entries: []catalog.Entry{{Label: "Figma", Value: "figma"}}})
	mm := updated.(Model)

	if mm.apps.loading || !mm.apps.loaded {
		t.Fatal("dopo catalogMsg lo stato delle app dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Figma") {
		t.Error("la view App non mostra l'app caricata")
	}
}

func TestCatalogMsgLoadsFonts(t *testing.T) {
	m := New()
	m.step = stepFonts
	m.fonts.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Fonts, entries: []catalog.Entry{{Label: "Fira Code", Value: "font-fira-code-nerd-font"}}})
	mm := updated.(Model)

	if mm.fonts.loading || !mm.fonts.loaded {
		t.Fatal("dopo catalogMsg lo stato dei font dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "Fira Code") {
		t.Error("la view Font non mostra il font caricato")
	}
}

func TestCatalogMsgLoadsThemes(t *testing.T) {
	m := New()
	m.step = stepTheme
	m.theme.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Themes, entries: []catalog.Entry{{Label: "Atomic", Value: "atomic"}}})
	mm := updated.(Model)

	if mm.theme.loading || !mm.theme.loaded {
		t.Fatal("dopo catalogMsg lo stato del tema dovrebbe essere caricato")
	}
	v := mm.View()
	if !strings.Contains(v, "Atomic") || !strings.Contains(v, "Nessun tema") {
		t.Error("la view Tema deve mostrare il tema caricato e la voce 'Nessun tema'")
	}
	if mm.theme.selectionLabel() != "Nessun tema" {
		t.Errorf("default = %q, atteso 'Nessun tema' (prima voce)", mm.theme.selectionLabel())
	}
}

func TestCatalogMsgLoadsTools(t *testing.T) {
	m := New()
	m.step = stepTools
	m.tools.loading = true

	updated, _ := m.Update(catalogMsg{target: catalog.Tools, entries: []catalog.Entry{{Label: "GitHub CLI", Value: "gh"}}})
	mm := updated.(Model)

	if mm.tools.loading || !mm.tools.loaded {
		t.Fatal("dopo catalogMsg lo stato degli strumenti dovrebbe essere caricato")
	}
	if !strings.Contains(mm.View(), "GitHub CLI") {
		t.Error("la view Strumenti non mostra lo strumento caricato")
	}
	if len(mm.tools.chosenLabels()) != 0 {
		t.Error("nessuno strumento deve essere preselezionato")
	}
}

func TestAutoToggle(t *testing.T) {
	m := New()
	if !m.auto {
		t.Fatal("l'aggiornamento automatico dovrebbe essere attivo di default")
	}
	m.step = stepAuto
	updated, _ := m.Update(tea.KeyMsg{Type: tea.KeySpace})
	if updated.(Model).auto {
		t.Error("dopo Seleziona l'aggiornamento automatico dovrebbe essere disattivato")
	}
}

// driveInstall porta l'installazione a termine: esegue il comando delle fasi
// reali e salta il timer di quelle simulate, così il test non paga i ritardi.
func driveInstall(t *testing.T, m Model) Model {
	t.Helper()

	for i := 0; i < 100 && !m.inst.done; i++ {
		var msg tea.Msg = installStepMsg{}
		if m.inst.realNow() {
			msg = m.inst.next()() // esegue il comando e ne raccoglie l'esito
		}
		updated, _ := m.Update(msg)
		m = updated.(Model)
	}
	if !m.inst.done {
		t.Fatal("l'installazione non si è conclusa entro il limite di passi")
	}
	return m
}

func TestInstallRunsToDoneWithRealCore(t *testing.T) {
	// Core già presente: nessun comando d'installazione, nessuna scrittura.
	m := NewWith(Deps{
		Brew:  brew.New(&coreRunner{present: true}),
		Store: state.New(t.TempDir()),
	})
	m.step = stepInstall
	m.inst = newInstaller(m) // core + Configurazione terminale + Auto-update (default)

	// La schermata di avanzamento mostra le fasi base (mai "Homebrew": è tutto Donkey).
	v := m.View()
	if strings.Contains(v, "Homebrew") {
		t.Error("la view Installazione non deve citare Homebrew")
	}
	if !strings.Contains(v, "Installazione Donkey") || !strings.Contains(v, "Configurazione terminale") {
		t.Error("la view Installazione non elenca le fasi base")
	}
	if m.inst.done {
		t.Fatal("l'installazione non dovrebbe essere già conclusa")
	}

	mm := driveInstall(t, m)

	done := mm.View()
	if !strings.Contains(done, "Installazione completata") {
		t.Error("la schermata finale non mostra il riepilogo di completamento")
	}
	if !strings.Contains(done, "Già presente") {
		t.Error("con il core già presente la tabella deve dirlo, non fingere un'installazione")
	}
	if strings.Contains(done, "Homebrew") {
		t.Error("la schermata finale non deve citare Homebrew")
	}

	// A installazione conclusa, Invio chiude il wizard.
	_, cmd := mm.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if cmd == nil {
		t.Error("Invio sulla schermata 'Fatto' dovrebbe uscire dal wizard")
	}
}

func TestInstallFailedCoreNeverNamesHomebrew(t *testing.T) {
	// Il core non si installa: l'errore va mostrato, ma senza nominarlo.
	m := NewWith(Deps{
		Brew:  brew.New(&coreRunner{installFails: true, output: "Error: Homebrew install failed"}),
		Store: state.New(t.TempDir()),
	})
	m.step = stepInstall
	m.inst = newInstaller(m)

	mm := driveInstall(t, m)

	done := mm.View()
	if !strings.Contains(done, "Impossibile completare l'installazione") {
		t.Errorf("la schermata finale non riporta il fallimento del core:\n%s", done)
	}
	if strings.Contains(strings.ToLower(done), "brew") {
		t.Errorf("la schermata finale cita il core per nome:\n%s", done)
	}
}

func TestInstallerOutcomeAndDetails(t *testing.T) {
	in := installer{phases: []instPhase{
		{recap: "App", items: []string{"1Password", "Spotify"}},                                     // tutto ok
		{recap: "Font terminale", items: []string{"Fira Code", "Meslo"}, failed: []string{"Meslo"}}, // parziale → avviso
		{recap: "Strumenti terminale", items: []string{"gh"}, failed: []string{"gh"}},               // tutta fallita → errore
		{recap: "Terminale"}, // fase singola ok
	}}

	if got := in.phases[0].outcome(); got != outSuccess {
		t.Errorf("App: esito = %d, atteso success", got)
	}
	if got := in.phases[1].outcome(); got != outWarning {
		t.Errorf("Font: esito = %d, atteso warning", got)
	}
	if got := in.phases[2].outcome(); got != outError {
		t.Errorf("Strumenti: esito = %d, atteso error", got)
	}

	det := in.recapDetails()
	if !strings.Contains(det, "Meslo") {
		t.Error("il dettaglio deve nominare il font non installato (Meslo)")
	}
	if !strings.Contains(det, "gh") {
		t.Error("il dettaglio deve nominare lo strumento non installato (gh)")
	}

	table := in.recapTable()
	if !strings.Contains(table, "Installazione completata con avvisi") {
		t.Error("la tabella deve riportare l'esito con avvisi per i font")
	}
	if !strings.Contains(table, "Impossibile completare l'installazione") {
		t.Error("la tabella deve riportare l'esito di errore per gli strumenti")
	}
}

func TestPickerToggle(t *testing.T) {
	p := newPicker(catalog.Apps, "App", "x", "", false)
	p.setResult([]catalog.Entry{{Label: "A", Value: "a"}, {Label: "B", Value: "b"}}, nil)

	if p.selectedCount() != 0 {
		t.Fatalf("conteggio iniziale = %d, atteso 0", p.selectedCount())
	}
	p.update(tea.KeyMsg{Type: tea.KeySpace}) // seleziona la voce sotto il cursore (A)
	if p.selectedCount() != 1 {
		t.Fatalf("dopo il toggle = %d, atteso 1", p.selectedCount())
	}
	p.update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("a")}) // seleziona tutte
	if p.selectedCount() != 2 {
		t.Fatalf("dopo 'seleziona tutto' = %d, atteso 2", p.selectedCount())
	}
}

// --- meccanismo delle fasi reali -------------------------------------------

// realPhase costruisce una fase reale che restituisce subito l'esito dato.
func realPhase(name string, res phaseResult) instPhase {
	return instPhase{
		name: name, recap: name,
		run: func(i int) tea.Cmd {
			return func() tea.Msg { return installPhaseDoneMsg{index: i, res: res} }
		},
	}
}

func TestInstallIgnoresStalePhaseMessage(t *testing.T) {
	m := New()
	m.step = stepInstall
	m.inst = installer{phases: []instPhase{
		realPhase("Prima", phaseResult{outcome: outSuccess}),
		realPhase("Seconda", phaseResult{outcome: outSuccess}),
	}}

	// Un esito riferito a una fase che non è quella corrente è in ritardo.
	updated, _ := m.Update(installPhaseDoneMsg{index: 99, res: phaseResult{}})
	if got := updated.(Model).inst.pi; got != 0 {
		t.Errorf("un messaggio in ritardo ha fatto avanzare l'installer a %d", got)
	}
	if updated.(Model).inst.done {
		t.Error("un messaggio in ritardo non deve concludere l'installazione")
	}
}

func TestInstallIgnoresStepMessageDuringRealPhase(t *testing.T) {
	m := New()
	m.step = stepInstall
	m.inst = installer{phases: []instPhase{
		realPhase("Reale", phaseResult{outcome: outSuccess}),
		{name: "Simulata", recap: "Simulata", ticks: 2, delay: time.Millisecond},
	}}

	// Il tick della simulazione non compete alla fase reale in corso.
	updated, _ := m.Update(installStepMsg{})
	mm := updated.(Model)
	if mm.inst.pi != 0 || mm.inst.prog != 0 {
		t.Errorf("un tick simulato ha mosso una fase reale: pi=%d prog=%d", mm.inst.pi, mm.inst.prog)
	}

	// L'esito della fase reale invece la chiude tutta insieme.
	updated, _ = mm.Update(installPhaseDoneMsg{index: 0, res: phaseResult{outcome: outSuccess}})
	if got := updated.(Model).inst.pi; got != 1 {
		t.Errorf("dopo l'esito reale la fase corrente = %d, attesa 1", got)
	}
}

func TestPhaseResultOverridesDeducedOutcome(t *testing.T) {
	// Una fase singola con elementi falliti verrebbe dedotta come errore: l'esito
	// dichiarato dal comando deve vincere, con la sua dicitura e il suo dettaglio.
	in := installer{phases: []instPhase{{
		recap:  "Donkey core",
		failed: []string{"Donkey core"},
		res: &phaseResult{
			outcome: outWarning,
			failed:  []string{"Donkey core"},
			text:    "Installazione completata, registro non aggiornato",
			detail:  "Donkey core: installato, ma il registro locale non è stato aggiornato",
		},
	}}}

	if got := in.phases[0].outcome(); got != outWarning {
		t.Errorf("esito = %d, atteso warning: l'esito reale deve vincere sulla deduzione", got)
	}
	if table := in.recapTable(); !strings.Contains(table, "registro non aggiornato") {
		t.Errorf("la tabella deve usare la dicitura della fase reale:\n%s", table)
	}
	det := in.recapDetails()
	if !strings.Contains(det, "il registro locale non è stato aggiornato") {
		t.Errorf("il dettaglio deve essere quello della fase reale:\n%s", det)
	}
	if strings.Contains(det, "''") {
		t.Errorf("il dettaglio non deve stampare un elenco vuoto:\n%s", det)
	}
}

func TestDryRunBadge(t *testing.T) {
	const badge = "Modalità prova"

	// In modalità prova l'avviso compare ovunque si parli di installazione.
	m := NewWith(Deps{Brew: brew.NewDry(true), Store: state.New(t.TempDir())})
	m.step = stepSummary
	if v := m.summaryView(); !strings.Contains(v, badge) {
		t.Error("il riepilogo non avvisa che è una prova")
	}

	m.step = stepInstall
	m.inst = newInstaller(m)
	if v := m.installView(); !strings.Contains(v, badge) {
		t.Error("la schermata di installazione non avvisa che è una prova")
	}

	mm := driveInstall(t, m)
	if v := mm.View(); !strings.Contains(v, badge) {
		t.Error("la schermata finale non avvisa che è una prova: il riepilogo verrebbe preso per buono")
	}

	// Con i comandi reali l'avviso non deve comparire da nessuna parte.
	r := NewWith(Deps{Brew: brew.New(&coreRunner{present: true}), Store: state.New(t.TempDir())})
	r.step = stepInstall
	r.inst = newInstaller(r)
	rr := driveInstall(t, r)
	if v := rr.summaryView() + rr.View(); strings.Contains(v, badge) {
		t.Error("fuori dalla modalità prova l'avviso non deve comparire")
	}
}
