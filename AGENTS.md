# Donkey — Manifesto

Donkey è un'app da terminale che **allestisce un Mac e lo tiene aggiornato da solo**: un menù a schermo intero navigabile, viste curate, azioni anteprimabili. Questo documento è la fonte di verità su *cosa è Donkey, per chi, e come si comporta* — ed è la guida per chi ci sviluppa.

- **Comando**: `donkey`, alias breve **`dk`** (entrambi validi; `dk` è il lancio quotidiano).
- **Stack**: ibrido **Go** (TUI) + **shell** (azioni di sistema).

---

## 1. Direzione di prodotto

### Missione
**Un solo comando per avere il tuo Mac pronto e mantenerlo fresco senza pensarci.**
Donkey installa Homebrew e gli strumenti base, mette le **app che scegli**, **personalizza il terminale** (shell, tema, suggerimenti) e — se lo decidi al setup — tiene **tutto aggiornato in automatico in background**, per sempre.

### Per chi è (personas)
Utenti di **medio livello che amano il terminale**: sanno aprire una shell e muoversi tra i menù, ma non vogliono ricordarsi *quali* app installare, *come* configurare zsh o *quando* aggiornare. Donkey toglie loro questo carico.

### Il problema che risolve
Allestire un Mac (nuovo o resettato) è **tedioso, manuale e dimenticabile**. Donkey lo rende **un'unica esperienza guidata, bella e ripetibile**, e poi sparisce nello sfondo.

### Cosa fa Donkey (i pilastri)
1. **Provisioning** — installa Homebrew + strumenti + le app/font che scegli, in un flusso guidato.
2. **Personalizzazione terminale** — shell zsh, tema (Oh My Posh), suggerimenti *fish-like* (`zsh-autosuggestions`); modificabili in ogni momento.
3. **Set-and-forget** — configura l'auto-aggiornamento di Homebrew in background (opt-in) e non ci pensi più.
4. **Catalogo di app curato** — una selezione pronta di app installabili/disinstallabili con un gesto: come un **Homebrew semplificato**. Il catalogo vive nel repo ed è **sempre aggiornato** (vedi §3).
5. **Visibilità** — una vista di stato che dice a colpo d'occhio cosa è installato, cosa è da aggiornare, se l'auto-update è attivo.
6. **Manutenzione on-demand** — quando vuoi, aggiorni/pulisci/diagnostichi a mano.

### Cosa Donkey NON fa (confini)
- **Non è Mole.** Niente pulizia profonda del sistema, niente uninstall di app fuori dal suo catalogo, niente analisi disco o salute hardware. Se serve, Donkey **installa Mole** e gli lascia quel mestiere.
- **Non gestisce pacchetti oltre Homebrew**.
- **Nessun agente proprio in background**: l'auto-update gira su `launchd` via `homebrew-autoupdate`.
- **Niente modifiche di sistema invasive** non reversibili. E **all'uninstall non lascia residui** (vedi §5).

### Filtro per le decisioni di prodotto
Prima di aggiungere qualcosa, deve passare **tutti e tre**:
1. Serve a **mettere in piedi** un Mac o a **tenerlo aggiornato**?
2. È qualcosa che un utente medio-terminale **non vuole ricordarsi/fare a mano**?
3. **Non** è già il mestiere di Mole o di un altro tool dedicato?

---

## 2. Esperienza (schermata per schermata)

### Principi di UX
- **Terminal-native e calmo**: schermo intero, layout stabile, allineamenti curati, colori coerenti (Lipgloss). Un'estetica, non una somma di `echo`.
- **Tastiera-first**: `↑↓`/`j k`, `Spazio` per selezionare, `Invio` per confermare, `Esc`/`q` per indietro. Footer sempre visibile coi tasti.
- **Mai un vicolo cieco**: da ogni schermata si torna indietro. Niente flusso lineare rigido.
- **Anteprima prima di agire**: nessuna installazione/rimozione parte senza un **riepilogo** confermabile.
- **Segnale non rumore**: il log verboso di brew resta dietro le quinte; ma **errori** e output utile (es. `brew doctor` con warning e comandi suggeriti) vengono mostrati in un **pannello scrollabile leggibile**, coi suggerimenti copiabili.
- **Errori con dignità**: i fallimenti (es. rete assente dove serve) sono schermate curate, non crash o testo grezzo.

### 2.1 — Installazione & primo avvio (onboarding)
L'utente **non clona nulla**. Installa con un comando, due canali (come Mole):
- `brew install andreacurto/donkey/donkey` — se ha già Homebrew.
- `curl -fsSL …/install.sh | bash` — Mac fresco: installa Homebrew **e** Donkey.

