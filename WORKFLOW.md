# WORKFLOW — Regole di gestione del repository

Come si lavora su questa repository: rami, commit, merge, rilasci.
**Questo file è la fonte di verità**: se un altro documento o una vecchia automazione dice il
contrario, vince quello che è scritto qui.

---

## I rami

```
main                     ← stabile e pubblicato. Oggi contiene la 1.x (bash).
 └── develop             ← integrazione di Donkey 2.0. Qui confluisce il lavoro finito.
      ├── feature/<nome> ← una singola attività nuova
      └── fix/<nome>     ← una singola correzione
```

| Ramo | A cosa serve | Ci si sviluppa? |
|---|---|---|
| `main` | Versione stabile pubblicata | ❌ Mai |
| `develop` | Punto di raccolta del lavoro completato su Donkey 2.0 | ❌ No, solo merge |
| `feature/<nome>` | Una singola attività | ✅ Sì |
| `fix/<nome>` | Una singola correzione | ✅ Sì |

**Regola:** un ramo = un'attività. Se un'attività si allarga troppo, si spezza in più rami invece
di gonfiarne uno.

**Nomi:** minuscoli, parole separate da trattini, descrittivi del *risultato*, non del mezzo.
Esempi: `feature/installazione-homebrew`, `fix/allineamento-riepilogo`.

---

## Il ciclo di una modifica

1. **Partire aggiornati.** Allineare `develop` al remoto e creare il ramo da lì.
2. **Sviluppare** con commit piccoli e leggibili, uno per passo logico compiuto.
3. **Verificare** prima di ogni commit: `make lint` e `make test` devono essere verdi.
4. **Push** del ramo sul remoto man mano, così il lavoro non vive solo in locale.
5. **Merge in `develop`** quando l'attività è completa e approvata.
6. **Cancellare il ramo**, in locale e sul remoto.

Per il merge in `develop` si usa lo **squash**: tutta l'attività diventa **un solo commit**, così la
storia di `develop` si legge come un elenco di attività completate invece che di passi intermedi.

---

## Chi decide cosa

### Claude può procedere da solo
- Creare rami `feature/` e `fix/` a partire da `develop`
- Commit e push **su quei rami**
- Cancellare un ramo già mergiato

### Serve l'approvazione esplicita di Andrea
- **Merge in `develop`** — prima si mostra cosa entra
- **Merge in `main`** — sempre, senza eccezioni
- **Creare tag**
- Riscrivere la storia (`push --force`, rebase su rami condivisi)
- Modifiche alla configurazione della repository su GitHub (rinomine, ramo predefinito, visibilità)
- Cancellare o riscrivere `setup.sh` / `update.sh` della 1.x, finché `main` è la versione pubblicata

**In caso di dubbio, si chiede.** Le operazioni su `main` e sul remoto non sono facilmente
reversibili una volta che qualcun altro le ha scaricate.

---

## Commit

[Conventional Commits](https://www.conventionalcommits.org/) con prefisso maiuscolo:

| Prefisso | Quando |
|---|---|
| `Feat` | Nuova funzionalità |
| `Fix` | Correzione di un difetto |
| `Style` | Interfaccia, testi, formattazione |
| `Refactor` | Riorganizzazione senza cambio di comportamento |
| `Docs` | Documentazione |
| `Chore` | Manutenzione, dipendenze, tooling |

- Prima riga: massimo ~70 caratteri, minuscola dopo i due punti, in **italiano**.
- Corpo opzionale, separato da una riga vuota: spiega **cosa e perché**, non *come*.

---

## Versioni e rilasci

- La versione vive in **`main.go`** (`const version`). Oggi: `2.0.0-dev`.
- **Nessun tag viene creato fino alla v2.0.0.** Durante lo sviluppo della 2.0 non esistono release
  intermedie: il lavoro non deve mai raggiungere gli utenti della 1.x per sbaglio.
- Si segue il [versionamento semantico](https://semver.org/lang/it/): `MAJOR.MINOR.PATCH`.
- I tag portano sempre il prefisso `v` (es. `v2.0.0`).

⚠️ La 1.x usava una variabile `SCRIPT_VERSION` in `update.sh` e creava un tag a ogni modifica.
**Quel meccanismo non vale più per la 2.0.** Non cercarlo e non replicarlo.

---

## La migrazione 1.x → 2.0

Oggi `main` contiene la versione bash pubblicata e usata. Finché è così:

- Gli script `setup.sh` e `update.sh` **restano dove sono** anche sul ramo di sviluppo: sono la
  versione ancora in mano agli utenti.
- Non si tocca `main` e non si creano tag: gli utenti della 1.x ricevono gli aggiornamenti tramite
  i tag, quindi un tag creato per sbaglio li raggiungerebbe.

Quando Donkey 2.0 sarà pronta, in un'attività dedicata: merge di `develop` in `main`, rimozione dei
residui bash, rinomina della repository, tag `v2.0.0`.

---

## Automazioni di sviluppo (`.claude/`)

La cartella `.claude/` contiene automazioni per chi sviluppa con Claude Code. Sono versionate, così
valgono ovunque si cloni la repository. **Non fanno parte di ciò che viene distribuito agli utenti.**

Quando queste regole cambiano, vanno aggiornate **anche le automazioni**, altrimenti spingono verso
un processo che non esiste più.

Le modifiche in `.claude/` si committano con prefisso `Chore:`.
