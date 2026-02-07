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
# Assicura che Homebrew sia nel PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Versione script (usata per messaggio di stato)
SCRIPT_VERSION="1.5.3"

# URL sorgente per auto-aggiornamento script (API GitHub, no cache CDN)
SCRIPT_SOURCE="https://api.github.com/repos/andreacurto/homebrew/contents/brew-update.sh"

# Verifica/installa gum se non presente (necessario per l'interfaccia)
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# File temporanei con PID per evitare conflitti tra istanze concorrenti
TMP_OUTDATED="/tmp/outdated_casks_$$.txt"
TMP_DOCTOR="/tmp/brew_doctor_$$.txt"
TMP_UPDATE="/tmp/brew_update_$$.sh"

# Pulizia file temporanei all'uscita (normale, Ctrl+C, errori)
trap 'rm -f "$TMP_OUTDATED" "$TMP_DOCTOR" "$TMP_UPDATE"' EXIT

# ===== AUTO-AGGIORNAMENTO SCRIPT =====
# Scarica l'ultima versione dalla repo GitHub e aggiorna silenziosamente
# In caso di errore (no internet, timeout, etc.) lo script prosegue normalmente
SCRIPT_LOCAL="$HOME/Shell/brew-update.sh"
script_was_updated=false
script_update_checked=false
script_remote_version=""
if curl -fsSL --max-time 5 "$SCRIPT_SOURCE" 2>/dev/null | python3 -c "import sys,json,base64; sys.stdout.buffer.write(base64.b64decode(json.load(sys.stdin)['content']))" > "$TMP_UPDATE" 2>/dev/null; then
    if [ -f "$SCRIPT_LOCAL" ] && [ -f "$TMP_UPDATE" ]; then
        local_hash=$(shasum "$SCRIPT_LOCAL" 2>/dev/null | cut -d' ' -f1)
        remote_hash=$(shasum "$TMP_UPDATE" 2>/dev/null | cut -d' ' -f1)
        script_remote_version=$(grep '^SCRIPT_VERSION=' "$TMP_UPDATE" 2>/dev/null | cut -d'"' -f2)
        if [ -n "$remote_hash" ] && [ "$local_hash" != "$remote_hash" ]; then
            cp "$TMP_UPDATE" "$SCRIPT_LOCAL" 2>/dev/null
            chmod +x "$SCRIPT_LOCAL" 2>/dev/null
            script_was_updated=true
        fi
        script_update_checked=true
    fi
fi

# ===== CONFIGURAZIONE UI =====
# Definisce colori, simboli e stili per l'interfaccia Gum

# Colori (256 terminal colors)
GUM_COLOR_SUCCESS="10"    # Operazioni completate con successo
GUM_COLOR_ERROR="9"       # Messaggi di errore
GUM_COLOR_WARNING="11"    # Warning e operazioni saltate
GUM_COLOR_INFO="14"       # Messaggi informativi durante operazioni
GUM_COLOR_MUTED="244"     # Output secondario e testo attenuato

# Simboli
GUM_SYMBOL_SUCCESS="✔︎"    # Operazioni completate
GUM_SYMBOL_ERROR="✘"      # Errori
GUM_SYMBOL_WARNING="❖"    # Situazioni che richiedono attenzione
GUM_SYMBOL_INFO="❋"       # Informazioni neutre
GUM_SYMBOL_BULLET="→"     # Elementi di lista

# Checkbox
GUM_CHECKBOX_SELECTED="■"      # Opzione selezionata nei menu
GUM_CHECKBOX_UNSELECTED="□"    # Opzione non selezionata nei menu
GUM_CHECKBOX_CURSOR="□"        # Indicatore posizione cursore

# Spinner
GUM_SPINNER_TYPE="monkey"      # Tipo animazione durante operazioni

# Bordi
GUM_BORDER_ROUNDED="rounded"   # Stile bordo per box principali
GUM_BORDER_DOUBLE="double"     # Stile bordo alternativo
GUM_BORDER_THICK="thick"       # Stile bordo spesso

# Layout
GUM_PADDING="0 1"              # Spaziatura interna box (verticale orizzontale)
GUM_MARGIN="0"                 # Margine esterno box
GUM_ERROR_PADDING="0 1"        # Spaziatura messaggi di errore

# ===== MESSAGGIO INIZIALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Inizio 🚀"
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
    --selected="Aggiornamento Homebrew,Aggiornamento applicazioni,Aggiornamento strumenti e librerie,Rimozione pacchetti non utilizzati,Pulizia cache,Diagnostica sistema" \
    "Aggiornamento Homebrew" \
    "Aggiornamento applicazioni" \
    "Aggiornamento strumenti e librerie" \
    "Rimozione pacchetti non utilizzati" \
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
        "Aggiornamento Homebrew") do_update=true ;;
        "Aggiornamento applicazioni") do_cask_upgrade=true ;;
        "Aggiornamento strumenti e librerie") do_upgrade=true ;;
        "Rimozione pacchetti non utilizzati") do_autoremove=true ;;
        "Pulizia cache") do_cleanup=true ;;
        "Diagnostica sistema") do_doctor=true ;;
    esac
done <<< "$selected_operations"

# Se selezionato aggiornamento app, chiede se includere app con auto-update
# L'opzione --greedy forza l'aggiornamento anche di app che si aggiornano da sole
if [ "$do_cask_upgrade" = true ]; then
    if gum confirm "Includere anche app con auto-aggiornamento?" --default=false; then
        use_greedy=true
    fi
