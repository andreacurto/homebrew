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

# ===== CONFIGURAZIONE UI =====
# Definisce colori, simboli e stili per l'interfaccia Gum

# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"    # Verde per operazioni completate
GUM_COLOR_ERROR="9"       # Rosso per errori
GUM_COLOR_WARNING="11"    # Giallo per warning
GUM_COLOR_INFO="14"       # Cyan per informazioni
GUM_COLOR_PRIMARY="13"    # Magenta per titoli
GUM_COLOR_MUTED="244"     # Grigio per testo secondario

# Simboli
GUM_SYMBOL_SUCCESS="✓"    # Check per successo
GUM_SYMBOL_WARNING="!"    # Punto esclamativo per errori
GUM_SYMBOL_SKIP="○"       # Cerchio per operazioni saltate

# Checkbox (per menu di selezione)
GUM_CHECKBOX_SELECTED="■"      # Checkbox selezionata
GUM_CHECKBOX_UNSELECTED="□"    # Checkbox non selezionata
GUM_CHECKBOX_CURSOR="›"        # Cursore di selezione

# Spinner (animazione durante operazioni lunghe)
GUM_SPINNER_TYPE="monkey"

# Bordi (per box messaggi)
GUM_BORDER_ROUNDED="rounded"
GUM_BORDER_DOUBLE="double"
GUM_BORDER_THICK="thick"

# Layout (spaziatura box)
GUM_PADDING="0 1"
GUM_MARGIN="0"
GUM_ERROR_PADDING="0 1"

# ===== MESSAGGIO INIZIALE =====
echo ""
gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_PRIMARY" --bold "Homebrew Setup - Inizio 🚀"
echo ""

# ===== INSTALLAZIONE HOMEBREW =====
# Verifica se Homebrew è installato, altrimenti lo installa
# Homebrew è il package manager per macOS necessario per tutto il resto
if ! command -v brew &> /dev/null; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione Homebrew..." -- /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if command -v brew &> /dev/null; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore installazione Homebrew"
        exit 1
    fi
else
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew già installato"
fi

# ===== INSTALLAZIONE STRUMENTI CLI =====
# Installa pacchetti essenziali per il funzionamento degli script e dell'ambiente
# - node: Runtime JavaScript
# - gh: GitHub CLI
# - oh-my-posh: Personalizzazione prompt shell
# - gum: Tool per interfacce interattive nel terminale
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione strumenti CLI (node, gh, oh-my-posh, gum)..." -- sh -c "brew install node gh oh-my-posh gum &>/dev/null"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti CLI installati"
else
    gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore installazione CLI tools"
fi

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

# ===== INSTALLAZIONE FONT =====
# Installa font Nerd Font necessari per i temi Oh My Posh
# I Nerd Font includono icone e simboli speciali per il terminale
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione font Nerd Font..." -- sh -c "brew install --cask font-meslo-lg-nerd-font font-roboto-mono-nerd-font &>/dev/null"
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
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore installazione applicazioni"
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
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore configurazione script"
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

gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Shell configurata con tema: $selected_theme"

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_SUCCESS" --bold "Homebrew Setup - Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "⚠ Riavvia il terminale per applicare le modifiche"
echo ""
