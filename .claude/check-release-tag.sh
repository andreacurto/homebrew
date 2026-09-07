#!/bin/sh
# ============================================================================
# check-release-tag.sh — guardrail eseguito da un hook PreToolUse
# ----------------------------------------------------------------------------
# Scatta prima di un comando Bash che crea un git tag e lo BLOCCA sempre
# (permissionDecision "deny").
#
# Motivo: durante lo sviluppo di Donkey 2.0 non si creano tag (vedi
# WORKFLOW.md). Gli utenti della 1.x ricevono gli aggiornamenti proprio
# tramite i tag: crearne uno per sbaglio consegnerebbe loro codice incompleto.
#
# Elencare e cancellare tag resta permesso.
# Nota: intercetta solo le azioni di Claude, non i comandi manuali nel tuo shell.
# ============================================================================

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Considera solo la prima invocazione 'git tag ...', fermandosi ai separatori
after=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+tag[[:space:]]+(.*)/\1/p')
[ -z "$after" ] && exit 0
after=$(printf '%s' "$after" | sed -E 's/[[:space:]]*(&&|\|\||;).*//')

# Cancellazione/elenco tag: non è una creazione, lascia passare
case " $after " in
    *" -d "*|*" --delete "*|*" -l "*|*" --list "*) exit 0 ;;
esac

# Primo token non-flag = nome del tag
tag=""
for tok in $after; do
    case "$tok" in
        -*) continue ;;
        *) tag="$tok"; break ;;
    esac
done
[ -z "$tag" ] && exit 0   # 'git tag' senza argomenti: elenca, non crea

reason="Creazione del tag '$tag' bloccata. Durante lo sviluppo di Donkey 2.0 non si creano tag: gli utenti della 1.x ricevono gli aggiornamenti tramite i tag, quindi un tag li raggiungerebbe con codice incompleto (vedi WORKFLOW.md). Il primo tag sarà v2.0.0, in un'attività dedicata e con approvazione esplicita di Andrea."

jq -n --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
