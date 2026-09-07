#!/bin/sh
# ============================================================================
# session-fetch.sh — eseguito dall'hook SessionStart di Claude Code
# ----------------------------------------------------------------------------
# 1. Fa SEMPRE per prima cosa il fetch della repo remota (tag inclusi).
# 2. Confronta il branch locale con il suo corrispettivo remoto.
# 3. Se c'è disallineamento, emette un riassunto come contesto per Claude,
#    con l'istruzione di riassumere all'utente e CHIEDERE cosa fare.
#    Lo script NON esegue mai pull/push da solo.
# ============================================================================

# --- 1. Fetch (non blocca mai l'avvio: se manca rete/remote, prosegue) ------
git fetch --all --tags --prune >/dev/null 2>&1 || true

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0   # non in un repo git: niente da fare

# --- 2. Determina il ref remoto con cui confrontarsi ------------------------
remote_ref=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
if [ -z "$remote_ref" ]; then
    if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
        remote_ref="origin/$branch"
    else
        # Ramo nuovo non ancora pushato: il confronto sensato è con develop,
        # da cui nascono tutte le attività (vedi WORKFLOW.md).
        remote_ref="origin/develop"
    fi
fi

counts=$(git rev-list --left-right --count "$remote_ref"...HEAD 2>/dev/null)
behind=$(printf '%s' "$counts" | awk '{print $1}')
ahead=$(printf '%s' "$counts" | awk '{print $2}')
behind=${behind:-0}
ahead=${ahead:-0}

# --- 3. Allineato: nessun contesto da iniettare ----------------------------
if [ "$behind" -eq 0 ] && [ "$ahead" -eq 0 ]; then
    exit 0
fi

summary="Stato git all'avvio sessione — branch locale: '$branch', confronto con '$remote_ref'."

if [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ]; then
    # Locale INDIETRO rispetto al remoto
    commits=$(git log --oneline --no-decorate HEAD.."$remote_ref" 2>/dev/null)
    summary="$summary
Il branch locale è INDIETRO di $behind commit rispetto al remoto. Commit presenti sul remoto ma non in locale:
$commits

ISTRUZIONE PER CLAUDE: riassumi all'utente cosa è cambiato sul remoto e CHIEDI esplicitamente se vuole fare 'git pull' per allinearsi oppure mantenere lo stato attuale. NON eseguire il pull senza conferma."
elif [ "$ahead" -gt 0 ] && [ "$behind" -eq 0 ]; then
    # Locale AVANTI rispetto al remoto
    if [ "$branch" = "main" ]; then
        summary="$summary
Il branch main locale è AVANTI di $ahead commit non pushati rispetto al remoto. main è il ramo stabile pubblicato: non ci si sviluppa e deve restare allineato al remoto (vedi WORKFLOW.md). ISTRUZIONE PER CLAUDE: segnala la cosa all'utente e chiedi come vuole sistemare la situazione. Non pushare su main senza conferma esplicita."
    elif [ "$branch" = "develop" ]; then
        summary="$summary
Il branch develop locale è AVANTI di $ahead commit non pushati rispetto al remoto: probabilmente è un'attività appena chiusa con squash merge e non ancora pushata. ISTRUZIONE PER CLAUDE: segnala lo stato all'utente e chiedi se vuole pushare."
    else
        summary="$summary
Il branch '$branch' è AVANTI di $ahead commit rispetto al remoto: probabilmente è un'attività in corso su un ramo dedicato, è normale. ISTRUZIONE PER CLAUDE: segnala solo brevemente lo stato, nessuna azione necessaria."
    fi
else
    # Storie DIVERGENTI
    summary="$summary
Il branch è DIVERGENTE: $behind commit indietro e $ahead avanti rispetto a '$remote_ref'. ISTRUZIONE PER CLAUDE: riassumi la situazione all'utente e chiedi come procedere (pull/rebase/mantenere), senza agire da solo."
fi

# Emette il riassunto come contesto per Claude (JSON se jq c'è, altrimenti testo)
if command -v jq >/dev/null 2>&1; then
    jq -n --arg ctx "$summary" \
        '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ctx}}'
else
    printf '%s\n' "$summary"
fi
