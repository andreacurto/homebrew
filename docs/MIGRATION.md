# Donkey — La migrazione 1.x → 2.0

Donkey sta passando da **1.x (bash + gum)** a **2.0 (Go + Bubble Tea)** nella stessa repository,
quindi convivono cose di entrambe le epoche. Questo documento racconta come stanno le cose adesso e
cosa succederà alla fine.

> **Documento temporaneo.** Quando la 2.0 sarà pubblicata, questo file va cancellato: le regole
> permanenti stanno in [`WORKFLOW.md`](WORKFLOW.md), che è già scritto per il dopo.

---

## Dove sta cosa

| Ramo | Cosa contiene |
|---|---|
| `main` | La **1.x stabile pubblicata** (`setup.sh`, `update.sh`), quella in mano agli utenti |
| `develop` | **Donkey 2.0 in Go.** È qui che si lavora |

Nel ramo di sviluppo sono ancora presenti `setup.sh` e `update.sh` della 1.x: sono **residui**. Non
vanno usati, modificati, né presi a modello. La loro rimozione è tracciata in [`TODO.md`](TODO.md).

**Cancellare o riscrivere `setup.sh` e `update.sh` richiede l'approvazione esplicita di Andrea**,
finché `main` è la versione pubblicata: sono ancora il prodotto in uso.

---

## ⚠️ Nessun tag fino alla v2.0.0

Gli utenti della 1.x ricevono gli aggiornamenti **tramite i tag**. Un tag creato durante lo sviluppo
li raggiungerebbe con codice incompleto: per questo **non se ne crea nessuno** fino alla v2.0.0.

La regola è applicata anche da un controllo automatico in `.claude/check-release-tag.sh`, che blocca
la creazione di tag.

La versione della 2.0 vive in `main.go` (`const version`), oggi `2.0.0-dev`, e non si bumpa a ogni
modifica.

⚠️ La 1.x usava una variabile `SCRIPT_VERSION` in `update.sh` e creava un tag a ogni modifica.
**Quel meccanismo non vale più.** Non cercarlo e non replicarlo: qualunque istruzione che parli di
`gum`, di `setup.sh` come file da modificare o di bumpare `SCRIPT_VERSION` è obsoleta.

---

## A che punto siamo

Questa sezione va tenuta aggiornata: è la prima cosa che serve sapere prima di scrivere codice.

| Parte | Stato |
|---|---|
| Menù principale (`dk`) | Navigabile, ma tutte e 5 le voci mostrano un segnaposto |
| Wizard (`dk setup`) | **Interfaccia completa** e rifinita, da benvenuto a riepilogo finale |
| Installazione di **Donkey core** | ✅ **Reale**: verifica, installa se manca, annota nel registro |
| Installazione di App, Strumenti, Font | ❌ Simulata |
| Configurazione terminale e aggiornamenti | ❌ Simulata |
| `internal/brew`, `internal/state` | Usati dal wizard nella fase core |

**Come convivono il vero e il finto:** ogni fase della checklist porta con sé il proprio motore. Se
ha un comando (campo `run` di `instPhase`) è **reale**: parte il comando, torna l'esito, la fase si
chiude tutta insieme. Se non ce l'ha è **simulata**: avanza a sotto-passi con un timer (`tea.Tick`)
e ritardi inventati. Oggi solo la fase core ha un comando; le altre lo riceveranno una alla volta,
senza toccare l'impalcatura.

Resta un aggancio finto: `simulateFontWarning` in `install.go`, che fa fallire un font per mostrare
l'esito ▲. Va via quando i font si installeranno davvero.

### La modalità prova

Isolare Homebrew su macOS è oneroso (il perché è in [`TODO.md`](TODO.md)), quindi per sviluppare
senza toccare il Mac c'è una **modalità prova**: il flusso è quello vero, ma i comandi non vengono
eseguiti — un esecutore finto immagina il Mac al posto loro. È attiva a schermo, con un avviso
visibile su riepilogo, installazione e schermata finale.

```bash
make run-dry                          # Mac immaginato senza il core
make run-dry DONKEY_DRY_RUN=present   # Mac immaginato che ce l'ha già
```

Il secondo caso è il più frequente sui Mac veri, ed è l'unico ramo collaudabile su una macchina che
Homebrew ce l'ha già.

---

## Cosa manca, in ordine

Il percorso verso la 2.0. Cosa deve fare ogni pezzo è descritto in [`PRODUCT.md`](PRODUCT.md); qui
c'è solo l'ordine in cui si costruisce.

| # | Blocco | Stato |
|---|---|---|
| 1 | **Scheletro** — progetto Go + Bubble Tea, menù, `style/`, `internal/catalog/` | ✅ fatto |
| 2 | **Onboarding** — interfaccia del wizard S1→S8 | ✅ fatto |
| 3 | **Installazione vera** — collegare i comandi reali, partendo dal solo core | ⏳ in corso — core fatto |
| 4 | **App** — il catalogo: installa e disinstalla | |
| 5 | **Terminale** — tema, font, suggerimenti | |
| 6 | **Aggiornamento** manuale e automatico | |
| 7 | **Status** — la vista di stato | |
| 8 | **Uninstall** a residuo zero | |
| 9 | **Rifinitura UX** e **distribuzione** — formula Homebrew, `install.sh`, release binari | |

---

## L'ultimo passo

Finiti i nove blocchi, in un'attività dedicata e con approvazione esplicita:

1. Merge di `develop` in `main`.
2. Rimozione dei residui bash (`setup.sh`, `update.sh`).
3. Rinomina della repository (`homebrew` → `donkey`) e allineamento dell'indirizzo dei cataloghi.
4. Riscrittura del `README` per il nuovo prodotto.
5. Tag `v2.0.0` — il primo.
6. **Cancellazione di questo documento.**
