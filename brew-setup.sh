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
# Usati prima che gum sia disponibile
MUTED="\033[38;5;244m"
RED="\033[38;5;9m"
RESET="\033[0m"

# ===== MODALITÀ TEST =====
# Attiva con --test per simulare installazioni senza modifiche reali
TEST_MODE=false
[[ "$1" == "--test" ]] && TEST_MODE=true

# ===== LISTE INSTALLAZIONE =====
# Modificare questi array per aggiungere/rimuovere elementi
# I nomi devono corrispondere ai nomi Homebrew Cask

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
# Mostra cosa farà lo script e chiede conferma all'utente
echo ""
echo -e "${MUTED}╭──────────────────────────────╮${RESET}"
echo -e "${MUTED}│${RESET}  Homebrew Setup → Inizio 🚀  ${MUTED}│${RESET}"
echo -e "${MUTED}╰──────────────────────────────╯${RESET}"
echo ""
echo "Questo script installerà:"
echo ""
echo -e "${MUTED}  → Homebrew (package manager per macOS)${RESET}"
echo -e "${MUTED}  → Strumenti e librerie (node, gh, oh-my-posh, gum)${RESET}"
echo -e "${MUTED}  → Font per terminale a tua scelta${RESET}"
echo -e "${MUTED}  → Tema terminale a tua scelta${RESET}"
echo -e "${MUTED}  → Applicazioni a tua scelta${RESET}"
echo ""
echo "Premi Invio per continuare o Ctrl+C per annullare..."
read -r

# ===== VERIFICA PRELIMINARE =====
echo -e "${MUTED}⌛ Verifica preliminare in corso, non chiudere il terminale...${RESET}"

# ===== INSTALLAZIONE SILENZIOSA HOMEBREW =====
# Verifica se Homebrew è installato, altrimenti lo installa
HOMEBREW_ALREADY_INSTALLED=false
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}! Errore installazione Homebrew${RESET}"
        exit 1
    fi
else
    HOMEBREW_ALREADY_INSTALLED=true
fi

# ===== INSTALLAZIONE SILENZIOSA GUM =====
# Verifica se gum è installato, altrimenti lo installa
GUM_ALREADY_INSTALLED=false
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
    if ! command -v gum &> /dev/null; then
        echo -e "${RED}! Errore installazione gum${RESET}"
        exit 1
    fi
else
    GUM_ALREADY_INSTALLED=true
fi

# Cancella il messaggio di verifica preliminare
echo -e "\033[1A\033[2K\033[1A\033[2K"

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
GUM_SYMBOL_SUCCESS="✔︎"    # Operazioni completate
GUM_SYMBOL_ERROR="✘"      # Errori
GUM_SYMBOL_WARNING="❖"    # Situazioni che richiedono attenzione
GUM_SYMBOL_INFO="❋"       # Informazioni neutre

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

# Banner modalità test
if [ "$TEST_MODE" = true ]; then
    echo ""
    gum style --border "$GUM_BORDER_THICK" --border-foreground "$GUM_COLOR_WARNING" --padding "$GUM_PADDING" --bold "⚠️  MODALITÀ TEST - Dati simulati, nessuna modifica reale al sistema"
    echo ""
fi

