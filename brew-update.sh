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
SCRIPT_VERSION="1.3.0"

# URL sorgente per auto-aggiornamento script
SCRIPT_SOURCE="https://raw.githubusercontent.com/andreacurto/homebrew/master/brew-update.sh"

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
if curl -fsSL --max-time 5 "$SCRIPT_SOURCE" -o "$TMP_UPDATE" 2>/dev/null; then
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
GUM_SYMBOL_WARNING="✘"    # Errori e warning
GUM_SYMBOL_BULLET="→"     # Elementi di lista
GUM_SYMBOL_SKIP="❋"       # Operazioni saltate

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
    if gum confirm "Includere anche applicazioni con auto-update (opzione --greedy)?" --default=false; then
        use_greedy=true
    fi
fi

# ===== MESSAGGIO VERSIONE SCRIPT =====
# Mostra lo stato di aggiornamento dello script all'utente
if [ "$script_was_updated" = true ] && [ -n "$script_remote_version" ]; then
    echo ""
    gum style --foreground "$GUM_COLOR_INFO" "Script aggiornato alla versione v$script_remote_version"
    echo ""
elif [ "$script_update_checked" = true ]; then
    echo ""
    gum style --foreground "$GUM_COLOR_INFO" "Script aggiornato (v$SCRIPT_VERSION)"
    echo ""
fi

# ===== AGGIORNAMENTO APPLICAZIONI =====
# Controlla e aggiorna applicazioni installate tramite Homebrew Cask
# Mostra il progresso di download per ogni app
if [ "$do_cask_upgrade" = true ]; then
    # Controlla quali app hanno aggiornamenti disponibili
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Controllo applicazioni obsolete..." -- sh -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi > \"$TMP_OUTDATED\""
    outdated_casks=$(<"$TMP_OUTDATED")

    if [[ -n "$outdated_casks" ]]; then
        # Mostra lista app da aggiornare
        gum style --foreground "$GUM_COLOR_WARNING" "Trovate applicazioni da aggiornare:"
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
            # Aggiorna includendo app con auto-update
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni (incluso auto-update)..."
            echo ""
            brew upgrade --cask --greedy "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            echo ""
            # pipestatus[1] cattura exit code del primo comando della pipeline (brew upgrade)
            if [ ${pipestatus[1]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        else
            # Aggiorna solo app senza auto-update
            gum style --foreground "$GUM_COLOR_INFO" "Aggiornamento applicazioni..."
            echo ""
            brew upgrade --cask "${outdated_casks_array[@]}" 2>&1 | grep -E "(==> Downloading|==> Installing|==> Upgrading|==> Pouring|==> Summary)" | while IFS= read -r line; do
                gum style --foreground "$GUM_COLOR_MUTED" "  $line"
            done
            echo ""
            if [ ${pipestatus[1]} -eq 0 ]; then
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_WARNING Errore aggiornamento applicazioni"
            fi
        fi
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_SKIP Nessuna applicazione da aggiornare"
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
    gum spin --spinner "$GUM_SPINNER_TYPE" --title "Esecuzione diagnostica sistema..." -- sh -c "brew doctor > \"$TMP_DOCTOR\" 2>&1"
    doctor_exit=$?
    if [ $doctor_exit -eq 0 ]; then
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica completata"
    else
        gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Diagnostica completata con warning"
    fi
    # Mostra output diagnostica in grigio
    echo ""
    gum style --foreground "$GUM_COLOR_MUTED" < "$TMP_DOCTOR"
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Completato 🎉"
echo ""
