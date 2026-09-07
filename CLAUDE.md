# Donkey — Documentazione tecnica

Guida **tecnica** al progetto: com'è fatto il codice e come ci si lavora.

| Documento | Cosa contiene |
|---|---|
| `AGENTS.md` | **Fonte di verità di prodotto**: cosa è Donkey, per chi, come si comporta |
| `CLAUDE.md` (questo file) | Come è fatto il codice e come ci si sviluppa |
| `WORKFLOW.md` | Regole di gestione del repository: rami, commit, rilasci |
| `TODO.md` | Cose emerse e volutamente rimandate, con il motivo |

---

## ⚠️ Stato del progetto — leggere prima di toccare qualsiasi cosa

Il progetto sta migrando da **1.x (bash + gum)** a **2.0 (Go + Bubble Tea)**. È la stessa
repository, quindi convivono cose di entrambe le epoche.

- **`main`** — la 1.x stabile pubblicata (`setup.sh`, `update.sh`). Non ci si sviluppa.
- **`develop`** — Donkey 2.0 in Go. **È qui che si lavora.**
- Nel ramo di sviluppo sono ancora presenti `setup.sh` e `update.sh` della 1.x: sono **residui**.
  Non vanno usati, modificati, né presi a modello. La loro rimozione è tracciata in `TODO.md`.

**Il contenuto precedente di questo file — gum, `SCRIPT_VERSION`, rilascio con tag a ogni modifica —
si riferiva alla 1.x e non vale più.** Se trovi istruzioni che parlano di `gum`, di `setup.sh` come
file da modificare o di bumpare `SCRIPT_VERSION`, sono obsolete.

Regola pratica: **la 2.0 non nomina mai `SCRIPT_VERSION`**. La versione vive in `main.go`
(`const version`), oggi `2.0.0-dev`, e **non si creano tag** fino alla v2.0.0.

---

## Cos'è Donkey 2.0

Un'app da terminale (TUI) che allestisce un Mac e lo tiene aggiornato: menù a schermo intero,
wizard di onboarding, cataloghi di app/strumenti/font/temi scaricati live dal repo.

- Comando: `donkey`, con scorciatoia `dk`.
- Stack: **Go** per interfaccia e orchestrazione, **Homebrew** per il lavoro sul sistema.

### Regola di prodotto non negoziabile

**Homebrew non va MAI nominato nell'interfaccia.** Per l'utente è tutto "Donkey": la fase che
installa Homebrew si chiama "Installazione Donkey core". Vale per ogni testo a schermo.

---

## Architettura

### Mappa del codice — stato reale

```
main.go                        entry point: instrada a sottocomando o menù
internal/
├── catalog/catalog.go         scarica e parsa i cataloghi (nessuna cache)
├── brew/brew.go               wrapper su Homebrew (NON ancora usato da nessuno)
├── state/state.go             registro ~/.donkey/ (NON ancora usato da nessuno)
└── tui/
    ├── style/style.go         palette, simboli, header, footer — unica fonte del look
    ├── menu/menu.go           menù principale (le voci sono segnaposto)
    └── setup/
        ├── setup.go           wizard: modello, gestione tasti, schermate
        ├── picker.go          schermata di selezione su un catalogo
        ├── delegate.go        disegno di una riga di lista (checkbox/radio)
        ├── summary.go         riepilogo pre-installazione
        └── install.go         checklist di installazione + esiti (OGGI SIMULATO)
config/*.list                  cataloghi: apps, tools, fonts, themes
scripts/gen-catalog.py         rigenera fonts.list e themes.list
```

Previsti da `AGENTS.md` ma **non ancora esistenti**: `internal/system/`, le viste
`tui/app|terminal|update|autoupdate|status/`, `install.sh`.

### Regole di architettura

- **Go orchestra, Homebrew esegue.** La TUI non lancia `brew` sparso: passa da `internal/brew/`.
- **Un file, una responsabilità.** Niente monoliti.
- **Stile centralizzato** in `internal/tui/style/`: cambiare lì si propaga ovunque.
- **Logica separata dall'interfaccia**, così è testabile senza un terminale vero.

### Come è fatta una schermata (Bubble Tea)

Ogni schermata è un *modello* con tre metodi: `Init` (comandi iniziali), `Update` (reagisce a
messaggi: tasti, timer, risultati) e `View` (produce il testo). Non si stampa mai direttamente a
schermo: `View` restituisce una stringa e il framework la disegna.

### I cataloghi

Le liste in `config/*.list` sono l'unica fonte di verità e **vivono solo nel repo**: il binario non
le incorpora e non le mette in cache, le scarica quando servono. Così il catalogo si aggiorna
editando il repo, senza rilasciare un nuovo binario.

