# Homebrew Management Tools

Script per installare e mantenere aggiornato il tuo Mac con Homebrew in modo semplice e automatico.

## Cosa fa questo tool

Questo progetto ti permette di:

1. **Installare Homebrew** (se non ce l'hai già)
2. **Scegliere quali applicazioni installare** tramite un menu interattivo con checkbox
3. **Mantenere tutto aggiornato** con un singolo comando da terminale
4. **Personalizzare il tema del terminale** scegliendo tra 4 temi disponibili

Tutto con un'interfaccia grafica nel terminale che ti guida passo dopo passo.

---

## Come Iniziare

### Passo 1: Scarica il progetto

Scarica questa cartella sul tuo Mac (o clonala con git se sai come fare).

### Passo 2: Apri il Terminale

1. Premi `Cmd + Spazio` per aprire Spotlight
2. Scrivi "Terminale" e premi Invio
3. Naviga nella cartella dove hai scaricato il progetto:
    ```bash
    cd /percorso/della/cartella/homebrew
    ```

### Passo 3: Rendi eseguibile lo script

Copia e incolla questo comando:

```bash
chmod +x brew-setup.sh
```

### Passo 4: Avvia l'installazione

Copia e incolla questo comando:

```bash
./brew-setup.sh
```

### Passo 5: Segui le istruzioni

Lo script ti mostrerà:

1. **Installazione automatica di Homebrew** (se non ce l'hai già)
    - Vedrai uno spinner mentre installa

2. **Installazione strumenti base**
    - Node.js, GitHub CLI, Oh My Posh, Gum
    - Vedrai uno spinner e poi un check verde ✓

3. **Scelta applicazioni**
    - Ti appare una lista con checkbox (□ vuoto, ■ pieno)
    - Usa le **frecce** per muoverti
    - Premi **Spazio** per selezionare/deselezionare
    - Premi **Invio** quando hai finito

4. **Scelta tema terminale**
    - 4 temi tra cui scegliere (consigliato: zash)
    - Usa le **frecce** e premi **Invio**

5. **Installazione automatica**
    - Font necessari
    - Applicazioni che hai selezionato
    - Vedrai gli spinner e poi i check verdi ✓

6. **Messaggio finale**
    - "Homebrew Setup - Completato 🎉"
    - **Chiudi e riapri il terminale** per vedere le modifiche

---

## Come Aggiornare il Sistema

Dopo l'installazione iniziale, puoi aggiornare tutto con un comando.

### Comando di aggiornamento

Apri il terminale e scrivi:

```bash
brew-update
```

### Cosa succede

1. **Menu di selezione**
    - Ti appare una lista con tutte le operazioni pre-selezionate (■)
    - Puoi deselezionare (□) quelle che non vuoi eseguire
    - Premi **Invio** per continuare

2. **Opzione per app con auto-update**
    - Ti chiede se includere anche app che si aggiornano da sole
    - Scegli Yes o No

3. **Esecuzione operazioni**
    - Vedrai uno spinner per ogni operazione
    - Quando finisce, lo spinner diventa un check verde ✓
    - Se c'è un errore, vedi un punto esclamativo rosso !

4. **Output diagnostica**
    - Se hai selezionato "Diagnostica sistema"
    - Vedrai l'output completo di brew doctor

5. **Messaggio finale**
    - "Homebrew Update - Completato 🎉"

---

## Applicazioni Disponibili

Durante il setup puoi scegliere quali installare:

| Applicazione       | Descrizione                   |
| ------------------ | ----------------------------- |
| 1Password          | Password manager              |
| AppCleaner         | Disinstallazione completa app |
| Claude Code        | Editor AI-powered             |
| Dropbox            | Cloud storage                 |
| Figma              | Design e prototipazione       |
| Google Chrome      | Browser web                   |
| ImageOptim         | Ottimizzazione immagini       |
| Numi               | Calcolatrice intelligente     |
| Rectangle          | Window manager                |
| Spotify            | Streaming musicale            |
| Visual Studio Code | Editor di codice              |
| WailBrew           | GUI per Homebrew              |
| WhatsApp           | Messaggistica                 |

**Nota**: Puoi selezionare solo quelle che ti servono, non sei obbligato a installarle tutte.

---

## Temi Terminale

Durante il setup scegli uno di questi temi per il terminale:

- **zash** (consigliato) - Minimalista e pulito
- **material** - Ispirato a Material Design di Google
- **robbyrussell** - Tema classico e popolare
- **pararussel** - Variante del precedente

### Cambiare tema dopo l'installazione

Se vuoi cambiare tema in seguito:

1. Apri il file di configurazione:

    ```bash
    nano ~/.zshrc
    ```

2. Cambia `zash` con il tema che preferisci:

    ```bash
    eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/NOME_TEMA.omp.json)"
    ```

3. Salva (Ctrl+O, Invio) ed esci (Ctrl+X)

4. Riavvia il terminale

---

## Risoluzione Problemi

### "Permission denied" quando eseguo ./brew-setup.sh

Hai dimenticato il Passo 3. Esegui:

```bash
chmod +x brew-setup.sh
```

### "Command not found: brew-update"

Hai chiuso e riaperto il terminale dopo l'installazione? È necessario per caricare le nuove configurazioni.

### Le applicazioni non si installano

Alcune applicazioni potrebbero richiedere conferme manuali o avere problemi di compatibilità con la tua versione di macOS. Lo script continua comunque con le altre.

### Voglio reinstallare tutto

Puoi rieseguire `./brew-setup.sh` senza problemi. Lo script rileva cosa è già installato e salta quei passaggi.

---

## Personalizzazione per Sviluppatori

### File di Configurazione

Le configurazioni UI si trovano all'inizio di ogni script:
- `brew-setup.sh` - Script di installazione (linee 16-45)
- `brew-update.sh` - Script di aggiornamento (linee 26-54)
- `CLAUDE.md` - Documentazione tecnica dettagliata

### Variabili Principali

**Colori** (palette 256 colori - [chart](https://www.ditig.com/256-colors-cheat-sheet)):
```bash
GUM_COLOR_SUCCESS="10"    # Operazioni completate
GUM_COLOR_ERROR="9"       # Errori
GUM_COLOR_WARNING="11"    # Warning e skip
GUM_COLOR_INFO="14"       # Messaggi informativi
GUM_COLOR_MUTED="244"     # Testo secondario
```

**Simboli**:
```bash
GUM_SYMBOL_SUCCESS="✓"    # Completato
GUM_SYMBOL_WARNING="!"    # Errore/Warning
GUM_SYMBOL_SKIP="○"       # Saltato
```

**Spinner** (tipi: `dot`, `line`, `monkey`, `globe`, `moon`, etc.):
```bash
GUM_SPINNER_TYPE="monkey"
```

### Quick Tasks

**Aggiungere applicazione:**
1. Trova il cask: `brew search nome-app`
2. Aggiungi alla lista in `brew-setup.sh` (linee 55-72)
3. Aggiorna tabella in README.md

**Cambiare tema:**
Modifica `~/.zshrc` e sostituisci il nome del tema, poi riavvia il terminale.

**Testare modifiche:**
```bash
# brew-setup.sh
./brew-setup.sh

# brew-update.sh
cp brew-update.sh ~/Shell/brew-update.sh && brew-update
```

### Reference

- [Gum Documentation](https://github.com/charmbracelet/gum) - UI terminale
- [Oh My Posh Themes](https://ohmyposh.dev/docs/themes) - Temi shell
- [Homebrew Docs](https://docs.brew.sh/) - Package manager
- [256 Colors Chart](https://www.ditig.com/256-colors-cheat-sheet) - Colori terminale
- [CLAUDE.md](CLAUDE.md) - Documentazione tecnica completa

---

## Contributi

Suggerimenti e bug reports: apri una issue su GitHub.
