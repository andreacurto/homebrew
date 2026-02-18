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
# - Auto-aggiornamento script dalla repo GitHub
# - Disinstallazione con --uninstall (-u)

# ===== SETUP AMBIENTE =====
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_VERSION="1.12.0"
SCRIPT_REPO="andreacurto/homebrew"
INSTALL_DIR="$HOME/.brew"

# Verifica/installa gum se non presente
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# ===== CONFIGURAZIONE UI =====
# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"
GUM_COLOR_ERROR="9"
GUM_COLOR_WARNING="11"
GUM_COLOR_INFO="14"
GUM_COLOR_MUTED="244"

# Simboli
GUM_SYMBOL_SUCCESS="✔︎"
GUM_SYMBOL_ERROR="✘"
GUM_SYMBOL_WARNING="❖"
GUM_SYMBOL_INFO="❋"
GUM_SYMBOL_BULLET="→"

# Checkbox
GUM_CHECKBOX_SELECTED="■"
GUM_CHECKBOX_UNSELECTED="□"
GUM_CHECKBOX_CURSOR="□"

# Spinner e layout
GUM_SPINNER_TYPE="monkey"
GUM_BORDER_ROUNDED="rounded"
GUM_PADDING="0 1"
GUM_MARGIN="0"

# ===== DISINSTALLAZIONE =====
if [[ "$1" == "--uninstall" ]] || [[ "$1" == "-u" ]]; then
    echo ""
    if gum confirm "Vuoi disinstallare brew-update?" --default=false; then
        # Rimuovi alias da .zshrc
        if [ -f ~/.zshrc ]; then
            sed -i '' '/# Alias/d; /alias brew-update=/d' ~/.zshrc
        fi
        echo ""
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS brew-update disinstallato"
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Esegui il comando 'source ~/.zshrc' o riavvia il terminale per applicare le modifiche"
        echo ""
        rm -rf "$INSTALL_DIR"
    fi
    exit 0
fi

# ===== VERSIONE =====
if [[ "$1" == "--version" ]] || [[ "$1" == "-v" ]]; then
    echo ""
    echo "v$SCRIPT_VERSION"
    echo ""
    exit 0
fi

# ===== TEST CONNESSIONE INTERNET =====
if ! curl --head --silent --fail --max-time 3 https://www.google.com > /dev/null 2>&1; then
    echo ""
    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Connessione internet assente."
    gum style --foreground "$GUM_COLOR_MUTED" "Lo script richiede una connessione internet attiva per funzionare."
    echo ""
    exit 1
fi

# File temporanei con PID
TMP_OUTDATED="/tmp/outdated_casks_$$.txt"
TMP_DOCTOR="/tmp/brew_doctor_$$.txt"
TMP_UPDATE="/tmp/brew_update_$$.sh"
trap 'rm -f "$TMP_OUTDATED" "$TMP_DOCTOR" "$TMP_UPDATE"' EXIT

# ===== AUTO-AGGIORNAMENTO SCRIPT (tag-based) =====
SCRIPT_LOCAL="${0:A}"
script_remote_version=""
script_update_declined=false

# Controlla ultimo tag rilasciato su GitHub
latest_tag=$(curl -fsSL --max-time 5 "https://api.github.com/repos/$SCRIPT_REPO/tags" 2>/dev/null | python3 -c "
import sys, json
tags = json.load(sys.stdin)
if tags:
    print(tags[0]['name'])
" 2>/dev/null)

if [ -n "$latest_tag" ]; then
    script_remote_version="${latest_tag#v}"

    # Confronta versione locale vs tag remoto (semver)
    if [ "$script_remote_version" != "$SCRIPT_VERSION" ] && python3 -c "
v_local = list(map(int, '$SCRIPT_VERSION'.split('.')))
v_remote = list(map(int, '$script_remote_version'.split('.')))
exit(0 if v_remote > v_local else 1)
" 2>/dev/null; then
        # Scarica script dal tag specifico (non da HEAD master)
        if curl -fsSL --max-time 5 "https://raw.githubusercontent.com/$SCRIPT_REPO/$latest_tag/update.sh" > "$TMP_UPDATE" 2>/dev/null; then
            echo ""
            if gum confirm "È disponibile una nuova versione di brew-update (v$script_remote_version). Vuoi aggiornarla ora?" --default=true; then
                cp "$TMP_UPDATE" "$SCRIPT_LOCAL" 2>/dev/null
                chmod +x "$SCRIPT_LOCAL" 2>/dev/null

                echo ""
                gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING brew-update aggiornato da v$SCRIPT_VERSION a v$script_remote_version"
                gum style --foreground "$GUM_COLOR_MUTED" "Riavvia il comando 'brew-update' per utilizzare la nuova versione."
                echo ""
                exit 0
            else
                script_update_declined=true
            fi
        fi
    fi
fi

# ===== MESSAGGIO INIZIALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → v$SCRIPT_VERSION 🚀"
echo ""

# ===== SELEZIONE OPERAZIONI =====
selected_operations=$(gum choose --no-limit \
    --header="Seleziona le operazioni da eseguire:" \
    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
    --selected="Aggiornamento Homebrew,Aggiornamento applicazioni,Aggiornamento strumenti e librerie,Rimozione pacchetti non utilizzati,Pulizia cache,Diagnostica sistema" \
    "Aggiornamento Homebrew" \
    "Aggiornamento applicazioni" \
    "Aggiornamento strumenti e librerie" \
    "Rimozione pacchetti non utilizzati" \
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

while IFS= read -r operation; do
    case "$operation" in
        "Aggiornamento Homebrew") do_update=true ;;
        "Aggiornamento applicazioni") do_cask_upgrade=true ;;
        "Aggiornamento strumenti e librerie") do_upgrade=true ;;
        "Rimozione pacchetti non utilizzati") do_autoremove=true ;;
        "Pulizia cache") do_cleanup=true ;;
        "Diagnostica sistema") do_doctor=true ;;
    esac
