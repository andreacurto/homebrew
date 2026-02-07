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
SCRIPT_VERSION="1.8.2"

# Modalità test (attiva con --test)
TEST_MODE=false
[[ "$1" == "--test" ]] && TEST_MODE=true

# URL sorgente per auto-aggiornamento script (API GitHub, no cache CDN)
SCRIPT_SOURCE="https://api.github.com/repos/andreacurto/homebrew/contents/brew-update.sh"

# Verifica/installa gum se non presente (necessario per l'interfaccia)
if ! command -v gum &> /dev/null; then
    brew install gum &> /dev/null
fi

# ===== TEST CONNESSIONE INTERNET =====
# Verifica connessione internet prima di procedere (skip in TEST mode)
if [ "$TEST_MODE" = false ]; then
    if ! curl --head --silent --fail --max-time 3 https://www.google.com > /dev/null 2>&1; then
        echo ""
        gum style --foreground "9" --border "thick" --padding "0 1" "✘ Connessione internet assente. Lo script richiede una connessione internet attiva per funzionare."
        echo ""
        exit 1
    fi
fi

# File temporanei con PID per evitare conflitti tra istanze concorrenti
TMP_OUTDATED="/tmp/outdated_casks_$$.txt"
TMP_DOCTOR="/tmp/brew_doctor_$$.txt"
TMP_UPDATE="/tmp/brew_update_$$.sh"

# Pulizia file temporanei all'uscita (normale, Ctrl+C, errori)
trap 'rm -f "$TMP_OUTDATED" "$TMP_DOCTOR" "$TMP_UPDATE"' EXIT

# ===== AUTO-AGGIORNAMENTO SCRIPT =====
# Scarica l'ultima versione dalla repo GitHub e chiede conferma prima di aggiornare
# In caso di errore (no internet, timeout, etc.) lo script prosegue normalmente
SCRIPT_LOCAL="$HOME/Shell/brew-update.sh"
script_was_updated=false
script_update_checked=false
script_remote_version=""
script_update_declined=false
if curl -fsSL --max-time 5 "$SCRIPT_SOURCE" 2>/dev/null | python3 -c "import sys,json,base64; sys.stdout.buffer.write(base64.b64decode(json.load(sys.stdin)['content']))" > "$TMP_UPDATE" 2>/dev/null; then
    if [ -f "$SCRIPT_LOCAL" ] && [ -f "$TMP_UPDATE" ]; then
        local_hash=$(shasum "$SCRIPT_LOCAL" 2>/dev/null | cut -d' ' -f1)
        remote_hash=$(shasum "$TMP_UPDATE" 2>/dev/null | cut -d' ' -f1)
        script_remote_version=$(grep '^SCRIPT_VERSION=' "$TMP_UPDATE" 2>/dev/null | cut -d'"' -f2)

        # Se versione remota diversa, chiedi conferma all'utente
        if [ -n "$remote_hash" ] && [ "$local_hash" != "$remote_hash" ] && [ -n "$script_remote_version" ]; then
            echo ""
            if gum confirm "È disponibile una nuova versione di brew-update (v$script_remote_version). Vuoi aggiornarla ora?" --default=true; then
                cp "$TMP_UPDATE" "$SCRIPT_LOCAL" 2>/dev/null
                chmod +x "$SCRIPT_LOCAL" 2>/dev/null

                # Mostra messaggio di info e termina
                echo ""
                gum style --foreground "$GUM_COLOR_INFO" "$GUM_SYMBOL_INFO brew-update aggiornato da v$SCRIPT_VERSION a v$script_remote_version"
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
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → v$SCRIPT_VERSION 🚀"
echo ""

# Banner modalità test
if [ "$TEST_MODE" = true ]; then
    gum style --bold "⚠️  MODALITÀ TEST - Dati simulati, nessuna modifica reale al sistema"
    echo ""
fi

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
# Mostra warning solo se utente ha rifiutato l'aggiornamento
if [ "$script_update_declined" = true ] && [ -n "$script_remote_version" ]; then
    # Nuova versione disponibile ma utente ha rifiutato
    gum style --foreground "$GUM_COLOR_WARNING" "$GUM_SYMBOL_WARNING Nuova versione v$script_remote_version disponibile (corrente: v$SCRIPT_VERSION)"
    echo ""
fi

