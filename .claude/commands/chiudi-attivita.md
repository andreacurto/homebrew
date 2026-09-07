---
description: Chiude l'attività corrente — squash merge del ramo in develop, dopo conferma
---

Stai chiudendo l'attività sviluppata sul ramo corrente, portandola dentro `develop`. Segui
`WORKFLOW.md`, sezione "Il ciclo di una modifica", passi 5 e 6. `WORKFLOW.md` è la fonte di verità:
se qualcosa qui contraddice quel file, vince `WORKFLOW.md`.

⚠️ **Questo comando non tocca mai `main` e non crea mai tag.** Il merge in `main` e la creazione di
tag avvengono solo alla v2.0.0, in un'attività dedicata e con approvazione esplicita di Andrea.

## Passi da eseguire

1. **Verifica che sia tutto verde.** Non si chiude un'attività con i controlli rossi:
   ```bash
   make lint
   make test
   ```
   Se qualcosa fallisce, **fermati**: mostra l'errore all'utente e sistemalo prima di proseguire.

2. **Controlla di essere sul ramo giusto.** Deve essere un ramo `feature/` o `fix/`, non `develop`
   né `main`, e non devono esserci modifiche non committate:
   ```bash
   git status
   ```

3. **Review pre-merge.** Mostra all'utente cosa entrerà in `develop` e **chiedi conferma
   esplicita**:
   ```bash
   git log develop..HEAD --format="- %s" --reverse
   ```
   Se l'utente chiede altre modifiche, valuta se tenerle nello stesso ramo o aprirne uno nuovo, e
   proponi la soluzione. **Non procedere senza OK.**

4. **Squash merge in `develop`** (tutti i commit del ramo → uno solo):
   ```bash
   git checkout develop
   git pull --ff-only
   git merge --squash <tipo>/<nome>
   ```

5. **Commit unico.** [Conventional Commits](https://www.conventionalcommits.org/) con prefisso
   maiuscolo, prima riga di ~70 caratteri in italiano e minuscola dopo i due punti. Nel corpo si
   sintetizza **cosa e perché**, filtrando i passi intermedi:
   ```
   Tipo: titolo descrittivo dell'attività

   Cosa cambia e perché, in due o tre righe.
   ```

6. **Push e pulizia:**
   ```bash
   git push
   git branch -d <tipo>/<nome>
   git push origin --delete <tipo>/<nome>
   ```
   La cancellazione del ramo remoto vale solo se il ramo era stato pushato.

Esegui i passi 4-6 in autonomia dopo l'OK al merge, senza chiedere ulteriori permessi.
