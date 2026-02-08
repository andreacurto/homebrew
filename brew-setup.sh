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

# ===== MODALITÀ TEST =====
TEST_MODE=false
[[ "$1" == "--test" ]] && TEST_MODE=true

# ===== LISTE INSTALLAZIONE =====
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

FONT_LIST=(
    "font-meslo-lg-nerd-font"
    "font-roboto-mono-nerd-font"
)

# ===== MESSAGGIO INIZIALE E CONFERMA =====
echo ""
echo -e "${MUTED}╭──────────────────────────────╮${RESET}"
echo -e "${MUTED}│${RESET}  Homebrew Setup → Inizio 🚀  ${MUTED}│${RESET}"
echo -e "${MUTED}╰──────────────────────────────╯${RESET}"
echo ""
echo "Questo script installerà:"
echo ""
echo -e "${MUTED}  → Homebrew (package manager per macOS)${RESET}"
echo -e "${MUTED}  → Strumenti e librerie (node, gh, oh-my-posh, gum)${RESET}"
echo -e "${MUTED}  → Applicazioni a tua scelta${RESET}"
echo -e "${MUTED}  → Font per terminale a tua scelta${RESET}"
echo -e "${MUTED}  → Tema terminale a tua scelta${RESET}"
echo -e "${MUTED}  → Script di aggiornamento (percorso a tua scelta)${RESET}"
echo ""
echo "Premi Invio per continuare o Ctrl+C per annullare..."
read -r

# ===== TEST CONNESSIONE INTERNET =====
if [ "$TEST_MODE" = false ]; then
    if ! curl --head --silent --fail --max-time 3 https://www.google.com > /dev/null 2>&1; then
        echo ""
        echo -e "${RED}✘ Connessione internet assente.${RESET}"
        echo -e "${MUTED}Lo script richiede una connessione internet attiva per funzionare.${RESET}"
        echo ""
        exit 1
    fi
fi

# ===== VERIFICA PRELIMINARE =====
echo -e "${MUTED}⌛ Verifica preliminare in corso, non chiudere il terminale...${RESET}"

# ===== INSTALLAZIONE SILENZIOSA HOMEBREW =====
HOMEBREW_ALREADY_INSTALLED=false
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}✘ Errore installazione Homebrew${RESET}"
        exit 1
    fi
else
    HOMEBREW_ALREADY_INSTALLED=true
fi

# ===== INSTALLAZIONE SILENZIOSA GUM =====
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
    if ! command -v gum &> /dev/null; then
        echo -e "${RED}✘ Errore installazione gum${RESET}"
        exit 1
    fi
fi

# Cancella il messaggio di verifica preliminare
echo -e "\033[1A\033[2K\033[1A\033[2K"

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

if [ "$TEST_MODE" = true ]; then
    echo ""
    gum style --bold "⚠️  MODALITÀ TEST - Dati simulati, nessuna modifica reale al sistema"
    echo ""
fi

# ===== SELEZIONE APPLICAZIONI =====
selected_apps=""
if [ ${#APP_LIST[@]} -gt 0 ]; then
    selected_apps=$(gum choose --no-limit --height 15 \
        --header="Seleziona le applicazioni da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${APP_LIST[@]}")
fi

selected_apps_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_apps_array+=("$line")
done <<< "$selected_apps"

# ===== SELEZIONE FONT =====
selected_fonts=""
if [ ${#FONT_LIST[@]} -gt 0 ]; then
    selected_fonts=$(gum choose --no-limit \
        --header="Seleziona i font da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${FONT_LIST[@]}")
fi

selected_fonts_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_fonts_array+=("$line")
done <<< "$selected_fonts"

# ===== SELEZIONE TEMA OH MY POSH =====
selected_theme=$(gum choose \
    --header="Seleziona il tema per terminale (Oh My Posh):" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel" \
    "Continua senza tema")

# ===== CARTELLA INSTALLAZIONE SCRIPT =====
install_dir=$(gum input \
    --header="Dove installare lo script di aggiornamento?" \
    --value="$HOME/Shell")
[[ -z "$install_dir" ]] && install_dir="$HOME/Shell"
install_dir="${install_dir/#\~/$HOME}"

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

    if [ "$TEST_MODE" = true ]; then
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        for tool in "node" "gh" "oh-my-posh"; do
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Downloading $tool"
            sleep 0.3
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Installing $tool"
            sleep 0.5
        done
        echo ""
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie installati"
    else
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
fi

# ===== INSTALLAZIONE APPLICAZIONI =====
if [ ${#selected_apps_array[@]} -gt 0 ]; then
    if [ "$TEST_MODE" = true ]; then
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        echo "Installazione applicazioni in corso..."
        echo ""
        for app in "${selected_apps_array[@]}"; do
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Downloading $app"
            sleep 0.4
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Installing $app"
            sleep 0.6
        done
        echo ""
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni installate"
    else
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
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessuna applicazione selezionata"
fi

# ===== INSTALLAZIONE FONT PER TERMINALE =====
if [ ${#selected_fonts_array[@]} -gt 0 ]; then
    if [ "$TEST_MODE" = true ]; then
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        echo "Installazione font per terminale in corso..."
        echo ""
        for font in "${selected_fonts_array[@]}"; do
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Downloading $font"
            sleep 0.3
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Installing $font"
            sleep 0.4
        done
        echo ""
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Font per terminale installati"
    else
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
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun font selezionato"
fi

# ===== SETUP SCRIPT DI AGGIORNAMENTO =====
if [ "$TEST_MODE" = true ]; then
    sleep 0.5
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script aggiornamento configurato"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione script aggiornamento..." -- sh -c "mkdir -p '$install_dir' && cp '$SCRIPT_DIR/brew-update.sh' '$install_dir/brew-update.sh' && chmod +x '$install_dir/brew-update.sh'"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script aggiornamento configurato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile configurare script aggiornamento"
    fi
fi

# ===== CONFIGURAZIONE SHELL =====
if [ "$TEST_MODE" = true ]; then
    sleep 0.3
    if [ "$selected_theme" = "Continua senza tema" ] || [ -z "$selected_theme" ]; then
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun tema selezionato"
    else
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato ($selected_theme)"
    fi
else
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.bak
    fi

    if [ "$selected_theme" = "Continua senza tema" ] || [ -z "$selected_theme" ]; then
        cat > ~/.zshrc << EOF
# Alias
alias brew-update='zsh $install_dir/brew-update.sh'
EOF
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun tema selezionato"
    else
        cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='zsh $install_dir/brew-update.sh'
EOF
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato ($selected_theme)"
    fi
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Setup → Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Esegui il comando 'source ~/.zshrc' o riavvia il terminale per applicare le modifiche"
gum style --foreground "$GUM_COLOR_MUTED" "Usa da terminale il comando 'brew-update' per aggiornare Homebrew in futuro"
echo ""
