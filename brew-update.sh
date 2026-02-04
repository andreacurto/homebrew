#!/bin/zsh
#
# Homebrew Update Script
# Script di aggiornamento e manutenzione Homebrew con interfaccia interattiva
#
# Funzionalità:
# - Aggiorna applicazioni installate (cask)
# - Aggiorna repository Homebrew
# - Aggiorna formule (pacchetti CLI)
# - Rimuove dipendenze orfane
# - Pulizia cache e vecchie versioni
# - Diagnostica sistema (brew doctor)

# ===== SETUP AMBIENTE =====
# Assicura che Homebrew sia nel PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Verifica/installa gum se non presente (necessario per l'interfaccia)
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# ===== CONFIGURAZIONE UI =====
# Definisce colori, simboli e stili per l'interfaccia Gum

# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"    # Verde per operazioni completate
GUM_COLOR_ERROR="9"       # Rosso per errori
GUM_COLOR_WARNING="11"    # Giallo per warning
GUM_COLOR_INFO="14"       # Cyan per informazioni
GUM_COLOR_PRIMARY="13"    # Magenta per titoli
GUM_COLOR_MUTED="244"     # Grigio per testo secondario

# Simboli
GUM_SYMBOL_SUCCESS="✓"    # Check per successo
GUM_SYMBOL_WARNING="!"    # Punto esclamativo per errori
GUM_SYMBOL_BULLET="·"     # Punto per liste

# Checkbox (per menu di selezione)
GUM_CHECKBOX_SELECTED="■"      # Checkbox selezionata
GUM_CHECKBOX_UNSELECTED="□"    # Checkbox non selezionata
GUM_CHECKBOX_CURSOR="›"        # Cursore di selezione

# Spinner (animazione durante operazioni lunghe)
GUM_SPINNER_TYPE="monkey"

# Bordi (per box messaggi)
GUM_BORDER_ROUNDED="rounded"
GUM_BORDER_DOUBLE="double"
GUM_BORDER_THICK="thick"

# Layout (spaziatura box)
GUM_PADDING="0 1"
GUM_MARGIN="0"
GUM_ERROR_PADDING="0 1"

# ===== MESSAGGIO INIZIALE =====
echo ""
gum style --border "$GUM_BORDER_DOUBLE" --border-foreground "$GUM_COLOR_PRIMARY" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update - Inizio 🚀"
echo ""

# ===== SELEZIONE OPERAZIONI =====
# Menu interattivo per scegliere quali operazioni eseguire
# Tutte le operazioni sono pre-selezionate di default
# Usa frecce per navigare, Spazio per deselezionare, Invio per confermare
selected_operations=$(gum choose --no-limit \
    --header="Seleziona le operazioni da eseguire:" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
    --selected="Aggiorna applicazioni,Aggiorna repository,Aggiorna formule,Rimuovi dipendenze,Pulizia cache,Diagnostica sistema" \
    "Aggiorna applicazioni" \
    "Aggiorna repository" \
    "Aggiorna formule" \
    "Rimuovi dipendenze" \
    "Pulizia cache" \
    "Diagnostica sistema")

# Inizializza variabili booleane per tracciare operazioni selezionate
do_cask_upgrade=false    # Aggiorna app (brew upgrade --cask)
do_update=false          # Aggiorna repository (brew update)
do_upgrade=false         # Aggiorna formule CLI (brew upgrade)
do_autoremove=false      # Rimuovi dipendenze orfane (brew autoremove)
do_cleanup=false         # Pulizia cache (brew cleanup)
do_doctor=false          # Diagnostica (brew doctor)
use_greedy=false         # Include app con auto-update

# Converte le selezioni dell'utente in variabili booleane
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

# Se selezionato aggiornamento app, chiede se includere app con auto-update
# L'opzione --greedy forza l'aggiornamento anche di app che si aggiornano da sole
if [ "$do_cask_upgrade" = true ]; then
    if gum confirm "Includere anche applicazioni con auto-update (opzione --greedy)?"; then
        use_greedy=true
    fi
fi

# ===== AGGIORNAMENTO APPLICAZIONI =====
# Controlla e aggiorna applicazioni installate tramite Homebrew Cask
# Mostra il progresso di download per ogni app
if [ "$do_cask_upgrade" = true ]; then
    # Controlla quali app hanno aggiornamenti disponibili
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Controllo applicazioni obsolete..." -- bash -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi" > /tmp/outdated_casks.txt
    outdated_casks=$(cat /tmp/outdated_casks.txt)
    rm -f /tmp/outdated_casks.txt

    if [[ -n "$outdated_casks" ]]; then
        # Mostra lista app da aggiornare
        gum style --foreground "$GUM_COLOR_WARNING" "Trovate applicazioni da aggiornare:"
        echo "$outdated_casks" | sed "s/^/  $GUM_SYMBOL_BULLET /"

        # Converte lista in array bash/zsh compatible
        outdated_casks_array=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && outdated_casks_array+=("$line")
        done <<< "$outdated_casks"

        if [ "$use_greedy" = true ]; then
            # Aggiorna includendo app con auto-update
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni (incluso auto-update)..."
            brew upgrade --cask --greedy "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            # PIPESTATUS[0] cattura exit code del primo comando della pipeline (brew upgrade)
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        else
            # Aggiorna solo app senza auto-update
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni..."
            brew upgrade --cask "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        fi
    else
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Nessuna applicazione da aggiornare"
    fi
fi

# ===== AGGIORNAMENTO REPOSITORY =====
# Aggiorna l'indice dei pacchetti disponibili su Homebrew
# Necessario per avere le ultime versioni disponibili
if [ "$do_update" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento repository Homebrew..." -- sh -c "brew update &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Repository aggiornato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento repository"
    fi
fi

# ===== AGGIORNAMENTO FORMULE =====
# Aggiorna tutti i pacchetti CLI installati (non le applicazioni)
# Es: node, gh, oh-my-posh, gum, etc.
if [ "$do_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento formule (pacchetti CLI)..." -- sh -c "brew upgrade &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Formule aggiornate"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento formule"
    fi
fi

# ===== RIMOZIONE DIPENDENZE ORFANE =====
# Rimuove pacchetti installati come dipendenze ma non più necessari
# Libera spazio rimuovendo pacchetti inutilizzati
if [ "$do_autoremove" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione dipendenze non necessarie..." -- sh -c "brew autoremove &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Dipendenze orfane rimosse"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore rimozione dipendenze"
    fi
fi

# ===== PULIZIA CACHE =====
# Rimuove vecchie versioni di pacchetti e svuota la cache di download
# --prune=all rimuove tutti i file di cache, anche quelli recenti
if [ "$do_cleanup" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache e file obsoleti..." -- sh -c "brew cleanup --prune=all &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia completata"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore pulizia"
    fi
fi

# ===== DIAGNOSTICA SISTEMA =====
# Esegue brew doctor per identificare potenziali problemi
# Mostra l'output completo della diagnostica
if [ "$do_doctor" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Esecuzione diagnostica sistema..." -- sh -c "brew doctor > /tmp/brew_doctor_output.txt 2>&1"
    doctor_exit=$?
    if [ $doctor_exit -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica completata"
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Diagnostica completata con warning"
    fi
    # Mostra output diagnostica in grigio
    cat /tmp/brew_doctor_output.txt | gum style --foreground "$GUM_COLOR_MUTED"
    rm -f /tmp/brew_doctor_output.txt
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_DOUBLE" --border-foreground "$GUM_COLOR_SUCCESS" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update - Completato 🎉"
echo ""
