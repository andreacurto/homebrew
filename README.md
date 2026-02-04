# Homebrew Management Tools

Tool per automatizzare l'installazione e l'aggiornamento di pacchetti tramite Homebrew su macOS con **interfaccia interattiva moderna**.

## Caratteristiche

✨ **Interfaccia Interattiva**
- Checkbox e menu di selezione con navigazione da tastiera
- Spinner animati durante le operazioni
- Messaggi colorati e formattati per migliore leggibilità
- Gestione errori non-blocking (continua anche in caso di problemi)

🎯 **Selezione Personalizzata**
- Scegli quali applicazioni installare
- Scegli il tema della shell durante il setup
- Seleziona quali operazioni di manutenzione eseguire

⚡ **Automazione Completa**
- Setup iniziale con un solo comando
- Aggiornamenti selettivi e veloci
- Pulizia automatica del sistema

---

## Indice

1. [Setup Iniziale](#setup-iniziale)
2. [Aggiornamento del Sistema](#aggiornamento-del-sistema)
3. [Personalizzazione](#personalizzazione)
   1. [Temi Shell](#temi-shell)
4. [Pacchetti Installati](#pacchetti-installati)
   1. [Strumenti CLI](#strumenti-cli)
   2. [Font](#font)
   3. [Applicazioni](#applicazioni)

## Setup Iniziale

1. Scarica questa cartella sul tuo Mac
2. Apri il terminale e naviga nella cartella scaricata
3. Rendi eseguibile lo script di setup:

    ```bash
    chmod +x brew-setup.sh
    ```

4. Esegui lo script di setup:

    ```bash
    ./brew-setup.sh
    ```

Lo script ti guiderà attraverso un'**installazione interattiva**:

1. **Installazione automatica** di Homebrew (se non presente)
2. **Installazione pacchetti essenziali** (Node.js, GitHub CLI, Oh My Posh, Gum)
3. **Selezione applicazioni**: Scegli quali app installare tramite checkbox interattive
4. **Selezione tema shell**: Scegli il tema Oh My Posh che preferisci
5. **Installazione font** e applicazioni selezionate
6. **Configurazione automatica** degli script di aggiornamento

Durante il processo vedrai:
- ✓ Messaggi di successo in verde
- ⚠ Warning in giallo (l'installazione continua)
- Spinner animati durante le operazioni lunghe

Al termine, **riavvia il terminale** per applicare le modifiche.

## Aggiornamento del Sistema

Una volta completato il setup, puoi aggiornare il sistema usando l'alias da terminale:

```bash
brew-update
```

Lo script ti permetterà di **selezionare le operazioni** da eseguire tramite checkbox interattive:

- ✅ Aggiorna applicazioni (con opzione --greedy per app con auto-update)
- ✅ Aggiorna repository Homebrew
- ✅ Aggiorna formule (pacchetti CLI)
- ✅ Rimuovi dipendenze orfane
- ✅ Pulizia cache e file obsoleti
- ✅ Diagnostica sistema (brew doctor)

Tutte le operazioni sono **pre-selezionate di default**. Puoi deselezionare quelle che non vuoi eseguire usando la barra spaziatrice.

Durante l'esecuzione vedrai:
- Spinner animati per ogni operazione
- Messaggi di completamento o errori
- Output nascosto per una visualizzazione pulita

## Personalizzazione

### Temi Shell

Il tema viene **selezionato interattivamente durante il setup** iniziale. Temi disponibili:

- **zash** (default) - Minimal e pulito
- **material** - Ispirato a Material Design
- **robbyrussell** - Classico tema Oh My Zsh
- **pararussel** - Variante di robbyrussell

Se vuoi cambiare tema successivamente, modifica il file `~/.zshrc` manualmente:

```bash
# Cambia "zash" con il tema desiderato
eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/NOME_TEMA.omp.json)"
```

Poi riavvia il terminale.

## Pacchetti Installati

### Strumenti CLI

- **Node.js** - Runtime JavaScript
- **GitHub CLI** (`gh`) - Gestione GitHub da terminale
- **Oh My Posh** - Personalizzazione prompt shell
- **Gum** - Tool per creare interfacce interattive nel terminale

### Font

- Meslo LG Nerd Font
- Roboto Mono Nerd Font

### Applicazioni

Le seguenti applicazioni sono **disponibili per l'installazione** (selezionabili durante il setup):

- **1Password** - Password manager
- **AppCleaner** - Disinstallazione completa applicazioni
- **Claude Code** - Editor AI-powered
- **Dropbox** - Cloud storage
- **Figma** - Design e prototipazione
- **Google Chrome** - Browser web
- **ImageOptim** - Ottimizzazione immagini
- **Numi** - Calcolatrice intelligente
- **Rectangle** - Window manager
- **Spotify** - Streaming musicale
- **Visual Studio Code** - Editor di codice
- **WailBrew** - GUI per Homebrew
- **WhatsApp** - Messaggistica

Durante il setup puoi **selezionare solo le app che ti servono** usando le checkbox interattive.
