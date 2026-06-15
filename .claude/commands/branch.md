---
description: Avvia una modifica — presenta il piano di rilascio e crea il branch (feature/ o fix/)
argument-hint: [descrizione della modifica]
---

Stai avviando una nuova modifica al progetto. Segui il "Processo di Sviluppo" di `CLAUDE.md`, passi 0 e 1.

Descrizione della modifica richiesta dall'utente: $ARGUMENTS

## Passi da eseguire

1. **Sincronizzazione (passo 0).** Per prima cosa allinea `master` al remoto:
   ```bash
   git fetch --all --tags --prune
   git checkout master
   git pull --ff-only
   ```
   Se `master` è disallineato o ci sono modifiche locali, fermati e segnala la situazione all'utente prima di procedere.

2. **Valuta il tipo di branch** in autonomia, in base alla natura della modifica:
   - `feature/` → nuova funzionalità o modifica significativa → bump **MINOR**
   - `fix/` → bug fix, correzione, tweak → bump **PATCH**

3. **Presenta il piano di rilascio** all'utente e **attendi approvazione** prima di toccare codice. Il piano deve includere:
   - **Tipo e nome branch**: descrittivo e conciso (es. `fix/greedy-cask-update`)
   - **Elenco commit previsti**: lista dei commit pianificati con breve descrizione
   - **Versione target**: bump previsto (PATCH/MINOR/MAJOR) a partire dall'attuale `SCRIPT_VERSION` in `update.sh`

4. **Dopo l'OK dell'utente**, crea il branch a partire da `master` aggiornato:
   ```bash
   git checkout -b <tipo>/<nome>
   ```

5. Da qui in poi lavora in autonomia (commit + push automatici) come da workflow, finché non sarà il momento di `/release`.

**Non** creare il branch prima di aver presentato il piano e ricevuto l'approvazione.
