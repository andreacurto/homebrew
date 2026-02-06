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
├── brew-setup.sh      # Script setup iniziale sistema
├── brew-update.sh     # Script aggiornamento e manutenzione
├── .zshrc-example     # Template configurazione shell (riferimento)
├── README.md          # Documentazione utente
└── CLAUDE.md          # Documentazione tecnica (questo file)
```

### Script Installati in ~/Shell/

- `~/Shell/brew-update.sh` - Copia di brew-update.sh accessibile via alias

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

### brew-setup.sh

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
14. **Setup script aggiornamento**: Copia in ~/Shell/
15. **Configurazione shell**: Genera ~/.zshrc con tema
16. Messaggio completamento

**Variabili Chiave:**

- `APP_LIST[]`, `FONT_LIST[]`: Liste configurabili in testata
- `MUTED`, `RESET`: Colori ANSI per messaggi pre-gum
- `selected_apps_array[]`: Applicazioni selezionate dall'utente
- `selected_fonts_array[]`: Font selezionati dall'utente
- `selected_theme`: Tema Oh My Posh scelto

### brew-update.sh

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

App e font sono configurati tramite array in testata di `brew-setup.sh` (sezione LISTE INSTALLAZIONE).
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

Lista temi in `brew-setup.sh` nel blocco `gum choose` tema:

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

### Commit e Push

- Dopo ogni commit, eseguire sempre il push automaticamente senza attendere conferma
- Non aspettare che l'utente chieda di pushare

### Versionamento Semantico (Semver)

Dopo ogni commit+push, valutare automaticamente il bump di versione seguendo [Semantic Versioning](https://semver.org/lang/it/) e aggiornare il tag git:

- **PATCH** (x.y.Z): bug fix, UI tweaks, modifiche minori
- **MINOR** (x.Y.0): nuove funzionalità backward-compatible
- **MAJOR** (X.0.0): breaking changes

Esempio:
```bash
git tag v1.0.1 && git push origin v1.0.1
```

## Changelog

### v2.5 - Messaggio versione script (2026-02-06)

- Aggiunta variabile `SCRIPT_VERSION` per tracciamento versione
- Messaggio info con stato versione prima delle operazioni
- Mostra versione corrente se aggiornato, o versione nuova se appena aggiornato

### v2.4 - Auto-aggiornamento script (2026-02-06)

- Auto-update silenzioso di `brew-update.sh` dalla repo GitHub pubblica
- Scarica l'ultima versione all'avvio e aggiorna `~/Shell/brew-update.sh` se diversa
- Nessun output per l'utente: completamente trasparente
- Timeout 5s per non bloccare in caso di assenza di rete
- Nuova variabile `SCRIPT_SOURCE` per URL sorgente
- Aggiunto hint `brew-update` nel messaggio finale di `brew-setup.sh`
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

_Ultimo aggiornamento: 2026-02-06_ _Versione: 2.5 (Messaggio versione script)_
