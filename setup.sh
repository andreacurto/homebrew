#!/bin/zsh
#
# Homebrew Setup Script
# Script di installazione iniziale di Homebrew con interfaccia interattiva
#
# Funzionalità:
# - Installa Homebrew se non presente
# - Installa strumenti CLI essenziali (node, gh, oh-my-posh, gum)
# - Permette selezione interattiva applicazioni e font da installare
# - Configura tema Oh My Posh per il terminale
# - Setup script di aggiornamento automatico

# ===== COLORI ANSI =====
MUTED="\033[38;5;244m"
RED="\033[38;5;9m"
RESET="\033[0m"

# ===== LISTE INSTALLAZIONE =====
# Label (visualizzata) e cask (pacchetto Homebrew) devono avere lo stesso ordine

APP_LABELS=(
    "1Password"
    "AppCleaner"
    "Claude Code"
    "Dropbox"
    "Figma"
    "Google Chrome"
    "ImageOptim"
    "Mole"
    "Numi"
    "Rectangle"
    "Spotify"
    "Visual Studio Code"
    "Wailbrew"
    "WhatsApp"
)
APP_CASKS=(
    "1password"
    "appcleaner"
    "claude-code"
    "dropbox"
    "figma"
    "google-chrome"
    "imageoptim"
    "mole"
    "numi"
    "rectangle"
    "spotify"
    "visual-studio-code"
    "wailbrew"
    "whatsapp"
)

FONT_LABELS=(
    "Meslo LG Nerd Font"
    "Roboto Mono Nerd Font"
    "Space Mono Nerd Font"
)
FONT_CASKS=(
    "font-meslo-lg-nerd-font"
    "font-roboto-mono-nerd-font"
    "font-space-mono-nerd-font"
)

THEME_LABELS=(
    "Zash"
    "Material"
    "Robby Russell"
    "ParaRussel"
)
THEME_FILES=(
    "zash"
    "material"
    "robbyrussell"
    "pararussel"
)

# Cartella installazione script
INSTALL_DIR="$HOME/.brew"

# ===== MESSAGGIO INIZIALE E CONFERMA =====
echo ""
printf "%b\n" "${MUTED}╭──────────────────────────────╮${RESET}"
printf "%b\n" "${MUTED}│${RESET}  Homebrew Setup → Inizio 🚀  ${MUTED}│${RESET}"
printf "%b\n" "${MUTED}╰──────────────────────────────╯${RESET}"
echo ""
echo "Questo script installerà:"
echo ""
printf "%b\n" "${MUTED}→ Homebrew (package manager per macOS)${RESET}"
printf "%b\n" "${MUTED}→ Strumenti e librerie (node, gh, oh-my-posh, gum)${RESET}"
printf "%b\n" "${MUTED}→ Applicazioni a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Font per terminale a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Tema terminale a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Script di aggiornamento${RESET}"
echo ""
echo "Premi Invio per continuare o Ctrl+C per annullare..."
read -r

# ===== TEST CONNESSIONE INTERNET =====
if ! curl --head --silent --fail --max-time 3 https://www.google.com > /dev/null 2>&1; then
    echo ""
    printf "%b\n" "${RED}✘ Connessione internet assente.${RESET}"
    printf "%b\n" "${MUTED}Lo script richiede una connessione internet attiva per funzionare.${RESET}"
    echo ""
    exit 1
fi

# ===== VERIFICA PRELIMINARE =====
printf "%b\n" "${MUTED}⌛ Verifica preliminare in corso, non chiudere il terminale...${RESET}"

# ===== INSTALLAZIONE SILENZIOSA HOMEBREW =====
HOMEBREW_ALREADY_INSTALLED=false
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew &> /dev/null; then
        printf "%b\n" "${RED}✘ Errore installazione Homebrew${RESET}"
        exit 1
    fi
else
    HOMEBREW_ALREADY_INSTALLED=true
fi

# ===== INSTALLAZIONE SILENZIOSA GUM =====
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
    if ! command -v gum &> /dev/null; then
        printf "%b\n" "${RED}✘ Errore installazione gum${RESET}"
        exit 1
    fi
fi

# Cancella il messaggio di verifica preliminare
printf "\033[1A\033[2K\033[1A\033[2K"

# ===== CONFIGURAZIONE UI =====
# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"
GUM_COLOR_ERROR="9"
GUM_COLOR_WARNING="11"
GUM_COLOR_INFO="14"
GUM_COLOR_MUTED="244"

# Simboli
GUM_SYMBOL_SUCCESS="✔︎"
GUM_SYMBOL_ERROR="✘"
GUM_SYMBOL_WARNING="❖"
GUM_SYMBOL_INFO="❋"

# Checkbox
GUM_CHECKBOX_SELECTED="■"
GUM_CHECKBOX_UNSELECTED="□"
GUM_CHECKBOX_CURSOR="□"

# Spinner e layout
GUM_SPINNER_TYPE="monkey"
GUM_BORDER_ROUNDED="rounded"
GUM_PADDING="0 1"
GUM_MARGIN="0"

