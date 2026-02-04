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

| Applicazione | Descrizione |
|-------------|-------------|
| 1Password | Password manager |
| AppCleaner | Disinstallazione completa app |
| Claude Code | Editor AI-powered |
| Dropbox | Cloud storage |
| Figma | Design e prototipazione |
| Google Chrome | Browser web |
| ImageOptim | Ottimizzazione immagini |
| Numi | Calcolatrice intelligente |
| Rectangle | Window manager |
| Spotify | Streaming musicale |
| Visual Studio Code | Editor di codice |
| WailBrew | GUI per Homebrew |
| WhatsApp | Messaggistica |

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

Questa sezione è per chi vuole modificare l'aspetto e il comportamento degli script.

### File da modificare

I file principali sono:
- `brew-setup.sh` - Script di installazione iniziale
- `brew-update.sh` - Script di aggiornamento

Le configurazioni UI sono all'inizio di ogni file (linee 3-38).

### Colori

I colori usano la palette a 256 colori del terminale.

**Variabili disponibili:**
```bash
GUM_COLOR_SUCCESS="10"    # Verde - operazioni completate
GUM_COLOR_ERROR="9"       # Rosso - errori
GUM_COLOR_WARNING="11"    # Giallo - warning
GUM_COLOR_INFO="14"       # Cyan - informazioni
GUM_COLOR_PRIMARY="13"    # Magenta - titoli principali
GUM_COLOR_MUTED="244"     # Grigio - testo secondario
```