Formato di ogni riga: `Etichetta|valore|descrizione` (descrizione opzionale; righe vuote e `#`
ignorate). L'`Etichetta` è ciò che vede l'utente, il `valore` è il nome del pacchetto Homebrew.

⚠️ L'indirizzo di download predefinito punta a un repository e a un ramo **che oggi non esistono**
(vedi `TODO.md`). In sviluppo non è un problema: `make run-setup` legge i cataloghi dalla cartella
locale.

---

## Stato di avanzamento — cosa è reale e cosa no

Questa sezione va tenuta aggiornata: è la prima cosa che serve sapere.

| Parte | Stato |
|---|---|
| Menù principale (`dk`) | Navigabile, ma tutte e 5 le voci mostrano un segnaposto |
| Wizard (`dk setup`) | **Interfaccia completa** e rifinita, da benvenuto a riepilogo finale |
| Installazione vera | ❌ **Interamente simulata** |
| `internal/brew`, `internal/state` | Scritti e testati, ma **non ancora usati da nessuno** |

**Come è fatta la simulazione:** `install.go` fa avanzare la checklist con un timer
(`tea.Tick`) e ritardi inventati. Gli esiti ✓/▲/✗ vengono dalle costanti `simulateFontWarning` e
`simulateToolsError`. **Nessun comando reale viene eseguito**: il Mac non viene toccato.

Il prossimo blocco di lavoro è collegare i comandi veri, partendo dal solo Homebrew.

---

## Comandi di sviluppo

| Comando | Cosa fa |
|---|---|
| `make build` | Compila il binario in `bin/dk` |
| `make run` | Avvia il menù principale |
| `make run-setup` | Avvia il wizard **usando i cataloghi locali** — è il comando da usare per provare |
| `make test` | Esegue i test |
| `make lint` | `gofmt -l .` + `go vet ./...` |
| `make tidy` | Sistema le dipendenze |
| `make update-fonts` / `update-themes` | Rigenera i cataloghi font/temi |

### Variabili d'ambiente

| Variabile | Effetto |
|---|---|
| `DONKEY_CATALOG_URL` | Sorgente dei cataloghi: un URL oppure un percorso locale |
| `DONKEY_HOME` | Cartella del registro (default `~/.donkey`) — utile nei test |

---

## Test

- Si eseguono con `make test`; devono essere **verdi prima di ogni commit**, insieme a `make lint`.
- La logica (cataloghi, Homebrew, registro) si testa in isolamento. Per Homebrew si inietta un
  esecutore finto, quindi **i test non installano mai nulla davvero**.
- L'interfaccia si testa "senza schermo": si costruisce il modello, si chiama `View()` e si
  verificano i testi, guidando le transizioni con messaggi passati a `Update()`.
- Per *vedere* l'app serve un terminale vero: `make run-setup`.
- Per un'anteprima usa e getta di una schermata, va bene un file `zz_tmp_*_test.go` che stampa
  `View()` — **da cancellare subito dopo**, non va committato.

---

## Convenzioni

- **Lingua: italiano** per commenti, testi dell'interfaccia e messaggi di commit.
- **Commenti**: spiegano *perché*, non *cosa*. Densità come il codice circostante.
- **Commit**: [Conventional Commits](https://www.conventionalcommits.org/) con prefisso maiuscolo —
  `Feat`, `Fix`, `Style`, `Refactor`, `Docs`, `Chore`. Prima riga ~70 caratteri, minuscola dopo i
  due punti.
- **Niente dipendenze nuove** senza motivo forte: oggi sono solo `bubbletea`, `bubbles`, `lipgloss`.

---

## Stile dell'interfaccia

Tutto lo stile vive in `internal/tui/style/style.go`. **Non scrivere colori a mano altrove.**

| Nome | Ruolo |
|---|---|
| `Cream` | Testo di base |
| `Ash` | Testi secondari, elementi in attesa |
| `Coral` | Brand "Donkey", elemento selezionato, errori |
| `Cheddar` | Slogan, avvisi |
| `Aquamarine` | Comandi e riusciti |

Simboli: cursore `❖` · successo `✓` · errore `✗` · avviso `▲` · info `◆` · checkbox `■`/`□` ·
acceso/spento `●`/`○`.

Principi: schermo intero e layout stabile; tastiera-first con footer sempre visibile; da ogni
schermata si torna indietro; nessuna installazione parte senza un riepilogo confermabile; spinner
scimmietta 🙈🙉🙊🐵 durante le attese. Il dettaglio completo è nella styleguide di `AGENTS.md`.

---

## Gestione del repository

Rami, commit e rilasci seguono **`WORKFLOW.md`**. Le regole da non violare mai:

1. Si sviluppa su rami dedicati che partono da **`develop`**, mai direttamente su `develop` o `main`.
2. **Nessun tag** finché non si arriva alla v2.0.0.
3. Niente merge verso `main` senza approvazione esplicita.