# ===== SELEZIONE APPLICAZIONI =====
selected_apps=""
if [ ${#APP_LABELS[@]} -gt 0 ]; then
    selected_apps=$(gum choose --no-limit --height 15 \
        --header="Seleziona le applicazioni da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${APP_LABELS[@]}")
fi

# Converti label selezionate in nomi cask
typeset -A app_to_cask
for i in {1..${#APP_LABELS[@]}}; do
    app_to_cask[${APP_LABELS[$i]}]=${APP_CASKS[$i]}
done
selected_apps_array=()
while IFS= read -r label; do
    [[ -n "$label" ]] && selected_apps_array+=("${app_to_cask[$label]}")
done <<< "$selected_apps"

# ===== SELEZIONE FONT =====
selected_fonts=""
if [ ${#FONT_LABELS[@]} -gt 0 ]; then
    selected_fonts=$(gum choose --no-limit \
        --header="Seleziona i font da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${FONT_LABELS[@]}")
fi

# Converti label selezionate in nomi cask
typeset -A font_to_cask
for i in {1..${#FONT_LABELS[@]}}; do
    font_to_cask[${FONT_LABELS[$i]}]=${FONT_CASKS[$i]}
done
selected_fonts_array=()
while IFS= read -r label; do
    [[ -n "$label" ]] && selected_fonts_array+=("${font_to_cask[$label]}")
done <<< "$selected_fonts"

# ===== SELEZIONE TEMA OH MY POSH =====
selected_theme_label=$(gum choose \
    --header="Seleziona il tema per terminale (Oh My Posh):" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
    --selected="Zash" \
    "${THEME_LABELS[@]}" \
    "Continua senza tema")

# Converti label in nome file tema
typeset -A theme_to_file
for i in {1..${#THEME_LABELS[@]}}; do
    theme_to_file[${THEME_LABELS[$i]}]=${THEME_FILES[$i]}
done
selected_theme="${theme_to_file[$selected_theme_label]}"

# ===== INSTALLAZIONI =====
if [ "$HOMEBREW_ALREADY_INSTALLED" = true ]; then
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Homebrew già installato"
else
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato"
fi

# ===== INSTALLAZIONE STRUMENTI E LIBRERIE =====
CLI_ALREADY_INSTALLED=false
if command -v node &> /dev/null && command -v gh &> /dev/null && command -v oh-my-posh &> /dev/null; then
    CLI_ALREADY_INSTALLED=true
fi

if [ "$CLI_ALREADY_INSTALLED" = true ]; then
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Strumenti e librerie già installati"
else
    echo "Installazione strumenti e librerie in corso..."
    echo ""
    (brew install node gh && brew install --cask jandedobbeleer/oh-my-posh/oh-my-posh) 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
        if [[ "$line" == "Password:"* ]]; then
            echo "$line"
            echo ""
        else
            gum style --foreground "$GUM_COLOR_MUTED" "  $line"
        fi
    done
    echo ""
    if [ ${pipestatus[1]} -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie installati"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile installare strumenti e librerie"
    fi
fi

# ===== INSTALLAZIONE APPLICAZIONI =====
if [ ${#selected_apps_array[@]} -gt 0 ]; then
    apps_to_install=()
    for app in "${selected_apps_array[@]}"; do
        if ! brew list --cask "$app" &> /dev/null; then
            apps_to_install+=("$app")
        fi
    done

    if [ ${#apps_to_install[@]} -gt 0 ]; then
        echo "Installazione applicazioni in corso..."
        echo ""
        brew install --cask ${apps_to_install[*]} 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
            if [[ "$line" == "Password:"* ]]; then
                echo "$line"
                echo ""
            else
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            fi
        done
        echo ""
        if [ ${pipestatus[1]} -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni installate"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile installare applicazioni"
        fi
    else
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Applicazioni già installate"
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessuna applicazione selezionata"
fi

# ===== INSTALLAZIONE FONT PER TERMINALE =====
if [ ${#selected_fonts_array[@]} -gt 0 ]; then
    fonts_to_install=()
    for font in "${selected_fonts_array[@]}"; do
        if ! brew list --cask "$font" &> /dev/null; then
            fonts_to_install+=("$font")
        fi
    done

    if [ ${#fonts_to_install[@]} -gt 0 ]; then
        echo "Installazione font per terminale in corso..."
        echo ""
        brew install --cask --force ${fonts_to_install[*]} 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
            if [[ "$line" == "Password:"* ]]; then
                echo "$line"
                echo ""
            else
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            fi
        done
        echo ""
        if [ ${pipestatus[1]} -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Font per terminale installati"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile installare font per terminale"
        fi
    else
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Font per terminale già installati"
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun font selezionato"
fi

# ===== SETUP SCRIPT DI AGGIORNAMENTO =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione script aggiornamento..." -- sh -c "mkdir -p '$INSTALL_DIR' && cp '$SCRIPT_DIR/update.sh' '$INSTALL_DIR/update.sh' && chmod +x '$INSTALL_DIR/update.sh'"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script aggiornamento configurato"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile configurare script aggiornamento"
fi

# ===== CONFIGURAZIONE SHELL =====
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
fi

if [ -z "$selected_theme" ]; then
    cat > ~/.zshrc << EOF
# Alias
alias brew-update='zsh $INSTALL_DIR/update.sh'
EOF
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun tema selezionato"
else
    cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='zsh $INSTALL_DIR/update.sh'
EOF
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato ($selected_theme_label)"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Setup → Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Esegui il comando 'source ~/.zshrc' o riavvia il terminale per applicare le modifiche"
gum style --foreground "$GUM_COLOR_MUTED" "Usa da terminale il comando 'brew-update' per aggiornare Homebrew in futuro"
echo ""