**Reference colori:**
- [256 Colors Cheat Sheet](https://www.ditig.com/256-colors-cheat-sheet) - Tutti i colori disponibili con codici

**Come cambiare:**
1. Scegli un numero dalla chart (0-255)
2. Sostituisci il numero nella variabile
3. Salva il file

**Esempio:** Per usare un blu al posto del cyan per INFO:
```bash
GUM_COLOR_INFO="33"  # Blu medio
```

### Simboli

I simboli sono caratteri Unicode usati per messaggi e checkbox.

**Variabili disponibili:**
```bash
GUM_SYMBOL_SUCCESS="✓"          # Check per successo
GUM_SYMBOL_WARNING="!"          # Punto esclamativo per errori
GUM_SYMBOL_BULLET="·"           # Punto per liste
GUM_SYMBOL_SKIP="○"             # Cerchio vuoto per skip
GUM_CHECKBOX_SELECTED="■"       # Checkbox piena (selezionata)
GUM_CHECKBOX_UNSELECTED="□"     # Checkbox vuota (non selezionata)
GUM_CHECKBOX_CURSOR="›"         # Cursore di selezione
```

**Come cambiare:**
1. Cerca il carattere Unicode che preferisci
2. Sostituisci nella variabile
3. Salva il file

**Esempio:** Per usare emoji invece di simboli:
```bash
GUM_SYMBOL_SUCCESS="✅"
GUM_SYMBOL_WARNING="❌"
```

### Spinner

Lo spinner è l'animazione che appare durante le operazioni lunghe.

**Variabile:**
```bash
GUM_SPINNER_TYPE="line"
```

**Tipi disponibili in Gum:**
- `dot` - Punto che si muove
- `line` - Linea che ruota (attuale)
- `minidot` - Punto minimo
- `jump` - Punto che salta
- `pulse` - Punto che pulsa
- `points` - Punti che appaiono
- `globe` - Globo che ruota
- `moon` - Luna che cambia fase
- `monkey` - Scimmia animata
- `meter` - Barra di avanzamento
- `hamburger` - Hamburger animato

**Come cambiare:**
1. Scegli uno spinner dalla lista
2. Sostituisci il valore nella variabile
3. Salva il file

**Esempio:**
```bash
GUM_SPINNER_TYPE="dots"
```

### Bordi

I bordi sono usati per i messaggi di inizio/fine e per gli errori.

**Variabili disponibili:**
```bash
GUM_BORDER_ROUNDED="rounded"    # Bordo arrotondato
GUM_BORDER_DOUBLE="double"      # Bordo doppio (usato per inizio/fine)
GUM_BORDER_THICK="thick"        # Bordo spesso (usato per errori)
```

**Tipi disponibili in Gum:**
- `none` - Nessun bordo
- `hidden` - Nascosto
- `normal` - Normale
- `rounded` - Arrotondato
- `thick` - Spesso
- `double` - Doppio

**Come usarli:**
I bordi sono già configurati negli script. Per cambiare quale bordo viene usato dove, cerca nel codice:
- `--border "$GUM_BORDER_DOUBLE"` per messaggi di inizio/fine
- `--border "$GUM_BORDER_THICK"` per messaggi di errore

### Layout e Spaziatura

Controlla padding e margin dei messaggi.

**Variabili disponibili:**
```bash
GUM_PADDING="0 1"           # Verticale Orizzontale
GUM_MARGIN="0"              # Margin attorno ai box
GUM_ERROR_PADDING="0 1"     # Padding specifico per errori
```

**Formato:** `"verticale orizzontale"`
- Primo numero: padding/margin sopra e sotto
- Secondo numero: padding/margin sinistra e destra

**Esempio:** Per più spazio attorno ai messaggi:
```bash
GUM_PADDING="1 2"  # 1 riga sopra/sotto, 2 spazi sinistra/destra
```

### Testare le modifiche

Dopo aver modificato le variabili:

1. **Per brew-setup.sh:**
   ```bash
   ./brew-setup.sh
   ```

2. **Per brew-update.sh:**
   - Copia in ~/Shell/:
     ```bash
     cp brew-update.sh ~/Shell/brew-update.sh
     ```
   - Esegui:
     ```bash
     brew-update
     ```

### Reference e Documentazione

**Gum (tool per UI):**
- [GitHub Gum](https://github.com/charmbracelet/gum) - Documentazione completa
- [Gum Examples](https://github.com/charmbracelet/gum#examples) - Esempi pratici

**Oh My Posh (temi terminale):**
- [Oh My Posh Themes](https://ohmyposh.dev/docs/themes) - Galleria completa temi
- [Oh My Posh Config](https://ohmyposh.dev/docs/installation/customize) - Customizzazione avanzata

**Homebrew:**
- [Homebrew Documentation](https://docs.brew.sh/) - Documentazione ufficiale
- [Homebrew Cask](https://github.com/Homebrew/homebrew-cask) - Lista applicazioni disponibili

**Colori Terminale:**
- [256 Colors Cheat Sheet](https://www.ditig.com/256-colors-cheat-sheet) - Reference completa
- [Terminal Colors](https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html) - Guida tecnica

**Shell Scripting:**
- [Zsh Guide](https://zsh.sourceforge.io/Guide/) - Guida completa Zsh
- [Bash Scripting](https://www.gnu.org/software/bash/manual/) - Reference Bash

### Struttura Codice

Entrambi gli script seguono questo pattern:

```bash
#!/bin/zsh

# 1. Configurazione variabili UI (colori, simboli, spinner, bordi)
GUM_COLOR_SUCCESS="10"
...

# 2. Messaggio iniziale con bordo
echo ""
gum style --border "$GUM_BORDER_DOUBLE" ... "Script - Inizio 🚀"
echo ""

# 3. Operazioni con pattern: spinner → check verde/rosso
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Descrizione..." -- sh -c "comando &>/dev/null"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Operazione completata"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore"
fi

# 4. Messaggio finale con bordo
echo ""
gum style --border "$GUM_BORDER_DOUBLE" ... "Script - Completato 🎉"
echo ""
```

**Punti chiave:**
- Tutti i comandi brew devono usare `sh -c "comando &>/dev/null"` per nascondere correttamente l'output
- `$?` cattura l'exit code del comando precedente
- `gum style` formatta e colora il testo
- `gum spin` mostra lo spinner animato
- `gum choose` crea menu interattivi con checkbox

### Aggiungere Nuove Applicazioni

Per aggiungere app alla lista in `brew-setup.sh`:

1. Trova il nome del cask Homebrew:
   ```bash
   brew search nome-app
   ```

2. Aggiungi alla lista (linee 61-73):
   ```bash
   selected_apps=$(gum choose --no-limit --height 15 \
       --header="Seleziona le applicazioni da installare:" \
       ...
       "nome-nuova-app" \
       "whatsapp")
   ```

3. Aggiorna anche il README nella tabella applicazioni

### Aggiungere Nuove Operazioni

Per aggiungere operazioni a `brew-update.sh`:

1. Aggiungi alla lista di selezione (linee 48-53)
2. Aggiungi variabile booleana (dopo linea 61)
3. Aggiungi case nel while loop (dopo linea 70)
4. Aggiungi sezione con pattern spinner → check

**Esempio:**
```bash
# Nella lista
"Nuova operazione" \

# Variabile
do_nuova_operazione=false

# Case
"Nuova operazione") do_nuova_operazione=true ;;

# Esecuzione
if [ "$do_nuova_operazione" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Esecuzione nuova operazione..." -- sh -c "comando &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Operazione completata"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore operazione"
    fi
fi
```

---

## Licenza e Contributi

Questo progetto è open source. Sentiti libero di modificarlo e migliorarlo come preferisci.

Se hai suggerimenti o trovi bug, apri una issue su GitHub.
