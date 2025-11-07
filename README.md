# Homebrew Management Tools

Tool per automatizzare l'installazione e l'aggiornamento di pacchetti tramite Homebrew su macOS.

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

Lo script eseguirà automaticamente:

-   Installazione di Homebrew (se non presente)
-   Installazione dei pacchetti essenziali
-   Configurazione degli script di aggiornamento
-   Setup della shell

Al termine, **riavvia il terminale** per applicare le modifiche.

## Aggiornamento del Sistema

Una volta completato il setup, puoi aggiornare il sistema usando l'alias da terminale:

```bash
brew-update
```

Lo script si occuperà di:

-   Aggiornare le applicazioni
-   Aggiornare i pacchetti Homebrew
-   Pulire i file non necessari
-   Verificare lo stato del sistema

## Personalizzazione

### Temi Shell

Per cambiare il tema del terminale, modifica il file `~/.zshrc` e scegli uno dei temi commentati:

-   material
-   robbyrussell
-   pararussel
-   zash (default)

## Pacchetti Installati

### Strumenti CLI

-   Node.js
-   GitHub CLI
-   Oh My posh (personalizzazione Shell)

### Font

-   Meslo LG Nerd Font
-   Roboto Mono Nerd Font

### Applicazioni

-   1password
-   AppCleaner
-   Dropbox
-   Figma
-   Google Chrome
-   ImageOptim
-   Numi
-   Rectangle
-   Spotify
-   Visual Studio Code
-   WhatsApp
