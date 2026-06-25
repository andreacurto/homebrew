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
# - Abilita l'autocompletamento del terminale (zsh-autocomplete)
# - Configura (opzionale) l'aggiornamento automatico di Homebrew in background
# - Installa il comando di utility 'brew-update' (aggiornamenti e manutenzione manuali)

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
    "Codex"
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
    "codex"
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

# Evita il "brew update" implicito prima di ogni install: più veloce e niente blocchi
export HOMEBREW_NO_AUTO_UPDATE=1

# ===== MESSAGGIO INIZIALE E CONFERMA =====
echo ""
printf "%b\n" "${MUTED}╭──────────────────────────────╮${RESET}"
printf "%b\n" "${MUTED}│${RESET}  Homebrew Setup → Inizio 🚀  ${MUTED}│${RESET}"
printf "%b\n" "${MUTED}╰──────────────────────────────╯${RESET}"
echo ""
echo "Questo script installerà:"
echo ""
printf "%b\n" "${MUTED}→ Homebrew (package manager per macOS)${RESET}"
printf "%b\n" "${MUTED}→ Aggiornamento automatico di Homebrew (opzionale)${RESET}"
printf "%b\n" "${MUTED}→ Strumenti e librerie (node, gh, oh-my-posh, gum)${RESET}"
printf "%b\n" "${MUTED}→ Applicazioni a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Font per terminale a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Tema terminale a tua scelta${RESET}"
printf "%b\n" "${MUTED}→ Autocompletamento terminale${RESET}"
printf "%b\n" "${MUTED}→ Comando di utility 'brew-update'${RESET}"
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
clear
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
clear
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
clear
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

# ===== SELEZIONE AGGIORNAMENTO AUTOMATICO HOMEBREW =====
clear
gum confirm "Abilitare l'aggiornamento automatico di Homebrew in background?" --default=true
case $? in
    0) enable_autoupdate=true ;;
    1) enable_autoupdate=false ;;
    130) exit 130 ;;
esac

# Preferenze auto-update (default: una volta a settimana, aggiorna pacchetti + pulizia)
au_interval="7d"
au_upgrade=false
au_cleanup=false
au_aconly=false
au_immediate=false
if [ "$enable_autoupdate" = true ]; then
    # Intervallo (default pre-selezionato e primo in lista: una volta a settimana)
    clear
    interval_label=$(gum choose \
        --header="Ogni quanto eseguire l'aggiornamento automatico?" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        --selected="Una volta a settimana" \
        "Una volta a settimana" \
        "Una volta al giorno")
    [ $? -eq 130 ] && exit 130
    if [ "$interval_label" = "Una volta al giorno" ]; then
        au_interval="1d"
    else
        au_interval="7d"
    fi

    # Opzioni (pre-selezionate = default consigliati)
    clear
    autoupdate_opts=$(gum choose --no-limit \
        --header="Opzioni aggiornamento automatico Homebrew:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        --selected="Aggiorna anche i pacchetti e le applicazioni installate,Pulisci la cache dopo l'aggiornamento" \
        "Aggiorna anche i pacchetti e le applicazioni installate" \
        "Pulisci la cache dopo l'aggiornamento" \
        "Esegui solo quando il Mac è collegato alla corrente" \
        "Esegui ad ogni avvio del Mac")
    [ $? -eq 130 ] && exit 130

    while IFS= read -r opt; do
        case "$opt" in
            "Aggiorna anche i pacchetti e le applicazioni installate") au_upgrade=true ;;
            "Pulisci la cache dopo l'aggiornamento") au_cleanup=true ;;
            "Esegui solo quando il Mac è collegato alla corrente") au_aconly=true ;;
            "Esegui ad ogni avvio del Mac") au_immediate=true ;;
        esac
    done <<< "$autoupdate_opts"
fi

# ===== INSTALLAZIONI =====
if [ "$HOMEBREW_ALREADY_INSTALLED" = true ]; then
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Homebrew già installato"
else
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato"
fi

