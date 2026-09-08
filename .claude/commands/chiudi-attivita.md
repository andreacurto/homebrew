---
description: Chiude l'attività corrente — squash merge del ramo in develop, dopo conferma
---

Stai chiudendo l'attività sviluppata sul ramo corrente, portandola dentro `develop`. Segui
`docs/WORKFLOW.md`, sezione "Il ciclo di una modifica", passi 5 e 6. `docs/WORKFLOW.md` è la fonte
di verità: se qualcosa qui contraddice quel file, vince `docs/WORKFLOW.md`.

⚠️ **Questo comando non tocca mai `main` e non crea mai tag.** Entrambi richiedono un'attività
dedicata e l'approvazione esplicita di Andrea (vedi `docs/MIGRATION.md`).

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

3. **Verifica l'allineamento della documentazione.** Vedi `docs/WORKFLOW.md`, sezione "Allineamento
   della documentazione". Guarda cosa ha toccato l'attività:
   ```bash
   git diff develop...HEAD --stat
   ```
   Confronta ciò che è cambiato con la tabella "se hai cambiato X aggiorna Y" di
   `docs/WORKFLOW.md`: codice e comandi → `docs/DEVELOPMENT.md`; colori e layout →
   `docs/STYLEGUIDE.md`; comportamento del prodotto → `docs/PRODUCT.md`; cosa funziona davvero →
   `docs/MIGRATION.md`.

   Se qualcosa è disallineato, **aggiornalo adesso e committa sul ramo**: fa parte dell'attività e
   deve finire nello stesso squash. Se il disallineamento è fuori dal perimetro dell'attività,
   proponi all'utente di annotarlo in `docs/TODO.md` invece di allargare il ramo.

4. **Review pre-merge.** Mostra all'utente cosa entrerà in `develop` e **chiedi conferma
   esplicita**:
   ```bash
   git log develop..HEAD --format="- %s" --reverse
   ```
   Se l'utente chiede altre modifiche, valuta se tenerle nello stesso ramo o aprirne uno nuovo, e
   proponi la soluzione. **Non procedere senza OK.**

5. **Squash merge in `develop`** (tutti i commit del ramo → uno solo):
   ```bash
   git checkout develop
   git pull --ff-only
   git merge --squash <tipo>/<nome>
   ```

6. **Commit unico**, nel formato definito da `docs/WORKFLOW.md`, sezione "Commit". Nel corpo si
   sintetizza **cosa e perché**, filtrando i passi intermedi:
   ```
   Tipo: titolo descrittivo dell'attività

   Cosa cambia e perché, entro il limite di righe previsto.
   ```

7. **Push e pulizia:**
   ```bash
   git push
   git branch -d <tipo>/<nome>
   git push origin --delete <tipo>/<nome>
   ```
   La cancellazione del ramo remoto vale solo se il ramo era stato pushato.

Esegui i passi 5-7 in autonomia dopo l'OK al merge, senza chiedere ulteriori permessi.
