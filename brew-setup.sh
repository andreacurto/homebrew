#!/bin/zsh

echo "" && echo "🚀 Inizializzazione setup Homebrew..."  && echo ""

# =====================================================
# 1. Installazione Homebrew
# =====================================================

if ! command -v brew &> /dev/null; then
    
    echo "👉 Homebrew non trovato. Avvio installazione..."
    # Installa Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Aggiunge Homebrew al PATH per la sessione corrente
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "✅ Homebrew installato correttamente" && echo ""

else
    
    echo "✅ Homebrew già installato" && echo ""

fi

# =====================================================
# 2. Installazione pacchetti
# =====================================================

# Strumenti CLI
echo "👉 Installazione strumenti CLI..."
brew install node gh oh-my-posh
echo "✅ Installazione strumenti CLI completata!" && echo ""

# Font
echo "👉 Installazione font..."
brew install --cask font-meslo-lg-nerd-font
brew install --cask font-roboto-mono-nerd-font
echo "✅ Installazione font completata!" && echo ""

# Applicazioni
echo "👉 Installazione applicazioni..."
brew install --cask \
    1password \
    appcleaner \
    dropbox \
    figma \
    google-chrome \
    imageoptim \
    numi \
    rectangle \
    spotify \
    visual-studio-code \
    whatsapp
echo "✅ Installazione applicazioni completata!" && echo ""

# =====================================================
# 3. Setup Script di aggiornamento
# =====================================================

echo "👉 Configurazione script di aggiornamento..."

# Crea directory Scripts se non esiste
mkdir -p ~/Shell

# Copia lo script di aggiornamento
SCRIPT_DIR=$(dirname "$0")
cp "$SCRIPT_DIR/brew-update.sh" ~/Shell/brew-update.sh
chmod +x ~/Shell/brew-update.sh

echo "✅ Configurazione script di aggiornamento completato!" && echo ""

# =====================================================
# 4. Configurazione Shell
# =====================================================

echo "👉 Configurazione Shell..."

# Backup del file .zshrc esistente
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
    echo "💾 Backup del file ~/.zshrc creato in ~/.zshrc.bak"
fi

# Copia il file di configurazione .zshrc
SCRIPT_DIR=$(dirname "$0")
cp "$SCRIPT_DIR/.zshrc" ~/.zshrc

echo "✅ Configurazione Shell completata!" && echo ""

# =====================================================
# Completamento
# =====================================================

# Messaggio di completamento
echo "🎉 Setup Homebrew completato con successo! Per applicare le modifiche, riavvia il terminale." && echo ""