# ===== AGGIORNAMENTO APPLICAZIONI =====
# Controlla e aggiorna applicazioni installate tramite Homebrew Cask
# Mostra il progresso di download per ogni app
if [ "$do_cask_upgrade" = true ]; then
    # Controlla quali app hanno aggiornamenti disponibili
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: inietta dati fake
        sleep 0.5
        echo -e "google-chrome\nvisual-studio-code\n1password\nspotify\ndropbox" > "$TMP_OUTDATED"
    else
        # Modalità normale: esegue brew outdated
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento applicazioni..." -- sh -c "if [ \"$use_greedy\" = true ]; then brew outdated --cask --greedy --quiet; else brew outdated --cask --quiet; fi > \"$TMP_OUTDATED\""
    fi
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
                # Aggiorna app selezionate con greedy (output filtrato per vedere password/progresso)
                echo "Aggiornamento applicazioni in corso (incluse app con auto-aggiornamento)..."
                echo ""

                if [ "$TEST_MODE" = true ]; then
                    # Modalità test: simula richiesta password visiva
                    gum style --foreground "$GUM_COLOR_WARNING" "🔒 Password amministratore richiesta (simulata in test)"
                    echo ""
                    sleep 0.8

                    # Modalità test: simula output brew realistico
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
                    # Modalità normale: esegue brew upgrade
                    password_shown=false
                    brew upgrade --cask --greedy "${selected_casks_array[@]}" 2>&1 | grep -E "(Password:|==> Downloading|==> Installing|==> Upgrading|==> Summary)" | while IFS= read -r line; do
                        if [[ "$line" == "Password:"* ]]; then
                            echo "$line"
                            echo ""
                            password_shown=true
                        else
                            # Cancella "Password:" dopo che l'utente l'ha inserita
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
            # Aggiorna solo app senza auto-update (non richiede password di solito)
            if [ "$TEST_MODE" = true ]; then
                # Modalità test: simula con spinner e delay
                sleep 1.5
                gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Applicazioni aggiornate"
            else
                # Modalità normale: esegue brew upgrade
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
# Aggiorna l'indice dei pacchetti disponibili su Homebrew
# Necessario per avere le ultime versioni disponibili
if [ "$do_update" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula con delay
        sleep 1
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
    else
        # Modalità normale: esegue brew update
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento Homebrew..." -- sh -c "brew update &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Homebrew aggiornato"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare Homebrew"
        fi
    fi
fi

# ===== AGGIORNAMENTO STRUMENTI E LIBRERIE =====
# Aggiorna tutti i pacchetti CLI installati (non le applicazioni)
# Es: node, gh, oh-my-posh, gum, etc.
if [ "$do_upgrade" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula con delay
        sleep 1.2
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
    else
        # Modalità normale: esegue brew upgrade
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Aggiornamento strumenti e librerie..." -- sh -c "brew upgrade &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Strumenti e librerie aggiornati"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile aggiornare strumenti e librerie"
        fi
    fi
fi

# ===== RIMOZIONE PACCHETTI NON UTILIZZATI =====
# Rimuove pacchetti installati come dipendenze ma non più necessari
# Libera spazio rimuovendo pacchetti inutilizzati
if [ "$do_autoremove" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula con delay
        sleep 0.8
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
    else
        # Modalità normale: esegue brew autoremove
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Rimozione pacchetti non utilizzati..." -- sh -c "brew autoremove &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pacchetti non utilizzati rimossi"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile rimuovere pacchetti non utilizzati"
        fi
    fi
fi

# ===== PULIZIA CACHE =====
# Rimuove vecchie versioni di pacchetti e svuota la cache di download
# --prune=all rimuove tutti i file di cache, anche quelli recenti
if [ "$do_cleanup" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula con delay
        sleep 1
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
    else
        # Modalità normale: esegue brew cleanup
        gum spin --spinner "$GUM_SPINNER_TYPE" --title "Pulizia cache..." -- sh -c "brew cleanup --prune=all &>/dev/null"
        if [ $? -eq 0 ]; then
            gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Pulizia cache completata"
        else
            gum style --foreground "$GUM_COLOR_ERROR" "$GUM_SYMBOL_ERROR Impossibile completare la pulizia cache"
        fi
    fi
fi

# ===== DIAGNOSTICA SISTEMA =====
# Esegue brew doctor per identificare potenziali problemi
# Mostra l'output completo della diagnostica
if [ "$do_doctor" = true ]; then
    if [ "$TEST_MODE" = true ]; then
        # Modalità test: simula output diagnostica
        sleep 0.8
        gum style --foreground "$GUM_COLOR_SUCCESS" "$GUM_SYMBOL_SUCCESS Diagnostica sistema completata"
        echo ""
        echo "Your system is ready to brew." | gum style --foreground "$GUM_COLOR_MUTED"
    else
        # Modalità normale: esegue brew doctor
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
fi

# ===== MESSAGGIO FINALE =====
echo ""
gum style --border "$GUM_BORDER_ROUNDED" --border-foreground "$GUM_COLOR_MUTED" --padding "$GUM_PADDING" --margin "$GUM_MARGIN" --bold "Homebrew Update → Completato 🎉"
echo ""
