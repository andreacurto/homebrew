#!/bin/zsh
#
# Homebrew Setup Script
# Script di installazione iniziale di Homebrew con interfaccia interattiva
#
# Funzionalità:
# - Installa Homebrew se non presente
# - Installa strumenti CLI essenziali (node, gh, oh-my-posh, gum)
# - Permette selezione interattiva applicazioni da installare
# - Configura tema Oh My Posh per il terminale
# - Setup script di aggiornamento automatico

# ===== COLORI ANSI =====
# Usati prima che gum sia disponibile
MUTED="\033[38;5;244m"
RED="\033[38;5;9m"
RESET="\033[0m"

# ===== MESSAGGIO INIZIALE E CONFERMA =====
# Mostra cosa farà lo script e chiede conferma all'utente
echo ""
echo -e "${MUTED}╭──────────────────────────────╮${RESET}"
echo -e "${MUTED}│${RESET}  Homebrew Setup - Inizio 🚀  ${MUTED}│${RESET}"
echo -e "${MUTED}╰──────────────────────────────╯${RESET}"
echo ""
echo "Questo script installerà:"
echo ""
echo -e "${MUTED}→ Homebrew (package manager per macOS)${RESET}"
echo -e "${MUTED}→ Strumenti CLI (node, gh, oh-my-posh, gum)${RESET}"
echo -e "${MUTED}→ Font 'Nerd Font' per il terminale${RESET}"
echo -e "${MUTED}→ Applicazioni a tua scelta${RESET}"
echo -e "${MUTED}→ Tema personalizzato per il terminale${RESET}"
echo ""
echo "Premi Invio per continuare o Ctrl+C per annullare..."
read -r

# ===== INSTALLAZIONE SILENZIOSA HOMEBREW =====
# Verifica se Homebrew è installato, altrimenti lo installa
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}! Errore installazione Homebrew${RESET}"
        exit 1
    fi
fi

# ===== INSTALLAZIONE SILENZIOSA GUM =====
# Verifica se gum è installato, altrimenti lo installa
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
    if ! command -v gum &> /dev/null; then
        echo -e "${RED}! Errore installazione gum${RESET}"
        exit 1
    fi
fi

# ===== CONFIGURAZIONE UI =====
# Definisce colori, simboli e stili per l'interfaccia Gum

# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"    # Operazioni completate con successo
GUM_COLOR_ERROR="9"       # Messaggi di errore
GUM_COLOR_WARNING="11"    # Warning e operazioni saltate
GUM_COLOR_INFO="14"       # Messaggi informativi durante operazioni
GUM_COLOR_PRIMARY="13"    # Titoli e header principali
GUM_COLOR_MUTED="244"     # Output secondario e testo attenuato

# Simboli
GUM_SYMBOL_SUCCESS="✓"    # Operazioni completate
GUM_SYMBOL_WARNING="!"    # Errori e warning
GUM_SYMBOL_SKIP="❋"       # Operazioni saltate

# Checkbox
GUM_CHECKBOX_SELECTED="■"      # Opzione selezionata nei menu
GUM_CHECKBOX_UNSELECTED="□"    # Opzione non selezionata nei menu
GUM_CHECKBOX_CURSOR="□"        # Indicatore posizione cursore

# Spinner
GUM_SPINNER_TYPE="monkey"      # Tipo animazione durante operazioni

# Bordi
GUM_BORDER_ROUNDED="rounded"   # Stile bordo per box principali
GUM_BORDER_DOUBLE="double"     # Stile bordo alternativo
GUM_BORDER_THICK="thick"       # Stile bordo spesso

# Layout
GUM_PADDING="0 1"              # Spaziatura interna box (verticale orizzontale)
GUM_MARGIN="0"                 # Margine esterno box
GUM_ERROR_PADDING="0 1"        # Spaziatura messaggi di errore

# ===== SELEZIONE APPLICAZIONI =====
# Menu interattivo con checkbox per scegliere quali applicazioni installare
# Usa frecce per navigare, Spazio per selezionare, Invio per confermare
selected_apps=$(gum choose --no-limit --height 15 \
    --header="Seleziona le applicazioni da installare:" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
    "1password" \
    "appcleaner" \
    "claude-code" \
    "dropbox" \
    "figma" \
    "google-chrome" \
    "imageoptim" \
    "numi" \
    "rectangle" \
    "spotify" \
    "visual-studio-code" \
    "wailbrew" \
    "whatsapp")

# Converte l'output multi-linea in array bash/zsh compatible
selected_apps_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_apps_array+=("$line")
done <<< "$selected_apps"

# ===== SELEZIONE TEMA OH MY POSH =====
# Menu per scegliere il tema del prompt del terminale
# Default: zash (minimalista)
selected_theme=$(gum choose \
    --header="Seleziona il tema Oh My Posh:" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel")

# ===== INSTALLAZIONI =====
# Messaggio di conferma dipendenze base
gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato"

# ===== INSTALLAZIONE STRUMENTI CLI =====
# Installa pacchetti essenziali per il funzionamento degli script e dell'ambiente
# - node: Runtime JavaScript
# - gh: GitHub CLI
# - oh-my-posh: Personalizzazione prompt shell
# (gum già installato nella fase iniziale)
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione strumenti CLI (node, gh, oh-my-posh, gum)..." -- sh -c "brew install node gh oh-my-posh &>/dev/null"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti CLI installati"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione strumenti CLI"
fi

# ===== INSTALLAZIONE FONT =====
# Installa font Nerd Font necessari per i temi Oh My Posh
# I Nerd Font includono icone e simboli speciali per il terminale
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione font 'Nerd Font'..." -- sh -c "brew install --cask font-meslo-lg-nerd-font font-roboto-mono-nerd-font &>/dev/null"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Font installati"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione font"
fi

# ===== INSTALLAZIONE APPLICAZIONI =====
# Installa le applicazioni selezionate dall'utente tramite Homebrew Cask
# Se nessuna app selezionata, salta questa fase
if [ ${#selected_apps_array[@]} -gt 0 ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione applicazioni selezionate..." -- sh -c "brew install --cask ${selected_apps_array[*]} &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni installate"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione applicazioni"
    fi
else
    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_SKIP Nessuna applicazione selezionata"
fi

# ===== SETUP SCRIPT DI AGGIORNAMENTO =====
# Copia brew-update.sh in ~/Shell/ per poterlo eseguire con alias brew-update
# Crea la directory ~/Shell/ se non esiste
SCRIPT_DIR=$(dirname "$0")
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione script di aggiornamento..." -- sh -c "mkdir -p ~/Shell && cp '$SCRIPT_DIR/brew-update.sh' ~/Shell/brew-update.sh && chmod +x ~/Shell/brew-update.sh"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script di aggiornamento configurato"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore configurazione script di aggiornamento"
fi

# ===== CONFIGURAZIONE SHELL =====
# Crea/sovrascrive ~/.zshrc con configurazione Oh My Posh e alias
# Backup automatico del file esistente in ~/.zshrc.bak
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
fi

cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='zsh ~/Shell/brew-update.sh'
EOF

gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Terminale configurato con tema '$selected_theme'"

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Setup - Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Riavvia il terminale per applicare le modifiche"
echo ""