# ===== INSTALLAZIONE STRUMENTI E LIBRERIE =====
CLI_ALREADY_INSTALLED=false
if command -v node &> /dev/null && command -v gh &> /dev/null && command -v oh-my-posh &> /dev/null && brew list zsh-autocomplete &> /dev/null; then
    CLI_ALREADY_INSTALLED=true
fi

if [ "$CLI_ALREADY_INSTALLED" = true ]; then
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Strumenti e librerie già installati"
else
    echo "Installazione strumenti e librerie in corso..."
    echo ""
    (brew install node gh zsh-autocomplete && brew install --cask jandedobbeleer/oh-my-posh/oh-my-posh) 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
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

# ===== CONFIGURAZIONE AGGIORNAMENTO AUTOMATICO HOMEBREW =====
if [ "$enable_autoupdate" = true ]; then
    # Costruisci i flag in base alle preferenze raccolte
    au_flags=(--sudo)
    [ "$au_upgrade" = true ] && au_flags+=(--upgrade)
    [ "$au_cleanup" = true ] && au_flags+=(--cleanup)
    [ "$au_aconly" = true ] && au_flags+=(--ac-only)
    [ "$au_immediate" = true ] && au_flags+=(--immediate)

    # Predisposizione completa e silenziosa in un unico passo: pinentry-mac (prompt
    # password GUI per --sudo), tap + trust del comando esterno e riconfigurazione
    # idempotente del job launchd. exec </dev/null evita blocchi su input.
    if gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione aggiornamento automatico..." \
        -- sh -c "exec </dev/null
            export HOMEBREW_NO_AUTO_UPDATE=1
            brew install pinentry-mac
            brew tap domt4/autoupdate
            brew trust --command domt4/autoupdate/autoupdate
            brew autoupdate delete
            brew autoupdate start $au_interval ${au_flags[*]}"; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Aggiornamento automatico configurato ($interval_label)"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile configurare l'aggiornamento automatico"
    fi
fi

# ===== SETUP COMANDO DI UTILITY (brew-update) =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione comando di utility..." -- sh -c "mkdir -p '$INSTALL_DIR' && cp '$SCRIPT_DIR/update.sh' '$INSTALL_DIR/update.sh' && chmod +x '$INSTALL_DIR/update.sh'"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Comando di utility configurato"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile configurare il comando di utility"
fi

# ===== CONFIGURAZIONE SHELL =====
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
fi

# Scrivi la riga di autocomplete solo se effettivamente installato (evita .zshrc rotto)
autocomplete_installed=false
brew list zsh-autocomplete &> /dev/null && autocomplete_installed=true

# Genera ~/.zshrc: autocomplete in cima (requisito del plugin), poi Oh My Posh, poi alias
{
    if [ "$autocomplete_installed" = true ]; then
        echo "# zsh-autocomplete (deve precedere compinit / Oh My Posh)"
        echo 'source "$(brew --prefix)/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"'
        echo ""
    fi
    if [ -n "$selected_theme" ]; then
        echo "# Oh My Posh"
        echo "eval \"\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)\""
        echo ""
    fi
    echo "# Alias"
    echo "alias brew-update='zsh $INSTALL_DIR/update.sh'"
} > ~/.zshrc

if [ -n "$selected_theme" ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato ($selected_theme_label)"
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun tema selezionato"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Setup → Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Esegui il comando 'source ~/.zshrc' o riavvia il terminale per applicare le modifiche"
if [ "$enable_autoupdate" = true ]; then
    gum style --foreground "$GUM_COLOR_MUTED" "Aggiornamento automatico attivo: gestiscilo con 'brew autoupdate status' o 'brew autoupdate stop'"
fi
gum style --foreground "$GUM_COLOR_MUTED" "Usa il comando 'brew-update' per aggiornamenti e manutenzione manuali"
echo ""
