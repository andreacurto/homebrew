#!/bin/zsh

# Esporta il percorso di Homebrew per essere sicuri che il comando venga trovato
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Assicura che gum sia installato
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# Messaggio di avvio dello script
echo "" && echo "🚀 Avvio aggiornamento e manutenzione Homebrew..." && echo ""

# =====================================================
# Selezione Operazioni da Eseguire
# =====================================================

echo "Seleziona le operazioni da eseguire (usa Spazio per selezionare, Invio per confermare):"
selected_operations=$(gum choose --no-limit \
    --selected="Aggiorna applicazioni,Aggiorna repository,Aggiorna formule,Rimuovi dipendenze,Pulizia cache,Diagnostica sistema" \
    "Aggiorna applicazioni" \
    "Aggiorna repository" \
    "Aggiorna formule" \
    "Rimuovi dipendenze" \
    "Pulizia cache" \
    "Diagnostica sistema")

# Inizializza variabili booleane
do_cask_upgrade=false
do_update=false
do_upgrade=false
do_autoremove=false
do_cleanup=false
do_doctor=false
use_greedy=false

# Converte le selezioni in variabili booleane
while IFS= read -r operation; do
    case "$operation" in
        "Aggiorna applicazioni") do_cask_upgrade=true ;;
        "Aggiorna repository") do_update=true ;;
        "Aggiorna formule") do_upgrade=true ;;
        "Rimuovi dipendenze") do_autoremove=true ;;
        "Pulizia cache") do_cleanup=true ;;
        "Diagnostica sistema") do_doctor=true ;;
    esac
done <<< "$selected_operations"

# Se l'aggiornamento cask è selezionato, chiedi per --greedy
if [ "$do_cask_upgrade" = true ]; then
    echo ""
    if gum confirm "Includere anche applicazioni con auto-update (opzione --greedy)?"; then
        use_greedy=true
    fi
fi

echo "" && echo "✅ Preferenze raccolte! Avvio operazioni..." && echo ""

# =====================================================
# FASE 1: Aggiornamento delle applicazioni (Casks)
# =====================================================

if [ "$do_cask_upgrade" = true ]; then

    # Controlla le applicazioni installate tramite Homebrew Cask che necessitano di aggiornamento
    if [ "$use_greedy" = true ]; then
        outdated_casks=$(brew outdated --cask --greedy --quiet)
    else
        outdated_casks=$(brew outdated --cask --quiet)
    fi

    # Controlla se ci sono applicazioni da aggiornare
    if [[ -n "$outdated_casks" ]]; then

        # Mostra l'elenco delle applicazioni da aggiornare
        echo "👉 Trovate applicazioni da aggiornare:"
        echo "$outdated_casks" | sed 's/^/- /' && echo ""

        # Esegue l'upgrade solo per le cask trovate
        echo "👉 Avvio aggiornamento..."
        if [ "$use_greedy" = true ]; then
            brew upgrade --cask --greedy $outdated_casks
        else
            brew upgrade --cask $outdated_casks
        fi
        echo "✅ Aggiornamento applicazioni completato!" && echo ""

    else

        echo "✅ Nessuna applicazione da aggiornare. Ottimo!" && echo ""

    fi

fi

# =====================================================
# FASE 2: Aggiornamento e manutenzione di Homebrew
# =====================================================

# Aggiorna l'indice dei pacchetti di Homebrew
if [ "$do_update" = true ]; then
    echo "👉 Avvio aggiornamento repository (update)..."
    brew update
    echo "✅ Aggiornamento repository completato!" && echo ""
fi

# Aggiorna tutte le formule installate (pacchetti CLI)
if [ "$do_upgrade" = true ]; then
    echo "👉 Avvio aggiornamento formule (upgrade)..."
    brew upgrade
    echo "✅ Aggiornamento formule completato!" && echo ""
fi

# Rimuove le dipendenze orfane (non più necessarie da altri pacchetti)
if [ "$do_autoremove" = true ]; then
    echo "👉 Avvio rimozione dipendenze non necessarie (autoremove)..."
    brew autoremove
    echo "✅ Rimozione dipendenze non necessarie completata!" && echo ""
fi

# Rimuove le vecchie versioni dei pacchetti e svuota la cache
if [ "$do_cleanup" = true ]; then
    echo "👉 Avvio pulizia file obsoleti (cleanup)..."
    brew cleanup --prune=all
    echo "✅ Pulizia file obsoleti completata!" && echo ""
fi

# Esegue un controllo diagnostico per identificare potenziali problemi
if [ "$do_doctor" = true ]; then
    echo "👉 Avvio controllo stato di salute (doctor)..."
    brew doctor
    echo "✅ Controllo stato di salute completato!" && echo ""
fi

# Messaggio di completamento
echo "🎉 Aggiornamento e manutenzione Homebrew terminati con successo!"  && echo ""