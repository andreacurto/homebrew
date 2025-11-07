#!/bin/zsh

# Esporta il percorso di Homebrew per essere sicuri che il comando venga trovato
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Messaggio di avvio dello script
echo "" && echo "🚀 Avvio aggiornamento e manutenzione Homebrew..." && echo ""

# =====================================================
# FASE 1: Aggiornamento delle applicazioni (Casks)
# =====================================================

# Controlla le applicazioni installate tramite Homebrew Cask che necessitano di aggiornamento
# L'opzione --greedy include anche le app che normalmente non verrebbero aggiornate automaticamente
outdated_casks=$(brew outdated --cask --greedy --quiet)

# Controlla se ci sono applicazioni da aggiornare
if [[ -n "$outdated_casks" ]]; then

    # Mostra l'elenco delle applicazioni da aggiornare
    echo "👉 Trovate applicazioni da aggiornare:"
    echo "$outdated_casks" | sed 's/^/- /' && echo ""
    
    # Esegue l'upgrade solo per le cask trovate
    echo "👉 Avvio aggiornamento..."
    brew upgrade --cask $outdated_casks
    echo "✅ Aggiornamento applicazioni completato!" && echo ""

else

    echo "✅ Nessuna applicazione da aggiornare. Ottimo!" && echo ""

fi

# =====================================================
# FASE 2: Aggiornamento e manutenzione di Homebrew
# =====================================================

# Aggiorna l'indice dei pacchetti di Homebrew
echo "👉 Avvio aggiornamento repository (update)..."
brew update
echo "✅ Aggiornamento repository completato!" && echo ""

# Aggiorna tutte le formule installate (pacchetti CLI)
echo "👉 Avvio aggiornamento formule (upgrade)..."
brew upgrade
echo "✅ Aggiornamento formule completato!" && echo ""

# Rimuove le dipendenze orfane (non più necessarie da altri pacchetti)
echo "👉 Avvio rimozione dipendenze non necessarie (autoremove)..."
brew autoremove
echo "✅ Rimozione dipendenze non necessarie completata!" && echo ""

# Rimuove le vecchie versioni dei pacchetti e svuota la cache
echo "👉 Avvio pulizia file obsoleti (cleanup)..."
brew cleanup --prune=all
echo "✅ Pulizia file obsoleti completata!" && echo ""

# Esegue un controllo diagnostico per identificare potenziali problemi
echo "👉 Avvio controllo stato di salute (doctor)..."
brew doctor
echo "✅ Controllo stato di salute completato!" && echo ""

# Messaggio di completamento
echo "🎉 Aggiornamento e manutenzione Homebrew terminati con successo!"  && echo ""