#!/bin/zsh

# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"
GUM_COLOR_ERROR="9"
GUM_COLOR_WARNING="11"
GUM_COLOR_INFO="14"
GUM_COLOR_PRIMARY="13"
GUM_COLOR_MUTED="244"

# Simboli
GUM_SYMBOL_SUCCESS="✓"
GUM_SYMBOL_WARNING="!"
GUM_SYMBOL_SKIP="○"

# Checkbox
GUM_CHECKBOX_SELECTED="■"
GUM_CHECKBOX_UNSELECTED="□"
GUM_CHECKBOX_CURSOR="›"

# Spinner
GUM_SPINNER_TYPE="line"

# Bordi
GUM_BORDER_ROUNDED="rounded"
GUM_BORDER_DOUBLE="double"
GUM_BORDER_THICK="thick"

# Layout
GUM_PADDING="0 1"
GUM_MARGIN="0"
GUM_ERROR_PADDING="0 1"

gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_PRIMARY" --bold "Setup Homebrew - Inizializzazione"

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

gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione strumenti CLI (node, gh, oh-my-posh, gum)..." -- brew install node gh oh-my-posh gum &>/dev/null
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti CLI installati"
else
    gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore installazione CLI tools"
fi

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

selected_apps_array=()
while IFS= read -r line; do
    [[ -n "$line" ]] && selected_apps_array+=("$line")
done <<< "$selected_apps"

selected_theme=$(gum choose \
    --header="Seleziona il tema Oh My Posh:" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel")

gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione font Nerd Font..." -- bash -c "brew install --cask font-meslo-lg-nerd-font font-roboto-mono-nerd-font &>/dev/null"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Font installati"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore installazione font"
fi

if [ ${#selected_apps_array[@]} -gt 0 ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Installazione applicazioni selezionate..." -- brew install --cask "${selected_apps_array[@]}" &>/dev/null
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni installate"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore installazione applicazioni"
    fi
else
    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_SKIP Nessuna applicazione selezionata"
fi

SCRIPT_DIR=$(dirname "$0")
gum spin --spinner "$GUM_SPINNER_TYPE" --title "Configurazione script di aggiornamento..." -- bash -c "mkdir -p ~/Shell && cp '$SCRIPT_DIR/brew-update.sh' ~/Shell/brew-update.sh && chmod +x ~/Shell/brew-update.sh"
if [ $? -eq 0 ]; then
    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Script di aggiornamento configurato"
else
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore configurazione script"
fi

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

gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_SUCCESS" --bold "Setup Completato!" "" "Riavvia il terminale per applicare le modifiche"
