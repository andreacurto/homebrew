#!/bin/zsh

echo ""
gum style --border double --padding "1 2" --margin "1 0" --foreground 5 --bold "Setup Homebrew - Inizializzazione"
echo ""

# =====================================================
# 1. Installazione Homebrew
# =====================================================

if ! command -v brew &> /dev/null; then

    gum style --foreground 6 "Homebrew non trovato. Avvio installazione..."
    # Installa Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Aggiunge Homebrew al PATH per la sessione corrente
    eval "$(/opt/homebrew/bin/brew shellenv)"
    gum style --foreground 2 "✓ Homebrew installato correttamente"
    echo ""

else

    gum style --foreground 2 "✓ Homebrew già installato"
    echo ""

fi

# =====================================================
# 2. Installazione pacchetti
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Installazione Pacchetti Essenziali"
echo ""

# Strumenti CLI
if gum spin --spinner dot --title "Installazione strumenti CLI (node, gh, oh-my-posh, gum)..." -- brew install node gh oh-my-posh gum 2>/dev/null; then
    gum style --foreground 2 "✓ Installazione strumenti CLI completata!"
    echo ""
else
    gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante l'installazione CLI tools. Continuo..."
    echo ""
fi

# =====================================================
# 3. Raccolta Preferenze Utente
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Raccolta Preferenze Utente"

# Selezione applicazioni con checkbox interattive
echo ""
gum style --foreground 6 "Seleziona le applicazioni da installare (usa Spazio per selezionare, Invio per confermare):"
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
gum style --foreground 6 "Seleziona il tema Oh My Posh:"
selected_theme=$(gum choose --selected="zash" \
    "zash" \
    "material" \
    "robbyrussell" \
    "pararussel")

echo ""
gum style --foreground 2 "✓ Preferenze raccolte con successo!"

# =====================================================
# 4. Installazione Font e Applicazioni
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Installazione Font e Applicazioni"
echo ""

# Font
if gum spin --spinner dot --title "Installazione Meslo LG Nerd Font..." -- brew install --cask font-meslo-lg-nerd-font 2>/dev/null; then
    gum style --foreground 2 "✓ Meslo LG Nerd Font installato"
else
    gum style --foreground 196 "⚠ Errore installazione Meslo LG"
fi

if gum spin --spinner dot --title "Installazione Roboto Mono Nerd Font..." -- brew install --cask font-roboto-mono-nerd-font 2>/dev/null; then
    gum style --foreground 2 "✓ Roboto Mono Nerd Font installato"
    echo ""
else
    gum style --foreground 196 "⚠ Errore installazione Roboto Mono"
    echo ""
fi

# Applicazioni
# Installa le app selezionate dall'utente
if [ ${#selected_apps_array[@]} -gt 0 ]; then

    echo ""
    if gum spin --spinner dot --title "Installazione applicazioni selezionate..." -- brew install --cask "${selected_apps_array[@]}" 2>/dev/null; then
        gum style --foreground 2 "✓ Installazione applicazioni completata!"
    else
        gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante l'installazione di alcune applicazioni. Continuo..."
    fi
    echo ""

else

    gum style --foreground 3 "⊘ Nessuna applicazione selezionata per l'installazione"
    echo ""

fi

# =====================================================
# 4. Setup Script di aggiornamento
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Setup Script di Aggiornamento"
echo ""

# Crea directory Scripts se non esiste
mkdir -p ~/Shell

# Copia lo script di aggiornamento
SCRIPT_DIR=$(dirname "$0")
cp "$SCRIPT_DIR/brew-update.sh" ~/Shell/brew-update.sh
chmod +x ~/Shell/brew-update.sh

gum style --foreground 2 "✓ Script di aggiornamento configurato in ~/Shell/"
echo ""

# =====================================================
# 5. Configurazione Shell
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Configurazione Shell"
echo ""

# Backup del file .zshrc esistente
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
    gum style --foreground 3 "⚑ Backup di ~/.zshrc creato in ~/.zshrc.bak"
fi

# Crea il file .zshrc con il tema selezionato
cat > ~/.zshrc << EOF
# Oh My Posh
eval "\$(oh-my-posh init zsh --config \$(brew --prefix oh-my-posh)/themes/${selected_theme}.omp.json)"

# Alias
alias brew-update='sh ~/Shell/brew-update.sh'
EOF

gum style --foreground 2 "✓ Shell configurata con tema: $selected_theme"
echo ""

# =====================================================
# Completamento
# =====================================================

# Messaggio di completamento
gum style \
    --border double \
    --padding "1 2" \
    --margin "1 0" \
    --foreground 2 \
    --bold \
    "Setup Completato con Successo!" \
    "" \
    "Riavvia il terminale per applicare le modifiche"
echo ""