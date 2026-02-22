# Documentazione Tecnica - Homebrew Management Tools

Documentazione tecnica per sviluppatori e AI assistants per modifiche future al progetto.

## Indice

1. [Architettura Progetto](#architettura-progetto)
2. [Tecnologie Utilizzate](#tecnologie-utilizzate)
3. [Specifiche UI/UX](#specifiche-uiux)
4. [Convenzioni Codice](#convenzioni-codice)
5. [Flussi Operativi](#flussi-operativi)
6. [Gestione Errori](#gestione-errori)
7. [Configurazione UI](#configurazione-ui)
8. [Workflow Git](#workflow-git)

## Architettura Progetto

### Struttura File

```
homebrew/
├── setup.sh           # Script setup iniziale sistema
├── update.sh          # Script aggiornamento e manutenzione
├── README.md          # Documentazione utente
└── CLAUDE.md          # Documentazione tecnica (questo file)
```

### Script Installati in ~/.brew/

- `~/.brew/update.sh` - Copia di update.sh accessibile via alias `brew-update`

### File Generati

- `~/.zshrc` - Configurazione shell con tema selezionato
- `~/.zshrc.bak` - Backup del .zshrc precedente (se esistente)

## Tecnologie Utilizzate

### Gum (Charmbracelet)

- **Versione**: Latest via Homebrew
- **Scopo**: UI interattiva terminale
- **Documentazione**: https://github.com/charmbracelet/gum
- **Componenti usati**:
    - `gum choose`: Select multi/singolo con checkbox
    - `gum spin`: Spinner loader animati
    - `gum style`: Styling testo, bordi, colori
    - `gum confirm`: Dialog conferma Y/N

### Homebrew

- **Comandi utilizzati**:
    - `brew install`: Installa formule (CLI tools)
    - `brew install --cask`: Installa applicazioni
    - `brew update`: Aggiorna repository
    - `brew upgrade`: Aggiorna pacchetti installati
    - `brew upgrade --cask`: Aggiorna applicazioni
    - `brew upgrade --cask --greedy`: Include app con auto-update
    - `brew outdated`: Lista pacchetti obsoleti
    - `brew autoremove`: Rimuove dipendenze orfane
    - `brew cleanup`: Pulizia cache e vecchie versioni
    - `brew doctor`: Diagnostica sistema

### Zsh

- Shell di default su macOS
- Supporto array avanzati
- Sintassi moderna
- Heredoc per generazione file

### Oh My Posh

- Personalizzazione prompt shell
- Temi disponibili: zash, material, robbyrussell, pararussel
- Configurazione tramite file JSON

## Specifiche UI/UX

### Principi Design

1. **Raccolta scelte iniziali**: Tutte le preferenze utente vengono raccolte PRIMA dell'esecuzione
2. **Separazione visiva**: Output Homebrew nascosto (`2>/dev/null`) per UI pulita
3. **Feedback continuo**: Spinner durante operazioni lunghe, messaggi di stato
4. **Gestione errori graceful**: Errori mostrati chiaramente ma esecuzione continua

### Schema Colori

Configurato tramite variabili (256 terminal colors - [Reference](https://www.ditig.com/256-colors-cheat-sheet)):

```bash
GUM_COLOR_SUCCESS="10"   # Verde brillante - operazioni completate
GUM_COLOR_ERROR="9"      # Rosso brillante - errori
GUM_COLOR_WARNING="11"   # Giallo brillante - warning
GUM_COLOR_INFO="14"      # Cyan brillante - informazioni
GUM_COLOR_MUTED="244"    # Grigio - output secondario
```

**ANSI Colors (pre-gum):** Per messaggi prima che gum sia disponibile:
```bash
MUTED="\033[38;5;244m"   # Grigio 244
RESET="\033[0m"          # Reset colore
```

### Simboli UI

Configurati tramite variabili per facile personalizzazione:

```bash
GUM_SYMBOL_SUCCESS="✔︎"   # Operazioni completate
GUM_SYMBOL_WARNING="✘"   # Errori e warning
GUM_SYMBOL_BULLET="→"    # Bullet point liste
GUM_SYMBOL_SKIP="❋"      # Operazione saltata
```

### Pattern UI Comuni

#### Header Sezione

```bash
gum style --border "$GUM_BORDER_ROUNDED" \
    --padding "$GUM_PADDING" \
    --margin "$GUM_MARGIN" \
    --foreground "$GUM_COLOR_INFO" \
    "Titolo Sezione"
```

#### Messaggio Successo

```bash
gum style --foreground "$GUM_COLOR_SUCCESS" \
    "$GUM_SYMBOL_SUCCESS Operazione completata"
```

#### Messaggio Errore

```bash
gum style --foreground "$GUM_COLOR_ERROR" \
    --border "$GUM_BORDER_THICK" \
    --padding "$GUM_ERROR_PADDING" \
    "$GUM_SYMBOL_WARNING Errore: descrizione"
```

#### Selezione Multipla con Default

```bash
selected=$(gum choose --no-limit \
    --selected="Opzione1,Opzione2" \
    --header "Seleziona opzioni:" \
    "Opzione1" "Opzione2" "Opzione3")
```

#### Operazione con Spinner

```bash
if gum spin --spinner "$GUM_SPINNER_TYPE" \
    --title "Descrizione operazione..." \
    -- comando_da_eseguire 2>/dev/null; then
    # Successo
else
    # Errore
fi
```

## Convenzioni Commit

Formato [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <descrizione imperativa breve>

<corpo opzionale: cosa e perché, non come>
```

### Tipi

| Prefisso   | Uso                        | Esempio                                  |
|------------|----------------------------|------------------------------------------|
| `Feat`     | nuova funzionalità         | `Feat: selezione tema opzionale`         |
| `Fix`      | bug fix                    | `Fix: simboli errore consistenti`        |
| `Style`    | UI/UX, formattazione       | `Style: messaggio connessione su due righe` |
| `Refactor` | ristrutturazione codice    | `Refactor: auto-update tag-based`        |
| `Docs`     | documentazione             | `Docs: workflow di sviluppo`             |
| `Chore`    | manutenzione, version bump | `Chore: bump version to 1.10.0`          |

### Regole

- Prefisso: sempre con iniziale maiuscola (`Feat`, `Fix`, `Docs`...)
- Prima riga: max ~70 caratteri, minuscolo dopo i due punti
- Lingua: italiano per la descrizione
- Corpo: opzionale, separato da riga vuota, per spiegare cosa e perché

## Convenzioni Codice

### Naming Variabili

- **MAIUSCOLO**: Variabili configurazione globale (`GUM_COLOR_SUCCESS`, `APP_LIST`, `FONT_LIST`)
- **snake_case**: Variabili locali/temporanee (`selected_apps`, `outdated_casks`)
- **Prefisso GUM\_**: Tutte le variabili di configurazione Gum
- **Suffisso \_LIST**: Array configurabili per liste installazione

### Commenti

- Sezioni delimitate con linea `# ===...===`
- Commenti inline per logica non ovvia
- Intestazione sezione con numero e descrizione
- Riferimenti esterni con link (es. colori terminale)

### Struttura Script

```bash
#!/bin/zsh

# Configurazione UI (variabili gum)
# Configurazione PATH/Environment

# Messaggio iniziale

# ===== SEZIONE 1: Titolo =====
# Logica...

# ===== SEZIONE 2: Titolo =====
# Logica...

# Messaggio finale
```

### Gestione Array

```bash
# Dichiarazione
declare -a array_name=()

# Popolamento
array_name+=("elemento")

# Conversione da output multi-linea
IFS=$'\n' read -r -d '' -a array_name <<< "$output"

# Verifica lunghezza
if [ ${#array_name[@]} -gt 0 ]; then
    # Array non vuoto
fi
```

## Flussi Operativi

### setup.sh

**Flusso Completo:**

1. Definizione liste installazione (`APP_LIST`, `FONT_LIST`)
2. Definizione colori ANSI (per messaggi pre-gum)
3. Messaggio iniziale con lista operazioni (ANSI styled)
4. Attesa conferma utente (Invio per continuare)
5. Installazione silenziosa Homebrew (se non presente)
6. Installazione silenziosa gum (se non presente)
7. **Selezione applicazioni**: Multi-select con checkbox (da `APP_LIST`)
8. **Selezione font**: Multi-select con checkbox (da `FONT_LIST`)
9. **Selezione tema**: Oh My Posh (default: zash)
10. Messaggio "Homebrew installato" (con gum)
11. **Installazione CLI tools**: node, gh, oh-my-posh, gum
12. **Installazione font** selezionati
13. **Installazione applicazioni** selezionate
14. **Setup script aggiornamento**: Copia in ~/.brew/
15. **Configurazione shell**: Genera ~/.zshrc con tema
16. Messaggio completamento

**Variabili Chiave:**

- `APP_LIST[]`, `FONT_LIST[]`: Liste configurabili in testata
- `MUTED`, `RESET`: Colori ANSI per messaggi pre-gum
- `selected_apps_array[]`: Applicazioni selezionate dall'utente
- `selected_fonts_array[]`: Font selezionati dall'utente
- `selected_theme`: Tema Oh My Posh scelto

### update.sh

**Flusso Completo:**

1. Export PATH, controllo/installa gum
2. Configurazione UI (variabili)
3. Messaggio iniziale
4. **Selezione Operazioni**: Multi-select operazioni (tutte pre-selezionate)
    - Aggiorna applicazioni
    - Aggiorna repository
    - Aggiorna formule
    - Rimuovi dipendenze
    - Pulizia cache
    - Diagnostica sistema
5. **Se cask selezionato**: Conferma opzione --greedy
6. **FASE 1**: Aggiornamento applicazioni (se selezionato)
    - Controlla app obsolete (con/senza --greedy)
    - Mostra lista se presenti
    - Aggiorna con spinner
7. **FASE 2**: Operazioni manutenzione (se selezionate)
    - Update repository
    - Upgrade formule
    - Autoremove dipendenze
    - Cleanup cache
    - Doctor diagnostica
8. Messaggio completamento

**Variabili Chiave:**

- `do_cask_upgrade`, `do_update`, `do_upgrade`, `do_autoremove`, `do_cleanup`, `do_doctor`: Boolean per operazioni
- `use_greedy`: Boolean per opzione --greedy
- `outdated_casks`: Lista app da aggiornare

## Gestione Errori

### Strategia

- **Non-blocking**: Errori non fermano esecuzione script
- **Visibilità**: Errori mostrati chiaramente con bordo e colore rosso
- **Continuazione**: Script procede con step successivo
- **Output nascosto**: `2>/dev/null` per output pulito, mostrato solo in caso di errore debug

### Implementazione Pattern

```bash
if gum spin --spinner "$GUM_SPINNER_TYPE" \
    --title "Operazione..." \
    -- comando 2>/dev/null; then
    gum style --foreground "$GUM_COLOR_SUCCESS" \
        "$GUM_SYMBOL_SUCCESS Completato"
else
    gum style --foreground "$GUM_COLOR_ERROR" \
        --border "$GUM_BORDER_THICK" \
        --padding "$GUM_ERROR_PADDING" \
        "$GUM_SYMBOL_WARNING Errore. Continuo..."
fi
# Script continua...
```

### Exit Codes

- `0`: Successo completo
- Non si usano exit espliciti per errori (eccetto installazione Homebrew fallita)
- Ogni operazione gestisce il proprio errore localmente

## Configurazione UI

### Variabili Disponibili

#### Colori

Modificare per cambiare schema colori (valori 0-255):

```bash
GUM_COLOR_SUCCESS="10"     # Verde brillante
GUM_COLOR_ERROR="9"        # Rosso brillante
GUM_COLOR_WARNING="11"     # Giallo brillante
GUM_COLOR_INFO="14"        # Cyan brillante
GUM_COLOR_MUTED="244"      # Grigio
```

#### Simboli

Modificare per adattare a font/preferenze:

```bash
GUM_SYMBOL_SUCCESS="✔︎"     # Completato
GUM_SYMBOL_WARNING="✘"     # Errore/Warning
GUM_SYMBOL_BULLET="→"      # Bullet liste
GUM_SYMBOL_SKIP="❋"        # Saltato
```

#### Spinner

Tipi disponibili: dot, line, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger

```bash
GUM_SPINNER_TYPE="monkey"
```

#### Bordi

Tipi disponibili: none, hidden, normal, rounded, thick, double

```bash
GUM_BORDER_ROUNDED="rounded"
GUM_BORDER_DOUBLE="double"
GUM_BORDER_THICK="thick"
```

#### Layout

```bash
GUM_PADDING="1 2"          # Verticale Orizzontale
GUM_MARGIN="1 0"           # Verticale Orizzontale
GUM_ERROR_PADDING="0 1"    # Padding errori
```

## Liste Installazione

App e font sono configurati tramite array in testata di `setup.sh` (sezione LISTE INSTALLAZIONE).
Separare i dati dalla logica permette di aggiungere/rimuovere elementi senza toccare il codice.

### Applicazioni (`APP_LIST`)

```bash
APP_LIST=(
    "1password"
    "appcleaner"
    "claude-code"
    "dropbox"
    "figma"
    "google-chrome"
    "imageoptim"
    "numi"
    "rectangle"
    "spotify"
    "visual-studio-code"
    "wailbrew"
    "whatsapp"
)
```

**Aggiungere nuove app**:

1. Trovare nome cask: `brew search nome-app`
2. Aggiungere elemento all'array `APP_LIST` in testata
3. Aggiornare README.md sezione Applicazioni

### Font (`FONT_LIST`)

```bash
FONT_LIST=(
    "font-meslo-lg-nerd-font"
    "font-roboto-mono-nerd-font"
)
```

**Aggiungere nuovi font**:

1. Trovare nome cask: `brew search font-nome`
2. Aggiungere elemento all'array `FONT_LIST` in testata
3. Aggiornare README.md sezione Font

## Temi Oh My Posh

Lista temi in `setup.sh` nel blocco `gum choose` tema:

- `zash` (default)
- `material`
- `robbyrussell`
- `pararussel`

**Aggiungere nuovi temi**:

1. Verificare esistenza tema: `ls $(brew --prefix oh-my-posh)/themes/`
2. Aggiungere opzione in `gum choose` tema
3. Aggiornare README.md lista temi

## Note per Modifiche Future

### Aggiunta Nuova Dipendenza CLI

1. Aggiungere a `brew install` in sezione INSTALLAZIONE STRUMENTI CLI
2. Aggiornare README.md lista strumenti

### Modifica Schema Colori

1. Editare variabili `GUM_COLOR_*` nella sezione CONFIGURAZIONE UI
2. Per colori pre-gum, editare variabili ANSI nella sezione COLORI ANSI
3. Usare [256 colors chart](https://www.ditig.com/256-colors-cheat-sheet) per scegliere

### Aggiunta Nuova Operazione in brew-update

1. Aggiungere opzione in `gum choose` nella sezione SELEZIONE OPERAZIONI
2. Aggiungere variabile booleana `do_*`
3. Aggiungere case nel blocco di conversione selezioni
4. Aggiungere sezione condizionale con pattern spinner + errori
5. Aggiornare README.md

### Personalizzazione Simboli

1. Editare variabili `GUM_SYMBOL_*` nella sezione CONFIGURAZIONE UI
2. Usare emoji o caratteri Unicode
3. Testare con font terminale in uso

### Debug

Per vedere output Homebrew completo, rimuovere `2>/dev/null` dai comandi:

```bash
# Prima (output nascosto)
-- brew install xyz 2>/dev/null

# Dopo (output visibile)
-- brew install xyz
```

## Dipendenze

### Richieste

- macOS (testato su macOS 12+)
- Zsh (shell di default su macOS)
- Connessione internet (per download Homebrew/pacchetti)

### Installate Automaticamente

- Homebrew (se non presente)
- Gum (installato con CLI tools)
- Node.js
- GitHub CLI
- Oh My Posh

## Risorse

- [Gum Documentation](https://github.com/charmbracelet/gum)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Oh My Posh Themes](https://ohmyposh.dev/docs/themes)
- [Terminal 256 Colors Chart](https://www.ditig.com/256-colors-cheat-sheet)
- [Zsh Scripting Guide](https://zsh.sourceforge.io/Guide/)

## Workflow Git

### Branching Strategy

Usare branch di sviluppo per non triggerare aggiornamenti prematuri agli utenti:

```
master (stabile, solo release taggate)
  └── feature/nome-feature   (nuove funzionalità)
  └── fix/nome-bug           (bug fix)
```

- **`feature/...`**: nuove funzionalità, modifiche significative → bump MINOR
- **`fix/...`**: bug fix, correzioni, tweaks → bump PATCH
- **Merge su master**: solo dopo approvazione esplicita dell'utente
- **Tag**: creato dopo il merge → solo a quel punto gli utenti vedono l'aggiornamento

### Processo di Sviluppo

**IMPORTANTE**: Seguire SEMPRE questo processo per qualsiasi modifica.

#### 1. Piano di rilascio (PRIMA di qualsiasi codice)

Quando l'utente chiede una modifica, presentare SEMPRE un piano che includa:
- **Tipo di branch**: `feature/` o `fix/` (valutare in autonomia)
- **Nome branch**: descrittivo e conciso
- **Elenco commit previsti**: lista dei commit pianificati con descrizione
- **Versione target**: bump previsto (PATCH/MINOR/MAJOR)

Attendere approvazione dell'utente prima di procedere.

#### 2. Sviluppo (dopo approvazione piano)

- Creare il branch e lavorare in autonomia
- Eseguire TUTTE le operazioni (commit, edit, test) senza chiedere permesso
- Ogni commit viene pushato automaticamente

#### 3. Review pre-merge (PRIMA del merge in master)

- **Chiedere SEMPRE conferma** all'utente prima di mergiare in master
- L'utente potrebbe voler aggiungere o correggere qualcosa
- Se l'utente chiede modifiche ulteriori: valutare se tenerle nello stesso branch o chiudere + nuovo branch, e proporre la soluzione

#### 4. Rilascio (dopo approvazione merge) — Squash Merge

Eseguire TUTTO in autonomia senza chiedere permesso:

```bash
# 1. Aggiornare SCRIPT_VERSION come ultimo commit sul branch
sed -i '' 's/SCRIPT_VERSION="x.y.z"/SCRIPT_VERSION="a.b.c"/' update.sh
git add update.sh && git commit -m "Chore: bump version to a.b.c" && git push

# 2. Squash merge su master (tutti i commit del branch → un solo commit)
git checkout master
git merge --squash feature/nome

# 3. Commit unico con changelog (filtrare i fix intermedi di testing)
git commit -m "$(cat <<'EOF'
Tipo: titolo descrittivo

Versione: x.y.z → a.b.c

Modifiche:
- Feat: descrizione funzionalità 1
- Fix: descrizione bug fix significativo
- Style: descrizione miglioramento UI
EOF
)"

# 4. Push + tag + cleanup
git push
git tag va.b.c && git push origin va.b.c
git branch -d feature/nome
git push origin --delete feature/nome
```

**Formato commit su master**: prima riga sintetica, poi `Versione: X → Y`, poi `Modifiche:` con i cambiamenti significativi (NON i fix intermedi di testing). Il log del branch (`git log master..feature/nome --format="- %s" --reverse`) è un punto di partenza da sintetizzare.

**Risultato su master**: un solo commit per release, leggibile come changelog. Nessun commit di bump separato.

### Versionamento Semantico (Semver)

Seguire [Semantic Versioning](https://semver.org/lang/it/):

- **PATCH** (x.y.Z): bug fix, UI tweaks, modifiche minori
- **MINOR** (x.Y.0): nuove funzionalità backward-compatible
- **MAJOR** (X.0.0): breaking changes

**IMPORTANTE**: `SCRIPT_VERSION` in `update.sh` deve SEMPRE corrispondere al tag. Aggiornare come ultimo commit sul branch di sviluppo, prima del merge su master. Il meccanismo di auto-update confronta `SCRIPT_VERSION` con l'ultimo tag GitHub per decidere se proporre l'aggiornamento.

### Auto-aggiornamento Script (tag-based)

Il meccanismo di auto-update in `update.sh` funziona così:

1. **Controlla ultimo tag** su GitHub API (`/repos/{repo}/tags`)
2. **Confronta versioni** (semver): `SCRIPT_VERSION` locale vs tag remoto
3. **Solo se il tag è più recente**: propone aggiornamento all'utente
4. **Scarica dal tag specifico**: `raw.githubusercontent.com/{repo}/{tag}/update.sh`

**Conseguenze importanti:**
- Commit su master senza nuovo tag → **nessun aggiornamento** proposto agli utenti
- Commit su branch di sviluppo → **nessun impatto** sugli utenti
- Nuovo tag creato → **utenti notificati** al prossimo avvio di brew-update

## Changelog

### v1.12.4 - Fix compatibilità sh e nuova app Mole (2026-02-18)

- **Aggiunta Mole**: aggiunta `mole` alla lista app in `setup.sh`
- **Fix `printf`**: sostituito `echo -e` con `printf` per evitare la stampa letterale di `-e` con shell `sh`
- **Style**: rimossi spazi superflui prima di `→` nella lista iniziale di `update.sh`

### v1.12.3 - Aggiornamento app sempre greedy con selezione interattiva (2026-02-18)

- **Rimossa scelta greedy**: eliminata la domanda "Includere anche app con auto-aggiornamento?" — il flusso è ora sempre greedy
- **Selezione interattiva sempre presente**: la `gum choose` per scegliere le app da aggiornare è sempre mostrata, flusso lineare senza branch if/else
- **Style**: messaggio "Aggiornamento applicazioni in corso..." semplificato

### v1.12.2 - Fix brew upgrade limitato alle formulae (2026-02-18)

- **Fix**: aggiunto `--formula` a `brew upgrade` nella sezione "strumenti e librerie" per escludere i cask dallo step (evita conflitti con la gestione separata delle app)

### v1.12.1 - Style messaggio greedy (2026-02-18)

- **Style**: il messaggio "Aggiornamento applicazioni in corso..." usa ora colore info (`GUM_COLOR_INFO`) e icona bullet, coerente con il resto della UI

### v1.12.0 - UX improvements, SIGINT e rinomina file (2026-02-18)

- **Opzione `-v` / `--version`**: stampa la versione corrente (`v1.12.0`) e termina
- **Ctrl+C in qualsiasi fase**: trap SIGINT che esce silenziosamente senza output; fix specifico per `gum confirm` (che intercetta il segnale internamente e richiede `kill -INT $$`) e per tutti i `gum choose` in command substitution (exit code 130 check esplicito)
- **UI lista app obsolete rimossa**: nella selezione greedy la `gum choose` mostra direttamente le app senza intestazione ridondante; header rinominato in "Seleziona le applicazioni con aggiornamenti disponibili che vuoi aggiornare:"
- **Riga vuota separatore**: aggiunta dopo l'output di brew upgrade --greedy, prima del messaggio di feedback
- **Strategia squash merge**: adottata per master — un commit per release con changelog integrato, nessun commit intermedio di sviluppo su master
- **Rinomina file progetto**: `brew-update.sh` → `update.sh`, `brew-setup.sh` → `setup.sh`
- **Aggiornati tutti i riferimenti interni**: URL auto-update, percorsi copia, alias
- **Nota breaking change**: utenti con versione ≤ 1.11.0 non ricevono l'auto-update (URL download cambiato da `brew-update.sh` a `update.sh`); devono rieseguire `setup.sh` manualmente

### v1.9.0 - Auto-update tag-based e branching workflow (2026-02-08)

- **Auto-update basato su tag**: sostituito meccanismo hash-based con confronto semver vs ultimo tag GitHub
  - Prima: confrontava hash SHA dei file (qualsiasi differenza triggerava update, anche a parità di versione)
  - Ora: confronta `SCRIPT_VERSION` locale con ultimo tag GitHub (update solo quando il tag è più recente)
- **Download dal tag specifico**: scarica script da `raw.githubusercontent.com/{repo}/{tag}/` invece che da HEAD master
- **Confronto semver**: usa python3 per confronto versioni affidabile (v_remote > v_local)
- **Branching strategy documentata**: sviluppo su branch `dev/` o `fix/`, merge + tag su master per rilascio
- **Variabile `SCRIPT_REPO`**: sostituisce `SCRIPT_SOURCE`, contiene solo `owner/repo`
- Rimosse variabili inutilizzate: `script_update_checked`, `SCRIPT_SOURCE`
- Flusso di rilascio documentato in CLAUDE.md

### v1.8.1 - Miglioramenti UI auto-aggiornamento (2026-02-07)

- **Versione nel titolo**: mostra "Homebrew Update → v1.8.1 🚀" invece di "Inizio"
- **Terminazione dopo aggiornamento**: se utente accetta aggiornamento, script si aggiorna e termina
  - Messaggio: "brew-update aggiornato da vX.X.X a vY.Y.Y"
  - Invito: "Riavvia il comando 'brew-update' per utilizzare la nuova versione"
  - Exit pulito senza proseguire con altre operazioni
- **Pulizia output**: rimosso messaggio "❋ brew-update: v1.8.0" quando script già aggiornato
- **Messaggio warning**: mostrato solo se utente rifiuta aggiornamento disponibile
- Migliora chiarezza UX e flusso di aggiornamento

### v1.8.0 - Test connessione e auto-aggiornamento interattivo (2026-02-07)

- **Test connessione internet** obbligatorio all'avvio di entrambi gli script
  - update.sh: test dopo installazione gum, messaggio errore con gum style
  - setup.sh: test prima di installare Homebrew/gum, messaggio errore con ANSI colors
  - Se connessione assente: mostra warning e termina script (exit 1)
  - Skip automatico in modalità TEST (--test)
- **Auto-aggiornamento interattivo** in update.sh
  - Non più silenzioso: chiede conferma all'utente prima di aggiornare
  - Usa gum confirm con messaggio: "È disponibile una nuova versione di brew-update (vX.X.X). Vuoi aggiornarla ora?"
  - Default: true (consiglia aggiornamento)
  - Messaggio di stato aggiornato per gestire 3 casi:
    - Aggiornato con successo (verde)
    - Nuova versione disponibile ma rifiutata (warning giallo)
    - Nessun aggiornamento disponibile (info grigio)
- Migliora UX: utente sempre informato e in controllo degli aggiornamenti
- Previene esecuzione in assenza di connessione con messaggio chiaro

### v1.7.1 - Simulazione richiesta password in TEST mode (2026-02-07)

- Aggiunto fake password prompt visivo in modalità TEST
- Simula "🔒 Password amministratore richiesta" prima delle installazioni
- Applicato a update.sh (sezione greedy app update)
- Applicato a setup.sh (sezioni CLI tools, font, app)
- Permette di testare anche la casistica password senza dover autenticarsi
- UX TEST completa: replica tutti gli scenari reali inclusa richiesta admin

### v1.7.0 - Modalità TEST per entrambi gli script (2026-02-07)

- Aggiunta modalità test completa con flag `--test` per update.sh e setup.sh
- Banner warning visibile: "⚠️ MODALITÀ TEST - Dati simulati, nessuna modifica reale al sistema"
- **update.sh --test**: Simula tutte le operazioni con dati fake e delay realistici
  - App obsolete fake (chrome, vscode, 1password, spotify, dropbox)
  - Output brew progressivo simulato per installazioni (Downloading, Installing, Summary)
  - Delay variabili per realismo (0.3s-1.2s a seconda dell'operazione)
  - Diagnostica fake "Your system is ready to brew"
- **setup.sh --test**: Simula installazioni senza modifiche filesystem
  - CLI tools, font, applicazioni con output simulato
  - Skip configurazione .zshrc e copia script in modalità test
- Uso: `brew-update --test` o `brew-setup --test`
- Permette testing completo senza impatto sul sistema
- Utile per demo, sviluppo, e verifica UI/UX

### v1.6.1 - Fix riga Password orfana (2026-02-07)

- Cancellazione automatica riga "Password:" dopo inserimento
- Usa ANSI escape codes (`\033[1A\033[2K`) per rimuovere righe
- Output pulito senza "Password:" residua a schermo
- Migliora percezione di pulizia UI durante installazione

### v1.6.0 - Fix blocco app greedy con output filtrato (2026-02-07)

- Risolto blocco apparente durante aggiornamento app con --greedy
- Sostituito spinner con output filtrato (pattern identico a setup.sh)
- Rimosso `sudo -v` e `gum spin` che nascondevano richiesta password di brew
- Output filtrato permette di vedere password prompt e progresso installazione
- Output pulito mostrando solo righe rilevanti (Password, Downloading, Installing, etc.)
- Spinner mantenuto per app non-greedy dove funziona correttamente
- Soluzione stabile testata e coerente con resto del progetto

### v1.5.5 - Ottimizzazione richiesta password (2026-02-07)

- Password richiesta solo per app con auto-aggiornamento (greedy)
- Rimossa richiesta password per app normali (non necessaria)
- Migliora UX: non disturba l'utente quando non serve
- Apps normali raramente richiedono privilegi amministratore

### v1.5.4 - Fix gestione password errata (2026-02-07)

- Aggiunto controllo exit code di `sudo -v`
- Se password errata: mostra messaggio errore e salta installazione
- Se password corretta: procede con spinner
- Previene che lo script si blocchi se password inserita erroneamente

### v1.5.3 - Fix richiesta password nascosta (2026-02-07)

- Aggiunto messaggio warning prima della richiesta password
- Richiesta password upfront con `sudo -v` prima dello spinner
- Previene che lo script sembri bloccato mentre brew attende la password
- Applicato a entrambi i rami (greedy e non-greedy)

### v1.5.2 - Fix spinner invisibile (2026-02-07)

- Fix bug: rimosso &>/dev/null che nascondeva output di gum spin
- gum spin nasconde già automaticamente l'output del comando
- Spinner ora visibile e funzionante durante aggiornamento app
- Permette a brew di richiedere password se necessario

### v1.5.1 - Spinner per aggiornamento applicazioni (2026-02-07)

- Sostituito output filtrato con spinner animato durante aggiornamento app
- UI più pulita: nasconde output brew e mostra solo spinner con messaggio
- Applicato a entrambi i rami (greedy e non-greedy)
- Riduce verbosità e migliora percezione di responsività

### v1.5.0 - Selezione interattiva app con auto-update (2026-02-07)

- Aggiunta selezione interattiva delle app quando use_greedy=true
- L'utente può scegliere quali app aggiornare tramite checkbox multi-select
- Menu gum choose con stile identico a setup.sh
- Gestione caso "nessuna selezione" con messaggio INFO
- Flusso non-greedy invariato (aggiorna tutte le app automaticamente)
- Nuova variabile `selected_casks_array[]` per app selezionate dall'utente

### v2.6 - Fix versione e documentazione SCRIPT_VERSION (2026-02-06)

- Fix messaggi versione invertiti in brew-update
- Documentata regola: SCRIPT_VERSION deve SEMPRE corrispondere al git tag
- Aggiornata documentazione workflow git con nota su SCRIPT_VERSION

### v2.5 - Messaggio versione script (2026-02-06)

- Aggiunta variabile `SCRIPT_VERSION` per tracciamento versione
- Messaggio info con stato versione prima delle operazioni
- Mostra versione corrente se aggiornato, o versione nuova se appena aggiornato

### v2.4 - Auto-aggiornamento script (2026-02-06)

- Auto-update silenzioso di `update.sh` dalla repo GitHub pubblica
- Scarica l'ultima versione all'avvio e aggiorna `~/.brew/update.sh` se diversa
- Nessun output per l'utente: completamente trasparente
- Timeout 5s per non bloccare in caso di assenza di rete
- Nuova variabile `SCRIPT_SOURCE` per URL sorgente
- Aggiunto hint `brew-update` nel messaggio finale di `setup.sh`
- Migliorate spaziature output aggiornamento applicazioni

### v2.3 - Liste configurabili e selezione font (2026-02-06)

- Liste app e font separate dalla logica in variabili `APP_LIST` e `FONT_LIST`
- Selezione interattiva font con menu checkbox (come le app)
- Gestione casistiche font: nessuno selezionato, già installati, errori
- Guard per array vuoti (menu non mostrato se lista vuota)

### v2.2 - Bug fix e robustezza (2026-02-06)

- Fix PIPESTATUS → pipestatus (zsh usa array 1-indexed)
- Fallback tema default "zash" se selezione vuota
- File temporanei con PID (`$$`) per evitare conflitti concorrenti
- Trap EXIT per pulizia automatica file temporanei
- Redirect stdout dentro `sh -c` per robustezza
- Sostituito `bash -c` con `sh -c` per consistenza POSIX
- Eliminato uso superfluo di `cat` (UUOC)
- Liste app indentate e colorate muted

### v2.1 - Ottimizzazioni (2026-02-05)

- Fix bug: gum usato prima di essere installato
- Aggiunto messaggio iniziale con ANSI colors (pre-gum)
- Installazione silenziosa Homebrew e gum
- Selezioni utente spostate prima delle installazioni
- Commenti migliorati in tutti gli script
- README.md snellito (sezione sviluppatori)

### v2.0 - UI Interattiva (2026-02-04)

- Aggiunta interfaccia interattiva con Gum
- Selezione applicazioni con checkbox
- Selezione tema Oh My Posh
- Selezione operazioni manutenzione
- Spinner animati
- Configurazione UI centralizzata
- Gestione errori migliorata

### v1.0 - Versione Iniziale

- Script setup base
- Script aggiornamento
- Installazione automatica pacchetti

---

_Ultimo aggiornamento: 2026-02-22_ _Versione: 1.12.4 (fix sh compatibilità, app sempre greedy, Mole)_
