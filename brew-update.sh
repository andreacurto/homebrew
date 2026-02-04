#!/bin/zsh

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

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
GUM_SYMBOL_BULLET="·"

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

echo ""
gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_PRIMARY" --bold "Homebrew Update - Inizio 🚀"
echo ""

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

do_cask_upgrade=false
do_update=false
do_upgrade=false
do_autoremove=false
do_cleanup=false
do_doctor=false
use_greedy=false

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

if [ "$do_cask_upgrade" = true ]; then
    if gum confirm "Includere anche applicazioni con auto-update (opzione --greedy)?"; then
        use_greedy=true
    fi
fi

if [ "$do_cask_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Controllo applicazioni obsolete..." -- bash -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi" > /tmp/outdated_casks.txt
    outdated_casks=$(cat /tmp/outdated_casks.txt)
    rm -f /tmp/outdated_casks.txt

    if [[ -n "$outdated_casks" ]]; then
        gum style --foreground "$GUM_COLOR_WARNING" "Trovate applicazioni da aggiornare:"
        echo "$outdated_casks" | sed "s/^/  $GUM_SYMBOL_BULLET /"

        outdated_casks_array=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && outdated_casks_array+=("$line")
        done <<< "$outdated_casks"

        if [ "$use_greedy" = true ]; then
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni (incluso auto-update)..."
            brew upgrade --cask --greedy "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        else
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni..."
            brew upgrade --cask "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            if [ ${PIPESTATUS[0]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        fi
    else
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Nessuna applicazione da aggiornare"
    fi
fi

if [ "$do_update" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento repository Homebrew..." -- sh -c "brew update &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Repository aggiornato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore aggiornamento repository"
    fi
fi

if [ "$do_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento formule (pacchetti CLI)..." -- sh -c "brew upgrade &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Formule aggiornate"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore aggiornamento formule"
    fi
fi

if [ "$do_autoremove" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione dipendenze non necessarie..." -- sh -c "brew autoremove &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Dipendenze orfane rimosse"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore rimozione dipendenze"
    fi
fi

if [ "$do_cleanup" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache e file obsoleti..." -- sh -c "brew cleanup --prune=all &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia completata"
    else
        gum style --foreground "$GUM_COLOR_ERROR" --border "$GUM_BORDER_THICK" --padding "$GUM_ERROR_PADDING" "$GUM_SYMBOL_WARNING Errore pulizia"
    fi
fi

if [ "$do_doctor" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Esecuzione diagnostica sistema..." -- sh -c "brew doctor > /tmp/brew_doctor_output.txt 2>&1"
    doctor_exit=$?
    if [ $doctor_exit -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica completata"
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Diagnostica completata con warning"
    fi
    cat /tmp/brew_doctor_output.txt | gum style --foreground "$GUM_COLOR_MUTED"
    rm -f /tmp/brew_doctor_output.txt
fi

echo ""
gum style --border "$GUM_BORDER_DOUBLE" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --foreground "$GUM_COLOR_SUCCESS" --bold "Homebrew Update - Completato 🎉"
echo ""
