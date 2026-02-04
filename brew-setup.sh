#!/bin/zsh

# =====================================================
# Configurazione UI (Gum)
# =====================================================

# Colori (256 terminal colors - Reference: https://www.ditig.com/256-colors-cheat-sheet)
GUM_COLOR_SUCCESS="2"        # Verde
GUM_COLOR_ERROR="196"        # Rosso
GUM_COLOR_WARNING="3"        # Giallo
GUM_COLOR_INFO="6"           # Cyan
GUM_COLOR_PRIMARY="5"        # Magenta
GUM_COLOR_MUTED="240"        # Grigio

# Simboli
GUM_SYMBOL_SUCCESS="✔"       # Simbolo successo
GUM_SYMBOL_WARNING="⚠"       # Simbolo warning/errore
GUM_SYMBOL_BULLET="❖"        # Bullet point liste
GUM_SYMBOL_SKIP="⊘"          # Simbolo operazione saltata
GUM_SYMBOL_INFO="⚑"          # Simbolo informativo

# Spinner
GUM_SPINNER_TYPE="dot"       # Tipo spinner: dot, line, minidot, jump, pulse, points, globe, moon, monkey, meter, hamburger

# Bordi
GUM_BORDER_ROUNDED="rounded" # Bordo arrotondato
GUM_BORDER_DOUBLE="double"   # Bordo doppio
GUM_BORDER_THICK="thick"     # Bordo spesso

# Layout
GUM_PADDING="1 2"            # Padding verticale orizzontale
GUM_MARGIN="1 0"             # Margin verticale orizzontale
GUM_ERROR_PADDING="0 1"      # Padding per messaggi errore

echo ""
gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_PRIMARY" --bold "Setup Homebrew - Inizializzazione"
echo ""

# =====================================================
# 1. Installazione Homebrew
# =====================================================

if ! command -v brew &> /dev/null; then

    gum style --foreground "$GUM_COLOR_INFO" "Homebrew non trovato. Avvio installazione..."
    # Installa Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Aggiunge Homebrew al PATH per la sessione corrente
    eval "$(/opt/homebrew/bin/brew shellenv)"
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew installato correttamente"
    echo ""

else

    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew già installato"
    echo ""

fi

# =====================================================
# 2. Installazione pacchetti
# =====================================================

gum style --border "$GUM_BORDER_ROUNDED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_INFO" "Installazione Pacchetti Essenziali"
echo ""

# Strumenti CLI
if gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione strumenti CLI (node, gh, oh-my-posh, gum)..." -- brew install node gh oh-my-posh gum 2>/dev/null; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Installazione strumenti CLI completata!"
    echo ""
else
    gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore durante l'installazione CLI tools. Continuo..."
    echo ""
fi

# =====================================================
# 3. Raccolta Preferenze Utente
# =====================================================

gum style --border "$GUM_BORDER_ROUNDED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_INFO" "Raccolta Preferenze Utente"

# Selezione applicazioni con checkbox interattive
echo ""
gum style --foreground "$GUM_COLOR_INFO" "Seleziona le applicazioni da installare (usa Spazio per selezionare, Invio per confermare):"
selected_apps=$(gum choose --no-limit --height 15 \
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

# Converte l'output in array
IFS=$'\n' read -r -d '' -a selected_apps_array <<< "$selected_apps"

# Selezione tema Oh My Posh
echo ""
gum style --foreground "$GUM_COLOR_INFO" "Seleziona il tema Oh My Posh:"
selected_theme=$(gum choose --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel")

echo ""
gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Preferenze raccolte con successo!"

# =====================================================
# 4. Installazione Font e Applicazioni
# =====================================================

gum style --border "$GUM_BORDER_ROUNDED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_INFO" "Installazione Font e Applicazioni"
echo ""

# Font
if gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione Meslo LG Nerd Font..." -- brew install --cask font-meslo-lg-nerd-font 2>/dev/null; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Meslo LG Nerd Font installato"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione Meslo LG"
fi

if gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione Roboto Mono Nerd Font..." -- brew install --cask font-roboto-mono-nerd-font 2>/dev/null; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Roboto Mono Nerd Font installato"
    echo ""
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione Roboto Mono"
    echo ""
fi

# Applicazioni
# Installa le app selezionate dall'utente
if [ ${#selected_apps_array[@]} -gt 0 ]; then

    echo ""
    if gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione applicazioni selezionate..." -- brew install --cask "${selected_apps_array[@]}" 2>/dev/null; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Installazione applicazioni completata!"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore durante l'installazione di alcune applicazioni. Continuo..."
    fi
    echo ""

else

    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_SKIP Nessuna applicazione selezionata per l'installazione"
    echo ""

fi

# =====================================================
# 4. Setup Script di aggiornamento
# =====================================================

gum style --border "$GUM_BORDER_ROUNDED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_INFO" "Setup Script di Aggiornamento"
echo ""

# Crea directory Scripts se non esiste
mkdir -p ~/Shell

# Copia lo script di aggiornamento
SCRIPT_DIR=$(dirname "$0")
cp "$SCRIPT_DIR/brew-update.sh" ~/Shell/brew-update.sh
chmod +x ~/Shell/brew-update.sh

gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script di aggiornamento configurato in ~/Shell/"
echo ""

# =====================================================
# 5. Configurazione Shell
# =====================================================

gum style --border "$GUM_BORDER_ROUNDED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_INFO" "Configurazione Shell"
echo ""

# Backup del file .zshrc esistente
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_INFO Backup di ~/.zshrc creato in ~/.zshrc.bak"
fi

# Crea il file .zshrc con il tema selezionato
cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='sh ~/Shell/brew-update.sh'
EOF

gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Shell configurata con tema: $selected_theme"
echo ""

# =====================================================
# Completamento
# =====================================================

# Messaggio di completamento
gum style \
    --border "$GUM_BORDER_DOUBLE" \
    --padding "$GUM_PADDING" \
    --margin "$GUM_MARGIN" \
    --foreground "$GUM_COLOR_SUCCESS" \
    --bold \
    "Setup Completato con Successo!" \
    "" \
    "Riavvia il terminale per applicare le modifiche"
echo ""