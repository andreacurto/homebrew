# Donkey — Istruzioni per gli agenti

**Punto d'ingresso della documentazione.** Questo file non contiene documentazione propria: dice
dove trovarla e quali regole non si violano mai.

Donkey è un'app da terminale (TUI) che allestisce un Mac e lo tiene aggiornato. Comando: `donkey`,
scorciatoia **`dk`**.

---

## Dove sta cosa

| Documento | Quando aprirlo |
|---|---|
| [`docs/PRODUCT.md`](docs/PRODUCT.md) | Cosa deve fare Donkey per l'utente: missione, confini, UX schermata per schermata |
| [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | Com'è fatto il codice e come ci si lavora: mappa, architettura, comandi, test |
| [`docs/STYLEGUIDE.md`](docs/STYLEGUIDE.md) | Come si presenta l'interfaccia: palette, simboli, header, animazioni |
| [`docs/WORKFLOW.md`](docs/WORKFLOW.md) | Come si lavora sulla repository: rami, commit, merge, rilasci |
| [`docs/MIGRATION.md`](docs/MIGRATION.md) | La migrazione 1.x → 2.0: cosa c'è su quale ramo, a che punto siamo, cosa manca |
| [`docs/TODO.md`](docs/TODO.md) | Cose emerse e volutamente rimandate, col motivo |

`CLAUDE.md` non ha contenuto proprio: richiama questo file.

---

## ⚠️ Lo stato di oggi, in una riga

**L'installazione è interamente simulata: nessun comando reale viene eseguito, il Mac non viene
toccato.** Prima di scrivere codice, leggi [`docs/MIGRATION.md`](docs/MIGRATION.md) per sapere cosa
funziona davvero.

---

## Regole invalicabili

Valgono sempre, anche quando nessun altro documento è stato aperto.

1. **Homebrew non va MAI nominato nell'interfaccia.** Per l'utente è tutto "Donkey": la fase che
   installa Homebrew si chiama "Installazione Donkey core". Vale per ogni testo a schermo.
2. **Lingua.** In italiano tutto ciò che è prosa: risposte, messaggi di commit, nomi dei rami,
   documentazione, commenti nel codice, testi dell'interfaccia. In inglese tutto ciò che è codice,
   **nomi di file e cartelle compresi**.
3. **Nessun tag** fino alla v2.0.0 — il perché è in [`docs/MIGRATION.md`](docs/MIGRATION.md).
4. **Non si sviluppa su `develop` né su `main`**: si parte sempre da un ramo `feature/` o `fix/`.
5. **Nessun merge verso `main`** senza approvazione esplicita di Andrea.
6. **Prima di toccare git** — commit compresi — leggi
   [`docs/WORKFLOW.md`](docs/WORKFLOW.md): è la fonte di verità sul processo e vince su qualunque
   altro documento.
7. **Prima di chiudere un'attività**, verifica che la documentazione sia allineata al codice del
   ramo: è un passo del ciclo, non un "dopo". Vedi
   [`docs/WORKFLOW.md`](docs/WORKFLOW.md) → "Allineamento della documentazione".