fi

# ===== MESSAGGIO VERSIONE SCRIPT =====
# Mostra lo stato di aggiornamento dello script all'utente
if [ "$script_was_updated" = true ] && [ -n "$script_remote_version" ]; then
    if [ "$SCRIPT_VERSION" != "$script_remote_version" ]; then
        gum style --foreground "$GUM_COLOR_MUTED" "$GUM_SYMBOL_SUCCESS brew-update aggiornato: v$SCRIPT_VERSION → v$script_remote_version"
    else
        gum style --foreground "$GUM_COLOR_MUTED" "$GUM_SYMBOL_SUCCESS brew-update aggiornato alla versione v$script_remote_version"
    fi
    echo ""
elif [ "$script_update_checked" = true ]; then
    gum style --foreground "$GUM_COLOR_MUTED" "$GUM_SYMBOL_INFO brew-update: v$SCRIPT_VERSION"
    echo ""
fi

# ===== AGGIORNAMENTO APPLICAZIONI =====
# Controlla e aggiorna applicazioni installate tramite Homebrew Cask
# Mostra il progresso di download per ogni app
if [ "$do_cask_upgrade" = true ]; then
    # Controlla quali app hanno aggiornamenti disponibili
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni..." -- sh -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi > \"$TMP_OUTDATED\""
    outdated_casks=$(<"$TMP_OUTDATED")

    if [[ -n "$outdated_casks" ]]; then
        # Mostra lista app da aggiornare
        echo "Aggiornamenti app disponibili:"
        echo ""
        echo "$outdated_casks" | while IFS= read -r line; do
            gum style --foreground "$GUM_COLOR_MUTED" "  $GUM_SYMBOL_BULLET $line"
        done
        echo ""

        # Converte lista in array bash/zsh compatible
        outdated_casks_array=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && outdated_casks_array+=("$line")
        done <<< "$outdated_casks"

        if [ "$use_greedy" = true ]; then
            # Selezione interattiva app da aggiornare
            selected_casks=""
            if [ ${#outdated_casks_array[@]} -gt 0 ]; then
                selected_casks=$(gum choose --no-limit \
                    --header="Seleziona le applicazioni da aggiornare:" \
                    --cursor-prefix="$GUM_CHECKBOX_CURSOR " \
                    --selected-prefix="$GUM_CHECKBOX_SELECTED " \
                    --unselected-prefix="$GUM_CHECKBOX_UNSELECTED " \
                    "${outdated_casks_array[@]}")
            fi

            # Converte selezione in array
            selected_casks_array=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && selected_casks_array+=("$line")
            done <<< "$selected_casks"

            # Se nessuna app selezionata, salta
            if [ ${#selected_casks_array[@]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO Nessuna applicazione selezionata"
            else
                # Richiedi password sudo prima di avviare lo spinner
                gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Alcune app potrebbero richiedere la password di amministratore"
                sudo -v
                echo ""

                # Aggiorna app selezionate con greedy
                gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni in corso (incluse app con auto-aggiornamento)..." -- brew upgrade --cask --greedy "${selected_casks_array[@]}"
                if [ $? -eq 0 ]; then
                    gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
                else
                    gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare l'aggiornamento delle applicazioni"
                fi
            fi
        else
            # Richiedi password sudo prima di avviare lo spinner
            gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Alcune app potrebbero richiedere la password di amministratore"
            sudo -v
            echo ""

            # Aggiorna solo app senza auto-update
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
# Aggiorna l'indice dei pacchetti disponibili su Homebrew
# Necessario per avere le ultime versioni disponibili
if [ "$do_update" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento Homebrew..." -- sh -c "brew update &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare Homebrew"
    fi
fi

# ===== AGGIORNAMENTO STRUMENTI E LIBRERIE =====
# Aggiorna tutti i pacchetti CLI installati (non le applicazioni)
# Es: node, gh, oh-my-posh, gum, etc.
if [ "$do_upgrade" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento strumenti e librerie..." -- sh -c "brew upgrade &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare strumenti e librerie"
    fi
fi

# ===== RIMOZIONE PACCHETTI NON UTILIZZATI =====
# Rimuove pacchetti installati come dipendenze ma non più necessari
# Libera spazio rimuovendo pacchetti inutilizzati
if [ "$do_autoremove" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione pacchetti non utilizzati..." -- sh -c "brew autoremove &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile rimuovere pacchetti non utilizzati"
    fi
fi

# ===== PULIZIA CACHE =====
# Rimuove vecchie versioni di pacchetti e svuota la cache di download
# --prune=all rimuove tutti i file di cache, anche quelli recenti
if [ "$do_cleanup" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache..." -- sh -c "brew cleanup --prune=all &>/dev/null"
    if [ $? -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
    else
        gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare la pulizia cache"
    fi
fi

# ===== DIAGNOSTICA SISTEMA =====
# Esegue brew doctor per identificare potenziali problemi
# Mostra l'output completo della diagnostica
if [ "$do_doctor" = true ]; then
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Diagnostica sistema..." -- sh -c "brew doctor > \"$TMP_DOCTOR\" 2>&1"
    doctor_exit=$?
    if [ $doctor_exit -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica sistema completata"
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Diagnostica sistema completata con avvisi"
    fi
    # Mostra output diagnostica in grigio
    echo ""
    gum style --foreground "$GUM_COLOR_MUTED" < "$TMP_DOCTOR"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Completato 🎉"
echo ""
