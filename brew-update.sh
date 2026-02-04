#!/bin/zsh

# Esporta il percorso di Homebrew per essere sicuri che il comando venga trovato
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Assicura che gum sia installato
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# Messaggio di avvio dello script
echo ""
gum style --border double --padding "1 2" --margin "1 0" --foreground 5 --bold "Homebrew Update - Aggiornamento Sistema"
echo ""

# =====================================================
# Selezione Operazioni da Eseguire
# =====================================================

gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Selezione Operazioni"
echo ""
gum style --foreground 6 "Seleziona le operazioni da eseguire (usa Spazio per selezionare, Invio per confermare):"
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

echo ""
gum style --foreground 2 "✓ Preferenze raccolte con successo!"
echo ""
gum style --border rounded --padding "1 2" --margin "1 0" --foreground 6 "Esecuzione Operazioni"
echo ""

# =====================================================
# FASE 1: Aggiornamento delle applicazioni (Casks)
# =====================================================

if [ "$do_cask_upgrade" = true ]; then

    # Controlla le applicazioni installate tramite Homebrew Cask che necessitano di aggiornamento
    gum style --foreground 6 "Controllo applicazioni obsolete..."
    if [ "$use_greedy" = true ]; then
        outdated_casks=$(brew outdated --cask --greedy --quiet)
    else
        outdated_casks=$(brew outdated --cask --quiet)
    fi

    # Controlla se ci sono applicazioni da aggiornare
    if [[ -n "$outdated_casks" ]]; then

        # Mostra l'elenco delle applicazioni da aggiornare
        gum style --foreground 3 "Trovate applicazioni da aggiornare:"
        echo "$outdated_casks" | sed 's/^/  • /'
        echo ""

        # Esegue l'upgrade solo per le cask trovate
        if [ "$use_greedy" = true ]; then
            if gum spin --spinner dot --title "Aggiornamento applicazioni (incluso auto-update)..." -- brew upgrade --cask --greedy $outdated_casks 2>/dev/null; then
                gum style --foreground 2 "✓ Aggiornamento applicazioni completato!"
            else
                gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante aggiornamento applicazioni. Continuo..."
            fi
        else
            if gum spin --spinner dot --title "Aggiornamento applicazioni..." -- brew upgrade --cask $outdated_casks 2>/dev/null; then
                gum style --foreground 2 "✓ Aggiornamento applicazioni completato!"
            else
                gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante aggiornamento applicazioni. Continuo..."
            fi
        fi
        echo ""

    else

        gum style --foreground 2 "✓ Nessuna applicazione da aggiornare"
        echo ""

    fi

fi

# =====================================================
# FASE 2: Aggiornamento e manutenzione di Homebrew
# =====================================================

# Aggiorna l'indice dei pacchetti di Homebrew
if [ "$do_update" = true ]; then
    if gum spin --spinner dot --title "Aggiornamento repository Homebrew..." -- brew update 2>/dev/null; then
        gum style --foreground 2 "✓ Repository aggiornato"
        echo ""
    else
        gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante aggiornamento repository. Continuo..."
        echo ""
    fi
fi

# Aggiorna tutte le formule installate (pacchetti CLI)
if [ "$do_upgrade" = true ]; then
    if gum spin --spinner dot --title "Aggiornamento formule (pacchetti CLI)..." -- brew upgrade 2>/dev/null; then
        gum style --foreground 2 "✓ Formule aggiornate"
        echo ""
    else
        gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante aggiornamento formule. Continuo..."
        echo ""
    fi
fi

# Rimuove le dipendenze orfane (non più necessarie da altri pacchetti)
if [ "$do_autoremove" = true ]; then
    if gum spin --spinner dot --title "Rimozione dipendenze non necessarie..." -- brew autoremove 2>/dev/null; then
        gum style --foreground 2 "✓ Dipendenze orfane rimosse"
        echo ""
    else
        gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante rimozione dipendenze. Continuo..."
        echo ""
    fi
fi

# Rimuove le vecchie versioni dei pacchetti e svuota la cache
if [ "$do_cleanup" = true ]; then
    if gum spin --spinner dot --title "Pulizia cache e file obsoleti..." -- brew cleanup --prune=all 2>/dev/null; then
        gum style --foreground 2 "✓ Pulizia completata"
        echo ""
    else
        gum style --foreground 196 --border thick --padding "0 1" "⚠ Errore durante pulizia. Continuo..."
        echo ""
    fi
fi

# Esegue un controllo diagnostico per identificare potenziali problemi
if [ "$do_doctor" = true ]; then
    gum style --foreground 6 "Esecuzione diagnostica sistema..."
    echo ""
    if brew doctor 2>&1 | gum style --foreground 240; then
        echo ""
        gum style --foreground 2 "✓ Diagnostica completata"
        echo ""
    else
        echo ""
        gum style --foreground 3 "⚠ Diagnostica completata con warning"
        echo ""
    fi
fi

# Messaggio di completamento
gum style \
    --border double \
    --padding "1 2" \
    --margin "1 0" \
    --foreground 2 \
    --bold \
    "Aggiornamento Completato con Successo!" \
    "" \
    "Tutte le operazioni selezionate sono state eseguite"
echo ""