Al **primo avvio** parte automaticamente il **Setup** (onboarding), un wizard navigabile, una schermata per passo:

| # | Schermata | Cosa fa |
|---|-----------|---------|
| S1 | **Benvenuto** | Spiega in 3 righe cosa accadrà. `Continua` / `Esci`. |
| S2 | **App** | Catalogo multi-selezione con descrizioni (scaricato live, §3). `Spazio` per (de)selezionare. |
| S3 | **Font** | Multi-selezione font (Nerd Font per i temi). |
| S4 | **Terminale** | Tema (anteprima) + toggle **suggerimenti** (`zsh-autosuggestions`) — è una scelta, non forzato. |
| S5 | **Auto-update** | Toggle "tieni tutto aggiornato da solo"; se sì → intervallo + opzioni. |
| S6 | **Riepilogo** | "Ecco cosa farò": elenco del selezionato. `Conferma e installa` / `Indietro`. |
| S7 | **Installazione** | Avanzamento live, raggruppato (Homebrew · strumenti · app · font · terminale · auto-update). |
| S8 | **Fatto** | Esito + prossimi passi. |

Il Setup **non è una voce del menù** `dk`: resta come comando `dk setup` (lo usa l'installer) e il primo avvio lo propone se il Mac non è configurato. La configurazione del terminale viene **appesa** al `~/.zshrc` in un blocco delimitato — Donkey non sovrascrive mai un `.zshrc` esistente (vedi §5).

### 2.2 — `dk` (menù principale, di gestione)
```
[ logo ASCII: Donkey ]              github.com/andreacurto/donkey
                                    Allestisci il tuo Mac. Tienilo fresco.

 ▸ 1. App          Installa o disinstalla singole app
   2. Terminal     Tema, font e autocompletamento
   3. Update       Aggiorna e fai ordine in Homebrew
   4. Auto-update  Gestisci l'aggiornamento automatico
   5. Status       Lo stato del tuo Mac a colpo d'occhio

   ↑↓ · Invio · U Disinstalla · V Versione · Q Esci
```
I sottocomandi (`dk app`, `dk terminal`, `dk update`, `dk autoupdate`, `dk status`) saltano dritti al flusso.

### 2.3 — **App** (il catalogo: Homebrew semplificato)
Scarica il catalogo `apps.list` **live dal repo a ogni avvio** (§3): sempre la lista più aggiornata.

| # | Schermata | Cosa fa |
|---|-----------|---------|
| A1 | **Catalogo** | Le app con lo stato (installata ✓ / non installata ○); `Spazio` per marcare cosa installare o rimuovere. |
| A2 | **Riepilogo** | "Installerò X, rimuoverò Y". `Conferma` / `Indietro`. |
| A3 | **Esecuzione + Fatto** | Avanzamento live, poi esito. |

### 2.4 — **Terminal** (personalizza il terminale)
Come App ma per il terminale (cataloghi font/temi scaricati live):

| Voce | Cosa fa |
|------|---------|
| **Tema** | Cambia il tema Oh My Posh (anteprima); aggiorna la riga nel blocco Donkey del `~/.zshrc` (mai il resto). |
| **Font** | Installa/seleziona un Nerd Font dal catalogo font. |
| **Suggerimenti** | Attiva/**disattiva** `zsh-autosuggestions` (aggiunge o rimuove la riga `source …` dal `~/.zshrc`). |

È anche la risposta a "come disabilito i suggerimenti?": da qui, senza editare file a mano.

### 2.5 — **Update** (manutenzione on-demand)
| # | Schermata | Cosa fa |
|---|-----------|---------|
| U1 | **Scegli** | Multi-selezione operazioni (aggiorna app/formule, rimuovi inutilizzati, pulizia, diagnostica), default sensati. |
| U2 | **Esecuzione** | Avanzamento live; l'output utile (es. `doctor`) mostrato in pannello scrollabile. |
| U3 | **Fatto** | Esito sintetico. |

### 2.6 — **Auto-update** (gestisci il set-and-forget)
- **Se spento** → *Attivalo*: intervallo + opzioni (`--upgrade`, `--cleanup`, `--ac-only`, …) + `pinentry-mac` per il prompt password GUI.
- **Se acceso** → *Modifica impostazioni* o *Disattivalo*.

### 2.7 — **Status** (sola lettura, funziona anche offline)
```
 Homebrew      6.0.3  ·  4 pacchetti da aggiornare
 Auto-update   attivo · ogni settimana · ultimo run: 2 giorni fa
 Terminale     tema zash · suggerimenti attivi
 App Donkey    11/14 dal catalogo installate
 Donkey        v2.0.0 (aggiornato)

 [A] Aggiorna ora   [Q] Indietro
```

---

## 3. Architettura (ibrida ma **pulita**)

### Modello
Go = **guscio** (TUI + orchestrazione), shell = **lavoro che tocca il sistema** (install/configurazione). Confine netto, **moduli piccoli, niente file monolite**.

- **Go + Bubble Tea + Lipgloss** → menù, wizard, viste, stile. Un modello per schermata.
- **Shell (script piccoli e mirati)** → un file per compito. Nessuno script "fa-tutto".

### Cataloghi: un'unica fonte di verità, sempre fresca
Le liste `config/*.list` **vivono solo nel repo** e sono l'unica fonte di verità. Il binario **non le incorpora e non le cacha**: le **scarica al volo** quando serve il comando (App → `apps.list`; Terminal/Setup → `fonts.list` + `themes.list`), via raw URL dal branch `main`. Così l'utente ha sempre la versione più aggiornata e **tu aggiorni il catalogo editando il repo**, senza nuova release del binario.
- **Rete**: data per scontata sui comandi che la richiedono (`app`, `terminal`, `setup`, `update`); **non** serve a `status` e `uninstall`. Se manca dove serve → schermata d'errore curata.
- **Niente persistenza** = niente liste orfane da ripulire (coerente con l'uninstall a residuo zero, §5).
- In sviluppo, l'URL del catalogo è override-abile (es. `DONKEY_CATALOG_URL` o un path locale) per testare senza pushare.

### Mappa del repo
```
donkey/
├── main.go                 # entry: instrada a TUI o sottocomando
├── internal/
│   ├── tui/
│   │   ├── menu/ setup/ app/ terminal/ update/ autoupdate/ status/
│   │   └── style/          # palette + temi Lipgloss centralizzati
│   ├── catalog/            # download e parsing delle liste dal repo (no cache)
│   ├── state/              # registro locale di cosa Donkey ha installato (per l'uninstall)
│   ├── brew/               # wrapper sottili su brew
│   └── system/             # info sistema (gopsutil)
├── scripts/                # shell: install-packages.sh, configure-shell.sh, setup-autoupdate.sh
├── config/                 # cataloghi (fonte di verità): apps.list, fonts.list, themes.list
├── Makefile · install.sh · AGENTS.md
```

### Regole di architettura
- **Niente monoliti**: un file = una responsabilità.
- **Go orchestra, shell esegue**: la TUI non lancia `brew` sparso — passa da `internal/brew/` o da `scripts/`.
- **Stile centralizzato** in `internal/tui/style/`: una **palette** unica (cambi i colori lì → si propaga ovunque). Non personalizzabile lato utente.
- **Testabile**: logica (catalog, brew, system) separata dalla UI, testabile senza TTY.

### Strumenti
`charmbracelet/bubbletea`, `charmbracelet/lipgloss`, `shirou/gopsutil` · build con **Makefile** · test Go + test shell (**Bats**) · lint (`gofmt` / `golangci-lint`).

---

## 4. Command Surface
- `dk` → menù principale
- `dk app` → catalogo: installa/disinstalla app
- `dk terminal` → personalizza il terminale (tema, font, suggerimenti)
- `dk update` → manutenzione on-demand
- `dk autoupdate` → gestisci l'aggiornamento automatico
- `dk status` → vista di stato (anche offline)
- `dk setup` → onboarding completo (installer / riconfigurazione da zero)
- `dk uninstall` → rimuove Donkey **senza lasciare residui** (con conferma)
- `dk completion` → genera il completamento Tab per il comando `dk`
- `dk version` / `-v` · `dk help` / `-h`

---

## 5. Sicurezza, reversibilità e uninstall

**Invariante**: Donkey è un *layer* sopra Homebrew — lo semplifica, non lo sostituisce. Tocca **solo le proprie aggiunte**; **tutto ciò che preesisteva resta identico**, qualunque fosse.

Tre meccanismi lo garantiscono:
- **Registro locale** (`~/.donkey/`, gestito da `internal/state/`): a ogni installazione Donkey annota **solo ciò che non era già presente** (Homebrew sì/no, formule, cask, tap, job auto-update). È *stato d'azione*, non un catalogo; viene rimosso all'uninstall.
- **Blocco `.zshrc` delimitato**: Donkey **appende** la sua configurazione (tema, suggerimenti, alias) dentro marcatori `# >>> donkey >>>` … `# <<< donkey <<<`; **non sovrascrive mai** il `.zshrc` esistente. La rimozione è chirurgica, il resto (anche le modifiche fatte dopo) resta intatto. Backup `~/.zshrc.bak` come rete di sicurezza.

### `dk uninstall`
Mostra un riepilogo e offre **due strade** (conferma esplicita):
1. **Togli solo Donkey** — rimuove il *layer*: binario, `~/.donkey/`, blocco `.zshrc`, job `homebrew-autoupdate` + tap. **Lascia** i pacchetti installati (sono tuoi).
2. **Pulizia totale** — torna **esattamente a prima di Donkey**: rimuove anche i pacchetti del registro (mai quelli preesistenti).

**Homebrew**: se **preesisteva** → mai toccato. Se **l'ha installato Donkey** → rimosso solo in *pulizia totale*, e solo se non restano pacchetti estranei a Donkey (aggiunti da te dopo); altrimenti **lasciato** con avviso.

In ogni caso: niente `rm -rf` "creativi", e **zero residui** dopo la pulizia totale.

---

## 6. Build, test, verifica
- `make build` / `make run` / `make test` / `make lint` _(da definire nel dettaglio)_.
- La logica (catalog parsing, mappatura brew, system info) è testabile a parte; la TUI a mano + smoke test.

---

## 7. Distribuzione & release
- **Canali**: formula Homebrew (`brew install …`), `install.sh` (`curl | bash`), binari nelle release GitHub.
- **Cataloghi disaccoppiati dal binario**: le liste si aggiornano editando il repo (live), senza nuova release.
- **Versioning**: Semantic Versioning; tag con prefisso `v` (es. `v2.0.0`).
- Obiettivo: **distribuibile online, stabile, affidabile**.

---

## 8. Workflow di sviluppo (git)
1. **Piano di rilascio** prima di toccare codice: nome branch, commit previsti, versione target → attendere OK.
2. **Branch**: `feature/<nome>` (MINOR), `fix/<nome>` (PATCH). Mai `dev/`.
3. **Sviluppo autonomo**: commit + push automatici dopo l'OK.
4. **Review pre-merge**: chiedere **sempre** conferma prima del merge su `master`.
5. **Squash merge** su `master`: un solo commit (titolo + `Versione: X → Y` + `Modifiche:`). Mai rebase su master né merge `--no-ff`.
6. **Tag** `vX.Y.Z` (prefisso `v` obbligatorio) + cleanup del branch.

Convenzioni: [Conventional Commits](https://www.conventionalcommits.org/) con prefisso maiuscolo (`Feat`, `Fix`, `Docs`, `Refactor`, `Style`, `Chore`); italiano per descrizioni e messaggi UI.

---

## 9. Roadmap (percorso verso la 2.0)
1. **Scheletro**: progetto Go + Bubble Tea, menù navigabile, `style/` (palette) condiviso, `internal/catalog/` (download liste).
2. **Onboarding (Setup)**: wizard S1→S8 + `install.sh` che lo lancia al primo avvio.
3. **App**: il catalogo (installa/disinstalla).
4. **Terminal**: personalizzazione (tema, font, suggerimenti).
5. **Auto-update** + **Update**: gestione automatica e manutenzione on-demand.
6. **Status**: la vista di stato.
7. **Uninstall** a residuo zero.
8. **Rifinitura UX** + **distribuzione** (formula Homebrew, install.sh, release binari).
9. **Aggiornare il `README`** per riflettere il nuovo prodotto.
10. **Rinominare il repo** `homebrew` → `donkey`.
11. Prima release stabile → **v2.0.0**.

---

## Styleguide (look & feel)

Tutto lo stile vive in `internal/tui/style/`: cambiare qui si propaga ovunque.

### Palette (nomi univoci)
| Nome | Hex | Ruolo |
|---|---|---|
| `cream` | `#F3E9D2` | testo di base |
| `ash` | `#838383` | testi secondari (descrizioni, footer) |
| `coral` | `#FF3D2A` | brand — logo Donkey |
| `gold` | `#F4BA15` | alert + slogan |
| `magenta` | `#EC3193` | selezione attiva |
| `sky` | `#29B6F6` | comando aperto (titolo della vista) |

### Regole di colore
- **Voce di menù**: titolo `cream` → `magenta` quando selezionata; descrizione `ash` → `cream` quando selezionata.
- **Cursore** `magenta` · **logo** `coral` · **slogan** `gold` · **titolo della vista aperta** `sky`.

### Simboli
cursore `❖` · successo `✓` · errore `✗` · info `◆` · checkbox `■`/`□` · stato installato/non `●`/`○` · attenzione `▲`.

### Animazioni
Vibe **giocoso ma sobrio** (effetto "wow" dosato, mai da prodotto per bambini):
- **Spinner** durante le operazioni (stile da scegliere: monkey 🙈🙉🙊 o a punti).
- **Pulse leggero** del cursore.
- **Logo animato** all'avvio (leggero, una volta sola).
- **Niente fade** al cambio schermata, salvo transizioni leggerissime ed eleganti.
