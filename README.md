# Homebrew Management Tools

Script per installare e mantenere aggiornato il tuo Mac con Homebrew in modo semplice e automatico.

## Cosa fa questo tool

Questo progetto ti permette di:

1. **Installare Homebrew** (se non ce l'hai già)
2. **Scegliere quali applicazioni e font installare** tramite menu interattivi con checkbox
3. **Personalizzare il tema del terminale** scegliendo tra 4 temi disponibili
4. **Avere l'autocompletamento del terminale** già attivo (suggerimenti in tempo reale)
5. **Aggiornare Homebrew automaticamente in background**, oppure manualmente con un comando

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
chmod +x setup.sh
```

### Passo 4: Avvia l'installazione

Copia e incolla questo comando:

```bash
./setup.sh
```

### Passo 5: Segui le istruzioni

Lo script ti mostrerà:

1. **Installazione automatica di Homebrew** (se non ce l'hai già)
    - Vedrai uno spinner mentre installa

2. **Installazione strumenti base**
    - Node.js, GitHub CLI, Oh My Posh, Gum
    - Vedrai uno spinner e poi un check verde ✔︎

3. **Scelta applicazioni**
    - Ti appare una lista con checkbox (□ vuoto, ■ pieno)
    - Usa le **frecce** per muoverti
    - Premi **Spazio** per selezionare/deselezionare
    - Premi **Invio** quando hai finito

4. **Scelta font**
    - Stessa logica delle applicazioni
    - I Nerd Font servono per i temi del terminale

5. **Scelta tema terminale**
    - 4 temi tra cui scegliere (consigliato: zash)
    - Usa le **frecce** e premi **Invio**

6. **Aggiornamento automatico** (opzionale)
    - Ti viene chiesto se abilitare l'aggiornamento automatico di Homebrew in background
    - Se accetti: scegli l'**intervallo** (una volta a settimana o al giorno) e le **opzioni** (aggiorna pacchetti e app, pulizia cache, ecc.)

7. **Installazione automatica**
    - Font e applicazioni che hai selezionato
    - Autocompletamento del terminale (sempre incluso) e aggiornamento automatico se l'hai scelto
    - Vedrai gli spinner e poi i check verdi ✔︎

8. **Messaggio finale**
    - "Homebrew Setup → Completato 🎉"
    - **Chiudi e riapri il terminale** per vedere le modifiche

---

## Come Aggiornare il Sistema

Dopo l'installazione iniziale hai due modi per tenere tutto aggiornato.

### Aggiornamento automatico (in background)

Se durante il setup hai abilitato l'**aggiornamento automatico**, Homebrew si aggiorna da solo in background all'intervallo che hai scelto, senza che tu debba fare nulla. Per controllarlo o gestirlo:

```bash
brew autoupdate status   # stato e prossima esecuzione
brew autoupdate stop     # mette in pausa
brew autoupdate start    # riattiva
```

> Le app che richiedono privilegi di amministratore mostreranno un prompt password grafico (gestito da `pinentry-mac`), così l'aggiornamento può completarsi anche in background.

### Aggiornamento manuale

Puoi comunque aggiornare quando vuoi con un comando. Apri il terminale e scrivi:

```bash
brew-update
```

### Cosa succede

1. **Menu di selezione**
    - Ti appare una lista con tutte le operazioni pre-selezionate (■)
    - Puoi deselezionare (□) quelle che non vuoi eseguire
    - Premi **Invio** per continuare

2. **Esecuzione operazioni**
    - Vedrai uno spinner per ogni operazione
    - Quando finisce, lo spinner diventa un check verde ✔︎
    - Se c'è un errore, vedi un croce rossa ✘

3. **Output diagnostica**
    - Se hai selezionato "Diagnostica sistema"
    - Vedrai l'output completo di brew doctor

4. **Messaggio finale**
    - "Homebrew Update → Completato 🎉"

---

## Applicazioni Disponibili

Durante il setup puoi scegliere quali installare:

| Applicazione       | Descrizione                   |
| ------------------ | ----------------------------- |
| 1Password          | Password manager              |
| AppCleaner         | Disinstallazione completa app |
| Claude Code        | Agente AI da terminale (Anthropic) |
| Codex              | Agente AI da terminale (OpenAI) |
| Dropbox            | Cloud storage                 |
| Figma              | Design e prototipazione       |
| Google Chrome      | Browser web                   |
| ImageOptim         | Ottimizzazione immagini       |
| Mole               | Pulizia e ottimizzazione del Mac |
| Numi               | Calcolatrice intelligente     |
| Rectangle          | Window manager                |
| Spotify            | Streaming musicale            |
| Visual Studio Code | Editor di codice              |
| Wailbrew           | GUI per Homebrew              |
| WhatsApp           | Messaggistica                 |

**Nota**: Puoi selezionare solo quelle che ti servono, non sei obbligato a installarle tutte.

---

## Font Disponibili

Durante il setup puoi scegliere quali font installare:

| Font                      | Descrizione                              |
| ------------------------- | ---------------------------------------- |
| Meslo LG Nerd Font        | Font monospaced con icone e simboli      |
| Roboto Mono Nerd Font     | Font monospaced ispirato a Roboto        |
| Space Mono Nerd Font      | Font monospaced geometrico e moderno     |

**Nota**: I Nerd Font includono icone speciali necessarie per i temi del terminale (Oh My Posh).

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

## Autocompletamento del terminale

Il setup attiva l'**autocompletamento** del terminale (zsh-autocomplete): mentre digiti vedrai comparire in tempo reale i suggerimenti (comandi, file, opzioni). Usa le **frecce** per navigarli e **Invio**/**Tab** per accettarli.

Per disabilitarlo: apri `~/.zshrc`, rimuovi la riga che inizia con `source ...zsh-autocomplete...` e riavvia il terminale.

---

## Risoluzione Problemi

### "Permission denied" quando eseguo ./setup.sh

Hai dimenticato il Passo 3. Esegui:

```bash
chmod +x setup.sh
```

### "Command not found: brew-update"

Hai chiuso e riaperto il terminale dopo l'installazione? È necessario per caricare le nuove configurazioni.

### Le applicazioni non si installano

Alcune applicazioni potrebbero richiedere conferme manuali o avere problemi di compatibilità con la tua versione di macOS. Lo script continua comunque con le altre.

### Voglio reinstallare tutto

Puoi rieseguire `./setup.sh` senza problemi. Lo script rileva cosa è già installato e salta quei passaggi.

---

## Per Sviluppatori

Per la documentazione tecnica (architettura, comandi, test) consulta [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). Il punto d'ingresso di tutta la documentazione è [AGENTS.md](AGENTS.md).

### Quick Reference

**Aggiungere app/font:** `brew search nome`, poi aggiungi label e cask agli array `APP_LABELS`/`APP_CASKS` (o `FONT_LABELS`/`FONT_CASKS`) in testata di `setup.sh`

**Testare modifiche:**
```bash
./setup.sh                                                # Setup
cp update.sh ~/.brew/update.sh && brew-update             # Update
```

**Rigenerare i cataloghi (Donkey 2.0):** i cataloghi font e temi sono generati dalle sorgenti ufficiali (Homebrew / Oh My Posh) e committati nel repo. Non si scrivono a mano — si rigenerano con:
```bash
make update-fonts      # config/fonts.list — tutti i Nerd Font (da Homebrew)
make update-themes     # config/themes.list — tutti i temi Oh My Posh (da GitHub)
```

**Link utili:** [Gum](https://github.com/charmbracelet/gum) · [Oh My Posh](https://ohmyposh.dev/docs/themes) · [Homebrew](https://docs.brew.sh/)

---

## Contributi

Suggerimenti e bug reports: apri una issue su GitHub.
