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

# ===== SETUP AMBIENTE =====
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_VERSION="1.8.4"
TEST_MODE=false
[[ "$1" == "--test" ]] && TEST_MODE=true

SCRIPT_SOURCE="https://api.github.com/repos/andreacurto/homebrew/contents/brew-update.sh"

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
GUM_BORDER_THICK="thick"
GUM_PADDING="0 1"
GUM_MARGIN="0"
GUM_ERROR_PADDING="0 1"

# ===== TEST CONNESSIONE INTERNET =====
if [ "$TEST_MODE" = false ]; then
    if ! curl --head --silent --fail --max-time 3 https://www.google.com > /dev/null 2>&1; then
        echo ""
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Connessione internet assente."
        gum style --foreground "$GUM_COLOR_MUTED" "Lo script richiede una connessione internet attiva per funzionare."
        echo ""
        exit 1
    fi
fi

# File temporanei con PID
TMP_OUTDATED="/tmp/outdated_casks_$$.txt"
TMP_DOCTOR="/tmp/brew_doctor_$$.txt"
TMP_UPDATE="/tmp/brew_update_$$.sh"
trap 'rm -f "$TMP_OUTDATED" "$TMP_DOCTOR" "$TMP_UPDATE"' EXIT

# ===== AUTO-AGGIORNAMENTO SCRIPT =====
SCRIPT_LOCAL="$HOME/Shell/brew-update.sh"
script_update_checked=false
script_remote_version=""
script_update_declined=false

if curl -fsSL --max-time 5 "$SCRIPT_SOURCE" 2>/dev/null | python3 -c "import sys,json,base64; sys.stdout.buffer.write(base64.b64decode(json.load(sys.stdin)['content']))" > "$TMP_UPDATE" 2>/dev/null; then
    if [ -f "$SCRIPT_LOCAL" ] && [ -f "$TMP_UPDATE" ]; then
        local_hash=$(shasum "$SCRIPT_LOCAL" 2>/dev/null | cut -d' ' -f1)
        remote_hash=$(shasum "$TMP_UPDATE" 2>/dev/null | cut -d' ' -f1)
        script_remote_version=$(grep '^SCRIPT_VERSION=' "$TMP_UPDATE" 2>/dev/null | cut -d'"' -f2)

        if [ -n "$remote_hash" ] && [ "$local_hash" != "$remote_hash" ] && [ -n "$script_remote_version" ]; then
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
        script_update_checked=true
    fi
fi

# ===== MESSAGGIO INIZIALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → v$SCRIPT_VERSION 🚀"
echo ""

if [ "$TEST_MODE" = true ]; then
    gum style --bold "⚠️  MODALITÀ TEST - Dati simulati, nessuna modifica reale al sistema"
    echo ""
fi

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
    if [ "$TEST_MODE" = true ]; then
        sleep 0.5
        echo -e "google-chrome\nvisual-studio-code\n1password\nspotify\ndropbox" > "$TMP_OUTDATED"
    else
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni..." -- sh -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi > \"$TMP_OUTDATED\""
    fi
    outdated_casks=$(<"$TMP_OUTDATED")

    if [[ -n "$outdated_casks" ]]; then
        echo "Aggiornamenti app disponibili:"
        echo ""
        echo "$outdated_casks" | while IFS= read -r line; do
            gum style --foreground "$GUM_COLOR_MUTED" "  $GUM_SYMBOL_BULLET $line"
        done
        echo ""

        outdated_casks_array=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && outdated_casks_array+=("$line")
        done <<< "$outdated_casks"

        if [ "$use_greedy" = true ]; then
            selected_casks=""
            if [ ${#outdated_casks_array[@]} -gt 0 ]; then
                selected_casks=$(gum choose --no-limit \
                    --header="Seleziona le applicazioni da aggiornare:" \
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

                if [ "$TEST_MODE" = true ]; then
                    gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
                    echo ""
                    sleep 0.8

                    for app in "${selected_casks_array[@]}"; do
                        gum style --foreground "$GUM_COLOR_MUTED" "  ==> Downloading $app"
                        sleep 0.4
                        gum style --foreground "$GUM_COLOR_MUTED" "  ==> Installing $app"
                        sleep 0.6
                        gum style --foreground "$GUM_COLOR_MUTED" "  ==> Summary"
                        sleep 0.2
                    done
                    echo ""
                    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
                else
                    password_shown=false
                    brew upgrade --cask --greedy "${selected_casks_array[@]}" 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Summary)" | while IFS= read -r line; do
                        if [[ "$line" == "Password:"* ]]; then
                            echo "$line"
                            echo ""
                            password_shown=true
                        else
                            if [ "$password_shown" = true ]; then
                                echo -ne "\033[1A\033[2K\033[1A\033[2K"
                                password_shown=false
                            fi
                            gum style --foreground "$GUM_COLOR_MUTED" "  $line"
                        fi
                    done
                    echo ""
                    if [ ${pipestatus[1]} -eq 0 ]; then
                        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
                    else
                        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare l'aggiornamento delle applicazioni"
                    fi
                fi
            fi
        else
            if [ "$TEST_MODE" = true ]; then
                sleep 1.5
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni in corso..." -- brew upgrade --cask "${outdated_casks_array[@]}"
                if [ $? -eq 0 ]; then
                    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
                else
                    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare l'aggiornamento delle applicazioni"
                fi
            fi
        fi
    else
        gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Tutte le applicazioni sono aggiornate"
    fi
fi

# ===== AGGIORNAMENTO HOMEBREW =====
if [ "$do_update" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        sleep 1
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
    else
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento Homebrew..." -- sh -c "brew update &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare Homebrew"
        fi
    fi
fi

# ===== AGGIORNAMENTO STRUMENTI E LIBRERIE =====
if [ "$do_upgrade" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        sleep 1.2
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
    else
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento strumenti e librerie..." -- sh -c "brew upgrade &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare strumenti e librerie"
        fi
    fi
fi

# ===== RIMOZIONE PACCHETTI NON UTILIZZATI =====
if [ "$do_autoremove" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        sleep 0.8
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
    else
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione pacchetti non utilizzati..." -- sh -c "brew autoremove &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile rimuovere pacchetti non utilizzati"
        fi
    fi
fi

# ===== PULIZIA CACHE =====
if [ "$do_cleanup" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        sleep 1
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
    else
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache..." -- sh -c "brew cleanup --prune=all &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare la pulizia cache"
        fi
    fi
fi

# ===== DIAGNOSTICA SISTEMA =====
if [ "$do_doctor" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        sleep 0.8
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica sistema completata"
        echo ""
        echo "Your system is ready to brew." | gum style --foreground "$GUM_COLOR_MUTED"
    else
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
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Completato 🎉"
echo ""
