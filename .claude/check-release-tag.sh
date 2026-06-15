#!/bin/sh
# ============================================================================
# check-release-tag.sh — guardrail eseguito da un hook PreToolUse
# ----------------------------------------------------------------------------
# Scatta prima di un comando Bash che crea un git tag. Verifica le due
# invarianti di rilascio del progetto (vedi CLAUDE.md):
#   1. Il tag deve avere il prefisso 'v'.
#   2. La versione del tag deve coincidere con SCRIPT_VERSION in update.sh.
# Se una condizione non è rispettata, BLOCCA il comando (permissionDecision
# "deny") spiegando il motivo. Altrimenti lascia passare silenziosamente.
# Nota: intercetta solo le azioni di Claude, non i comandi manuali nel tuo shell.
# ============================================================================

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Considera solo la prima invocazione 'git tag ...', fermandosi ai separatori
after=$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+tag[[:space:]]+(.*)/\1/p')
[ -z "$after" ] && exit 0
after=$(printf '%s' "$after" | sed -E 's/[[:space:]]*(&&|\|\||;).*//')

# Cancellazione/elenco tag: non è una creazione di release, lascia passare
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

deny() {
    jq -n --arg r "$1" \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
}

# Invariante 1: prefisso 'v'
case "$tag" in
    v*) ;;
    *) deny "Tag '$tag' senza prefisso 'v'. Le regole del progetto richiedono tag tipo 'v$tag' (es. v1.13.1), altrimenti l'auto-update tag-based non funziona. Correggi il tag prima di procedere." ;;
esac

tag_version="${tag#v}"

# Legge SCRIPT_VERSION da update.sh
update_sh="${CLAUDE_PROJECT_DIR:-.}/update.sh"
[ -f "$update_sh" ] || exit 0   # non trovo il file: non blocco
script_version=$(grep -E '^SCRIPT_VERSION=' "$update_sh" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')

# Invariante 2: SCRIPT_VERSION == versione del tag
if [ -n "$script_version" ] && [ "$script_version" != "$tag_version" ]; then
    deny "Disallineamento versione: stai creando il tag '$tag' ($tag_version) ma SCRIPT_VERSION in update.sh è '$script_version'. Le due DEVONO coincidere (vedi CLAUDE.md). Aggiorna SCRIPT_VERSION a $tag_version come ultimo commit sul branch, poi ricrea il tag."
fi

exit 0
