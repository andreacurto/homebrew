---
description: Avvia un'attività — crea il ramo feature/ o fix/ a partire da develop
argument-hint: [descrizione dell'attività]
---

Stai avviando una nuova attività su Donkey 2.0. Segui `WORKFLOW.md`, sezione "Il ciclo di una
modifica", passi 1 e 2. `WORKFLOW.md` è la fonte di verità: se qualcosa qui contraddice quel file,
vince `WORKFLOW.md`.

Descrizione dell'attività richiesta dall'utente: $ARGUMENTS

## Passi da eseguire

1. **Partire aggiornati.** Allinea `develop` al remoto:
   ```bash
   git fetch origin --prune
   git checkout develop
   git pull --ff-only
   ```
   Se `develop` è disallineato o ci sono modifiche locali non committate, **fermati** e segnala la
   situazione all'utente prima di procedere.

2. **Scegli il tipo di ramo** in autonomia, in base alla natura dell'attività:
   - `feature/<nome>` → una funzionalità nuova o una modifica significativa
   - `fix/<nome>` → una correzione di un difetto

   Il nome è minuscolo, con parole separate da trattini, e descrive il **risultato** non il mezzo
   (es. `feature/installazione-homebrew`, `fix/allineamento-riepilogo`).

3. **Presenta il piano** all'utente e **attendi approvazione** prima di toccare codice:
   - **Nome del ramo** proposto
   - **Elenco dei passi previsti**, uno per commit
   - **Cosa resta fuori** dall'attività, se c'è ambiguità sul confine

   Un ramo = un'attività: se il lavoro si allarga troppo, proponi di spezzarlo in più rami.

   ⚠️ **Niente versioni, niente tag.** Durante lo sviluppo della 2.0 non si bumpano versioni e non
   si creano tag: quel meccanismo apparteneva alla 1.x e non vale più.

4. **Dopo l'OK dell'utente**, crea il ramo a partire da `develop` aggiornato:
   ```bash
   git checkout -b <tipo>/<nome>
   ```

5. Da qui in poi lavora in autonomia: commit piccoli e leggibili, `make lint` e `make test` verdi
   prima di ogni commit, push del ramo man mano. Quando l'attività è completa si usa
   `/chiudi-attivita`.

**Non** creare il ramo prima di aver presentato il piano e ricevuto l'approvazione.
