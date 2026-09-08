# Donkey — Sviluppo

Com'è fatto il codice e come ci si lavora. È il documento da aprire quando si scrive codice.

- Cosa deve fare Donkey per l'utente → [`PRODUCT.md`](PRODUCT.md)
- Come si presenta l'interfaccia → [`STYLEGUIDE.md`](STYLEGUIDE.md)
- Rami, commit, merge → [`WORKFLOW.md`](WORKFLOW.md)
- Cosa è reale e cosa è ancora simulato → [`MIGRATION.md`](MIGRATION.md)

**Stack**: Go (Bubble Tea) per interfaccia e orchestrazione, Homebrew per il lavoro sul sistema.

---

## Mappa del codice

```
main.go                        entry point: instrada a sottocomando o menù
internal/
├── catalog/catalog.go         scarica e parsa i cataloghi (nessuna cache)
├── brew/brew.go               wrapper su Homebrew + modalità prova
├── state/state.go             registro ~/.donkey/
└── tui/
    ├── style/style.go         palette, simboli, header, footer — unica fonte del look
    ├── menu/menu.go           menù principale (le voci sono segnaposto)
    └── setup/
        ├── setup.go           wizard: modello, gestione tasti, schermate
        ├── picker.go          schermata di selezione su un catalogo
        ├── delegate.go        disegno di una riga di lista (checkbox/radio)
        ├── summary.go         riepilogo pre-installazione
        ├── install.go         checklist di installazione + esiti
        └── core.go            fase reale: installa Donkey core e lo annota
config/*.list                  cataloghi: apps, tools, fonts, themes
scripts/gen-catalog.py         rigenera fonts.list e themes.list
```

Previsti da [`PRODUCT.md`](PRODUCT.md) ma **non ancora esistenti**: `internal/system/`, le viste
`tui/app|terminal|update|autoupdate|status/`, `install.sh`.

---

## Regole di architettura

- **Go orchestra, Homebrew esegue.** La TUI non lancia `brew` sparso: passa da `internal/brew/`.
- **Un file, una responsabilità.** Niente monoliti.
- **Stile centralizzato** in `internal/tui/style/`: cambiare lì si propaga ovunque. Colori e simboli
  non si scrivono mai a mano altrove.
- **Logica separata dall'interfaccia**, così è testabile senza un terminale vero.

### Come è fatta una schermata (Bubble Tea)

Ogni schermata è un *modello* con tre metodi: `Init` (comandi iniziali), `Update` (reagisce a
messaggi: tasti, timer, risultati) e `View` (produce il testo). Non si stampa mai direttamente a
schermo: `View` restituisce una stringa e il framework la disegna.

---

## I cataloghi

Le liste in `config/*.list` sono l'unica fonte di verità e **vivono solo nel repo**: il binario non
le incorpora e non le mette in cache, le scarica quando servono. Il perché sta in
[`PRODUCT.md`](PRODUCT.md); qui il come.

Formato di ogni riga: `Etichetta|valore|descrizione` (descrizione opzionale; righe vuote e `#`
ignorate). L'`Etichetta` è ciò che vede l'utente, il `valore` è il nome del pacchetto Homebrew.

⚠️ L'indirizzo di download predefinito punta a un repository che oggi **non esiste** (vedi
[`TODO.md`](TODO.md)). In sviluppo non è un problema: `make run-setup` legge i cataloghi dalla
cartella locale.

---

## Comandi

| Comando | Cosa fa |
|---|---|
| `make build` | Compila il binario in `bin/dk` |
| `make run` | Avvia il menù principale |
| `make run-setup` | Avvia il wizard **usando i cataloghi locali** — è il comando da usare per provare |
| `make run-dry` | Come sopra ma in **modalità prova**: flusso reale, nessun comando eseguito. Aggiungi `DONKEY_DRY_RUN=present` per un Mac che ha già il core |
| `make test` | Esegue i test |
| `make lint` | `gofmt -l .` + `go vet ./...` |
| `make tidy` | Sistema le dipendenze |
| `make update-fonts` / `update-themes` | Rigenera i cataloghi font/temi |
| `make clean` | Rimuove gli artefatti di build (`bin/`) |

### Variabili d'ambiente

| Variabile | Effetto |
|---|---|
| `DONKEY_CATALOG_URL` | Sorgente dei cataloghi: un URL oppure un percorso locale |
| `DONKEY_HOME` | Cartella del registro (default `~/.donkey`) — utile nei test e per isolare le prove |
| `DONKEY_DRY_RUN` | **Modalità prova**: `1`/`true`/`on` immagina un Mac senza il core, `present` uno che ce l'ha già. Qualsiasi altro valore (o assente) = comandi reali |

---

## Test

- Si eseguono con `make test`; devono essere **verdi prima di ogni commit**, insieme a `make lint`.
- La logica (cataloghi, Homebrew, registro) si testa in isolamento. Per Homebrew si inietta un
  esecutore finto, quindi **i test non installano mai nulla davvero**.
- Anche il wizard si testa così: `setup.NewWith(setup.Deps{...})` accetta un client Homebrew e un
  registro espliciti. `setup.New()` costruisce quelli reali ed è riservato a `main.go`.
- L'interfaccia si testa "senza schermo": si costruisce il modello, si chiama `View()` e si
  verificano i testi, guidando le transizioni con messaggi passati a `Update()`.
- Per *vedere* l'app serve un terminale vero: `make run-setup`.
- Per un'anteprima usa e getta di una schermata, va bene un file `zz_tmp_*_test.go` che stampa
  `View()` — **da cancellare subito dopo**, non va committato.

---

## Convenzioni di codice

- **Commenti**: spiegano *perché*, non *cosa*. Densità come il codice circostante.
- **Dipendenze**: oggi solo `bubbletea`, `bubbles`, `lipgloss`. Non se ne aggiungono senza un motivo
  forte.
- **Lingua**: identificatori, nomi di file e di pacchetti in inglese; commenti e testi a schermo in
  italiano.