# ===== SELEZIONE APPLICAZIONI =====
# Menu interattivo con checkbox per scegliere quali applicazioni installare
# Usa frecce per navigare, Spazio per selezionare, Invio per confermare
selected_apps=""
if [ ${#APP_LIST[@]} -gt 0 ]; then
    selected_apps=$(gum choose --no-limit --height 15 \
        --header="Seleziona le applicazioni da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${APP_LIST[@]}")
fi

# Converte l'output multi-linea in array bash/zsh compatible
selected_apps_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_apps_array+=("$line")
done <<< "$selected_apps"

# ===== SELEZIONE FONT =====
# Menu interattivo con checkbox per scegliere quali font installare
# I Nerd Font includono icone e simboli speciali per il terminale
selected_fonts=""
if [ ${#FONT_LIST[@]} -gt 0 ]; then
    selected_fonts=$(gum choose --no-limit \
        --header="Seleziona i font da installare:" \
        --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
        --selected-prefix="$GUM_CHECKBOX_SELECTED " \
        --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
        "${FONT_LIST[@]}")
fi

# Converte l'output multi-linea in array bash/zsh compatible
selected_fonts_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_fonts_array+=("$line")
done <<< "$selected_fonts"

# ===== SELEZIONE TEMA OH MY POSH =====
# Menu per scegliere il tema del prompt del terminale
# Default: zash (minimalista)
selected_theme=$(gum choose \
    --header="Seleziona il tema per terminale da installare (Oh My Posh):" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel")

# Fallback al tema default se la selezione è vuota
[[ -z "$selected_theme" ]] && selected_theme="zash"

# ===== INSTALLAZIONI =====
# Messaggio di conferma dipendenze base
if [ "$HOMEBREW_ALREADY_INSTALLED" = true ]; then
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Homebrew già installato"
else
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato"
fi

# ===== INSTALLAZIONE STRUMENTI E LIBRERIE =====
# Installa pacchetti essenziali per il funzionamento degli script e dell'ambiente
# - node: Runtime JavaScript
# - gh: GitHub CLI
# - oh-my-posh: Personalizzazione prompt shell (cask)
# (gum già installato nella fase iniziale)

# Controlla se tutti gli strumenti e librerie sono già installati
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
        # Modalità test: simula richiesta password visiva
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        # Modalità test: simula installazione CLI tools
        for tool in "node" "gh" "oh-my-posh"; do
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Downloading $tool"
            sleep 0.3
            gum style --foreground "$GUM_COLOR_MUTED" "  ==> Installing $tool"
            sleep 0.5
        done
        echo ""
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie installati"
    else
        # Modalità normale: esegue brew install
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

# ===== INSTALLAZIONE FONT PER TERMINALE =====
# Installa i font selezionati dall'utente tramite Homebrew Cask
# Se nessun font selezionato, salta questa fase
if [ ${#selected_fonts_array[@]} -gt 0 ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula richiesta password visiva
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        # Modalità test: simula installazione font
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
        # Modalità normale: separa font già installati da quelli da installare
        fonts_to_install=()
        for font in "${selected_fonts_array[@]}"; do
            if ! brew list --cask "$font" &> /dev/null; then
                fonts_to_install+=("$font")
            fi
        done

        # Installa solo i font non ancora presenti
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
            # Tutti i font selezionati erano già installati
            gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Font per terminale già installati"
        fi
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessun font selezionato"
fi

# ===== INSTALLAZIONE APPLICAZIONI =====
# Installa le applicazioni selezionate dall'utente tramite Homebrew Cask
# Se nessuna app selezionata, salta questa fase
if [ ${#selected_apps_array[@]} -gt 0 ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula richiesta password visiva
        gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
        echo ""
        sleep 0.8

        # Modalità test: simula installazione applicazioni
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
        # Modalità normale: separa app già installate da quelle da installare
        apps_to_install=()
        for app in "${selected_apps_array[@]}"; do
            if ! brew list --cask "$app" &> /dev/null; then
                apps_to_install+=("$app")
            fi
        done

        # Installa solo le app non ancora presenti
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
            # Tutte le app selezionate erano già installate
            gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Applicazioni già installate"
        fi
    fi
else
    gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessuna applicazione selezionata"
fi

# ===== SETUP SCRIPT DI AGGIORNAMENTO =====
# Copia brew-update.sh in ~/Shell/ per poterlo eseguire con alias brew-update
# Crea la directory ~/Shell/ se non esiste
if [ "$TEST_MODE" = true ]; then
    # Modalità test: simula con delay
    sleep 0.5
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script aggiornamento configurato"
else
    # Modalità normale: esegue copia script
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione script aggiornamento..." -- sh -c "mkdir -p ~/Shell && cp '$SCRIPT_DIR/brew-update.sh' ~/Shell/brew-update.sh && chmod +x ~/Shell/brew-update.sh"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script aggiornamento configurato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile configurare script aggiornamento"
    fi
fi

# ===== CONFIGURAZIONE SHELL =====
# Crea/sovrascrive ~/.zshrc con configurazione Oh My Posh e alias
# Backup automatico del file esistente in ~/.zshrc.bak
if [ "$TEST_MODE" = true ]; then
    # Modalità test: simula con delay
    sleep 0.3
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato"
else
    # Modalità normale: modifica .zshrc
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.bak
    fi

    cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='zsh ~/Shell/brew-update.sh'
EOF

    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Tema terminale configurato"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Setup → Completato 🎉"
echo ""
gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Riavvia il terminale per applicare le modifiche"
gum style --foreground "$GUM_COLOR_MUTED" "Usa da terminale il comando 'brew-update' per aggiornare Homebrew in futuro"
echo ""
