package setup

import (
	"errors"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/andreacurto/donkey/internal/state"
)

// coreRecap è l'etichetta breve della fase core nella tabella finale. Per
// l'utente il core è Donkey: il nome del gestore di pacchetti sottostante non
// compare mai a schermo (AGENTS, regola 1).
const coreRecap = "Donkey core"

// errNoStore: il registro non è raggiungibile (cartella home illeggibile).
var errNoStore = errors.New("registro locale non disponibile")

// runCore avvolge installCore in un comando Bubble Tea. Il comando gira in una
// goroutine, quindi l'interfaccia resta viva e lo spinner continua a girare
// mentre l'installazione procede.
func runCore(d Deps, index int) tea.Cmd {
	return func() tea.Msg {
		return installPhaseDoneMsg{index: index, res: installCore(d)}
	}
}

// installCore installa il core se manca e ne annota l'aggiunta nel registro.
// È logica pura, senza Bubble Tea: si collauda da sola con un esecutore finto.
//
// L'ordine conta:
//  1. se il core c'è già non si tocca nulla, e soprattutto non si annota nulla —
//     annotarlo significherebbe, un domani, disinstallare il core di qualcun
//     altro (PRODUCT §5: si registra solo ciò che Donkey aggiunge);
//  2. dopo l'installazione si ri-verifica. Lo script ufficiale può concludersi
//     senza errori e lasciare comunque un core non raggiungibile: è questa
//     seconda verifica a distinguere "lo script è girato" da "il core funziona".
func installCore(d Deps) phaseResult {
	failed := []string{coreRecap}

	if d.Brew == nil {
		return phaseResult{outcome: outError, failed: failed}
	}

	if d.Brew.Present() {
		return phaseResult{outcome: outSuccess, text: "Già presente, nessuna modifica"}
	}

	if r := d.Brew.InstallHomebrew(); !r.Ok() {
		return phaseResult{outcome: outError, failed: failed, log: r.Output}
	}

	if !d.Brew.Present() {
		return phaseResult{outcome: outError, failed: failed}
	}

	if err := markCoreInstalled(d.Store); err != nil {
		return phaseResult{
			outcome: outWarning,
			text:    "Installazione completata, registro non aggiornato",
			detail:  coreRecap + ": installato, ma il registro locale non è stato aggiornato",
		}
	}

	return phaseResult{outcome: outSuccess}
}

// markCoreInstalled annota nel registro che è stato Donkey a installare il core:
// serve alla disinstallazione a residuo zero per sapere cosa può rimuovere.
func markCoreInstalled(s *state.Store) error {
	if s == nil {
		return errNoStore
	}
	m, err := s.Load()
	if err != nil {
		return err
	}
	m.HomebrewByDonkey = true
	return s.Save(m)
}
