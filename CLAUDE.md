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

## Architettura Progetto

### Struttura File

```
homebrew/
├── brew-setup.sh      # Script setup iniziale sistema
├── brew-update.sh     # Script aggiornamento e manutenzione
├── .zshrc             # Template configurazione shell (copiato in ~/)
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
GUM_COLOR_SUCCESS="2"    # Verde - operazioni completate
GUM_COLOR_ERROR="196"    # Rosso - errori
GUM_COLOR_WARNING="3"    # Giallo - warning
GUM_COLOR_INFO="6"       # Cyan - informazioni
GUM_COLOR_PRIMARY="5"    # Magenta - header principali
GUM_COLOR_MUTED="240"    # Grigio - output secondario
```

### Simboli UI

Configurati tramite variabili per facile personalizzazione:

```bash
GUM_SYMBOL_SUCCESS="✔"   # Operazioni completate
GUM_SYMBOL_WARNING="⚠"   # Errori e warning
GUM_SYMBOL_BULLET="❖"    # Bullet point liste
GUM_SYMBOL_SKIP="⊘"      # Operazione saltata
GUM_SYMBOL_INFO="⚑"      # Informazioni
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

- **MAIUSCOLO**: Variabili configurazione globale UI (`GUM_COLOR_SUCCESS`, `GUM_SPINNER_TYPE`)
- **snake_case**: Variabili locali/temporanee (`selected_apps`, `outdated_casks`)
- **Prefisso GUM\_**: Tutte le variabili di configurazione Gum

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

1. Configurazione UI (variabili)
2. Messaggio iniziale
3. **Sezione 1**: Controlla/installa Homebrew
4. **Sezione 2**: Installa CLI tools essenziali (node, gh, oh-my-posh, gum)
5. **Sezione 3**: Raccolta preferenze utente
    - Multi-select applicazioni (checkbox)
    - Select tema Oh My Posh (singola scelta, default: zash)
6. **Sezione 4**: Installazione
    - Font (Meslo LG, Roboto Mono)
    - Applicazioni selezionate
7. **Sezione 5**: Setup script aggiornamento
    - Crea `~/Shell/`
    - Copia `brew-update.sh`
8. **Sezione 6**: Configurazione shell
    - Backup `.zshrc` esistente
    - Genera nuovo `.zshrc` con tema selezionato
9. Messaggio completamento

**Variabili Chiave:**

- `selected_apps_array[]`: Applicazioni da installare
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
GUM_COLOR_SUCCESS="2"      # Verde
GUM_COLOR_ERROR="196"      # Rosso
GUM_COLOR_WARNING="3"      # Giallo
GUM_COLOR_INFO="6"         # Cyan
GUM_COLOR_PRIMARY="5"      # Magenta
GUM_COLOR_MUTED="240"      # Grigio
```

#### Simboli

Modificare per adattare a font/preferenze:

```bash
GUM_SYMBOL_SUCCESS="✔"
GUM_SYMBOL_WARNING="⚠"
GUM_SYMBOL_BULLET="❖"
GUM_SYMBOL_SKIP="⊘"
GUM_SYMBOL_INFO="⚑"
```

#### Spinner

Tipi disponibili: dot, line, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger

```bash
GUM_SPINNER_TYPE="dot"
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

## Applicazioni Installabili

Lista mantenuta in `brew-setup.sh` array `apps` (linee 86-98):

- 1password
- appcleaner
- claude-code
- dropbox
- figma
- google-chrome
- imageoptim
- numi
- rectangle
- spotify
- visual-studio-code
- wailbrew
- whatsapp

**Aggiungere nuove app**:

1. Inserire nome cask nell'array (ordine alfabetico preferito)
2. Aggiornare README.md sezione Applicazioni

## Temi Oh My Posh

Lista temi in `brew-setup.sh` gum choose (linee 106-110):

- `zash` (default)
- `material`
- `robbyrussell`
- `pararussel`

**Aggiungere nuovi temi**:

1. Verificare esistenza tema in Oh My Posh: `ls $(brew --prefix oh-my-posh)/themes/`
2. Aggiungere opzione in `gum choose` tema
3. Aggiornare README.md lista temi

## Note per Modifiche Future

### Aggiunta Nuova Dipendenza CLI

1. Aggiungere a `brew install` in sezione CLI tools (brew-setup.sh:68)
2. Aggiornare README.md lista strumenti

### Modifica Schema Colori

1. Editare variabili `GUM_COLOR_*` all'inizio script (brew-setup.sh:7-13, brew-update.sh:15-21)
2. Usare [256 colors chart](https://www.ditig.com/256-colors-cheat-sheet) per scegliere

### Aggiunta Nuova Operazione in brew-update

1. Aggiungere opzione in `gum choose` operazioni (brew-update.sh:53-60)
2. Aggiungere variabile booleana `do_*` (brew-update.sh:62-69)
3. Aggiungere case in conversione (brew-update.sh:72-80)
4. Aggiungere sezione condizionale con pattern spinner + errori
5. Aggiornare README.md

### Personalizzazione Simboli

1. Editare variabili `GUM_SYMBOL_*` (brew-setup.sh:15-20, brew-update.sh:23-26)
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

## Changelog

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

_Ultimo aggiornamento: 2026-02-04_ _Versione: 2.0 (UI Interattiva)_