done <<< "$selected_operations"

if [ "$do_cask_upgrade" = true ]; then
    if gum confirm "Includere anche app con auto-aggiornamento?" --default=false; then
        use_greedy=true
    fi
fi

# ===== MESSAGGIO VERSIONE SCRIPT =====
if [ "$script_update_declined" = true ] && [ -n "$script_remote_version" ]; then
    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Nuova versione v$script_remote_version disponibile (corrente: v$SCRIPT_VERSION)"
    echo ""
fi

# ===== AGGIORNAMENTO APPLICAZIONI =====
if [ "$do_cask_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Controllo aggiornamenti applicazioni..." -- sh -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi > \"$TMP_OUTDATED\""
    outdated_casks=$(<"$TMP_OUTDATED")

    if [[ -n "$outdated_casks" ]]; then
        outdated_casks_array=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && outdated_casks_array+=("$line")
        done <<< "$outdated_casks"

        if [ "$use_greedy" = true ]; then
            selected_casks=""
            if [ ${#outdated_casks_array[@]} -gt 0 ]; then
                selected_casks=$(gum choose --no-limit \
                    --header="Seleziona le applicazioni con aggiornamenti disponibili che vuoi aggiornare:" \
                    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
                    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
                    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
                    "${outdated_casks_array[@]}")
            fi

            selected_casks_array=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && selected_casks_array+=("$line")
            done <<< "$selected_casks"

            if [ ${#selected_casks_array[@]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessuna applicazione selezionata"
            else
                echo "Aggiornamento applicazioni in corso (incluse app con auto-aggiornamento)..."
                echo ""
                printf '\033[38;5;244m'
                brew upgrade --cask --greedy "${selected_casks_array[@]}"
                brew_exit=$?
                printf '\033[0m'
                echo ""
                if [ $brew_exit -eq 0 ]; then
                    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
                else
                    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare l'aggiornamento delle applicazioni"
                fi
            fi
        else
            gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni in corso..." -- brew upgrade --cask "${outdated_casks_array[@]}"
            if [ $? -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare l'aggiornamento delle applicazioni"
            fi
        fi
    else
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Tutte le applicazioni sono aggiornate"
    fi
fi

# ===== AGGIORNAMENTO HOMEBREW =====
if [ "$do_update" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento Homebrew..." -- sh -c "brew update &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare Homebrew"
    fi
fi

# ===== AGGIORNAMENTO STRUMENTI E LIBRERIE =====
if [ "$do_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento strumenti e librerie..." -- sh -c "brew upgrade &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare strumenti e librerie"
    fi
fi

# ===== RIMOZIONE PACCHETTI NON UTILIZZATI =====
if [ "$do_autoremove" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione pacchetti non utilizzati..." -- sh -c "brew autoremove &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile rimuovere pacchetti non utilizzati"
    fi
fi

# ===== PULIZIA CACHE =====
if [ "$do_cleanup" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache..." -- sh -c "brew cleanup --prune=all &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare la pulizia cache"
    fi
fi

# ===== DIAGNOSTICA SISTEMA =====
if [ "$do_doctor" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Diagnostica sistema..." -- sh -c "brew doctor > \"$TMP_DOCTOR\" 2>&1"
    doctor_exit=$?
    if [ $doctor_exit -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica sistema completata"
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Diagnostica sistema completata con avvisi"
    fi
    echo ""
    gum style --foreground "$GUM_COLOR_MUTED" < "$TMP_DOCTOR"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Completato 🎉"
echo ""
