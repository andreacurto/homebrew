# WORKFLOW — Regole di gestione del repository

Come si lavora su questa repository: rami, commit, merge, rilasci.
**Questo file è la fonte di verità sul processo**: se un altro documento o una vecchia automazione
dice il contrario, vince quello che è scritto qui.

Vale sempre, indipendentemente da cosa si stia sviluppando. Le regole legate alla fase attuale del
progetto stanno in [`MIGRATION.md`](MIGRATION.md).

---

## I rami

```
main                     ← stabile e pubblicato: la versione in mano agli utenti.
 └── develop             ← integrazione. Qui confluisce il lavoro finito.
      ├── feature/<nome> ← una singola attività nuova
      └── fix/<nome>     ← una singola correzione
```

| Ramo | A cosa serve | Ci si sviluppa? |
|---|---|---|
| `main` | Versione stabile pubblicata | ❌ Mai |
| `develop` | Punto di raccolta del lavoro completato | ❌ No, solo merge |
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
5. **Merge in `develop`** quando l'attività è completa e approvata — prima si verifica che la
   documentazione sia allineata (vedi sezione successiva).
6. **Cancellare il ramo**, in locale e sul remoto.

Per il merge in `develop` si usa lo **squash**: tutta l'attività diventa **un solo commit**, così la
storia di `develop` si legge come un elenco di attività completate invece che di passi intermedi.

---

## Allineamento della documentazione

La documentazione **vive nel ramo e descrive quel ramo**: quella su `main` racconta la versione
pubblicata, quella su `develop` il lavoro in corso. Passa da un ramo all'altro **con il merge**,
come il codice: non si copia a mano e non si porta avanti con un cherry-pick.

I documenti coinvolti sono `AGENTS.md` (punto d'ingresso) e tutto ciò che sta in `docs/`.

**Prima del merge in `develop`** (passo 5 del ciclo) si verifica che descrivano il codice del ramo.
Vanno aggiornati quando l'attività ha toccato:

| Se hai cambiato… | Aggiorna |
|---|---|
| File o cartelle sotto `internal/`, `main.go`, `config/` | `docs/DEVELOPMENT.md` → mappa del codice |
| Il `Makefile` o le variabili d'ambiente | `docs/DEVELOPMENT.md` → comandi |
| Colori, simboli, header, footer, animazioni | `docs/STYLEGUIDE.md` |
| Comportamento del prodotto, schermate, comandi `dk` | `docs/PRODUCT.md` |
| Cosa funziona davvero e cosa è ancora simulato | `docs/MIGRATION.md` → stato di avanzamento |
| I documenti stessi, o dove stanno | `AGENTS.md` → indice |
| Le regole di questo file | `docs/WORKFLOW.md` **e** le automazioni in `.claude/` |

**L'aggiornamento fa parte dell'attività**, non è un "dopo": entra negli stessi commit del ramo e
finisce nello stesso squash. Una documentazione disallineata è peggio di una assente, perché manda
gli agenti nella direzione sbagliata con sicurezza.

Se durante un'attività emerge un disallineamento **fuori dal suo perimetro**, non si allarga il
ramo: si annota in `docs/TODO.md` col motivo.

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
- Cancellare o riscrivere i file della versione pubblicata (vedi [`MIGRATION.md`](MIGRATION.md))

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

- **Prima riga**: massimo 70 caratteri, minuscola dopo i due punti, in **italiano**.
- **Corpo** opzionale, separato da una riga vuota: spiega **cosa e perché**, non *come*.
  Righe a capo a **72 caratteri**, **massimo 5 righe**.

Il tetto di 5 righe è voluto: se per spiegare un'attività ne servono di più, quell'attività era
troppo grande e andava spezzata in due rami. Il limite è un campanello, non una costrizione.

---

## Versioni e rilasci

- La versione vive in **`main.go`** (`const version`).
- Si segue il [versionamento semantico](https://semver.org/lang/it/): `MAJOR.MINOR.PATCH`.
- I tag portano sempre il prefisso `v` (es. `v2.0.0`), e si creano **solo con l'approvazione di
  Andrea**.
- Un tag raggiunge gli utenti: non se ne crea mai uno su codice incompleto. I vincoli della fase
  attuale sono in [`MIGRATION.md`](MIGRATION.md).

---

## Automazioni di sviluppo (`.claude/`)

La cartella `.claude/` contiene automazioni per chi sviluppa con Claude Code. Sono versionate, così
valgono ovunque si cloni la repository. **Non fanno parte di ciò che viene distribuito agli utenti.**

Quando queste regole cambiano, vanno aggiornate **anche le automazioni**, altrimenti spingono verso
un processo che non esiste più. Vale nei due sensi: un comando in `.claude/` non deve mai
contraddire `docs/WORKFLOW.md`, e i percorsi dei documenti citati devono esistere davvero.

Le modifiche in `.claude/` si committano con prefisso `Chore:`.
