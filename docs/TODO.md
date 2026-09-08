# TODO — Cose fuori scope

Idee e problemi emersi durante lo sviluppo che **non** stiamo affrontando adesso.

Per ognuno annotiamo **cosa** e **perché è stato rimandato**: così in futuro ricordiamo il motivo
della scelta e non rifacciamo da capo il ragionamento.

---

## UX / Interfaccia

### Mostrare l'elemento in corso durante l'installazione

**Cosa:** durante una fase come "Installazione App", mostrare anche *cosa* sta installando in quel
momento (es. `Installazione App · Spotify`) invece del solo nome della fase.

**Perché è rimandato:** con Homebrew vero una fase può restare ferma diversi minuti e l'utente non
ha riscontro di cosa stia succedendo — l'esigenza è reale e confermata. Ma in questa fase vogliamo
restare concentrati sullo **sviluppo della logica, non sull'interfaccia**. Da rivalutare **dopo aver
misurato i tempi reali** di installazione: solo allora sapremo quanto serve davvero e in che forma.

---

## Test e ambiente

### Ambiente isolato (VM) per il collaudo delle installazioni vere

**Cosa:** poter eseguire un'installazione reale completa senza toccare il Mac di sviluppo.

**Perché è rimandato:** isolare Homebrew su macOS è oneroso. L'unica strada davvero pulita è una
macchina virtuale macOS (pesante: download del sistema, decine di GB, prestazioni ridotte); un
secondo account utente **non** isola Homebrew, che è condiviso in `/opt/homebrew`; spostare il
prefisso di Homebrew è sconsigliato da Homebrew stesso (su Apple Silicon comporterebbe la
compilazione da sorgente di ogni pacchetto).

Nel frattempo bastano: la **modalità prova** per lo sviluppo quotidiano, e — per la verifica reale —
il fatto che Donkey **salti ciò che è già installato** e annoti **solo ciò che aggiunge**, così una
prova sul Mac vero ha un raggio d'azione limitato alle poche voci nuove selezionate.

Da riprendere se/quando servirà un collaudo end-to-end completo e ripetibile.

---

## Manutenzione

### Rimuovere i residui della versione 1.x (bash)

**Cosa:** nel repo convivono ancora `setup.sh` e `update.sh`, gli script della versione 1.x, più un
file `setup` non tracciato nella cartella di lavoro.

**Perché è rimandato:** finché `main` è la 1.x stabile pubblicata, quegli script sono ancora la
versione in uso dagli utenti. Vanno rimossi dal ramo di sviluppo solo insieme alla decisione su come
gestire il passaggio 1.x → 2.0 sul ramo stabile, per non lasciare gli utenti attuali senza nulla.

### Allineare l'indirizzo dei cataloghi

**Cosa:** il codice scarica i cataloghi da
`raw.githubusercontent.com/andreacurto/donkey/main/config`, ma **oggi quel repository non esiste**:
il repo si chiama ancora `homebrew`. Il ramo `main` invece adesso c'è, dopo la normalizzazione.

**Perché è rimandato:** dipende da una decisione non ancora presa — la rinomina del repository
(`homebrew` → `donkey`, prevista in `MIGRATION.md`). In sviluppo il problema non si vede perché
`make run-setup` legge i cataloghi dalla cartella locale. **Va sistemato prima di qualsiasi
distribuzione**, altrimenti i cataloghi non si scaricano.

---

## Automazioni e regole

### Controlli veri sul rispetto delle regole git

**Cosa:** far rispettare le regole di `WORKFLOW.md` con controlli **lato git**, non solo lato
agente. Oggi l'unico controllo è `.claude/check-release-tag.sh`, un gancio di Claude Code: blocca
Claude quando prova a creare un tag, ma non impedisce nulla a chi digita `git tag` in un terminale,
non vale per un altro agente e si aggira disattivando il gancio. Le regole più importanti (non
sviluppare su `develop`/`main`, niente tag, niente merge in `main`) restano quindi affidate alla
buona volontà.

Le strade possibili sono due, complementari:
- **Ganci git versionati** — una cartella di hook nel repo, attivata con `core.hooksPath`, che vale
  per chiunque cloni. Copre `pre-commit` e `pre-push`, ma restano disattivabili in locale.
- **Regole lato GitHub** — protezione dei rami o *rulesets*, che nessuno può aggirare dal proprio
  computer perché il rifiuto arriva dal server.

**Perché è rimandato:** è una decisione da prendere insieme, non un dettaglio implementativo. Tocca
la configurazione della repository su GitHub, che richiede approvazione esplicita (`WORKFLOW.md`,
"Chi decide cosa"), e si incastra con la revisione dei comandi qui sotto: ha senso deciderle in una
volta sola, per non riscrivere due volte le stesse automazioni.

### Revisione dei comandi in `.claude/`

**Cosa:** ripensare l'insieme dei comandi (oggi `/branch` e `/chiudi-attivita`). Due problemi
distinti:
- **I nomi non convincono.** Sono anche incoerenti fra loro — uno in inglese, uno in italiano — e
  `chiudi-attivita` viola la regola sulla lingua dei nomi di file (`AGENTS.md`, regola 2), che
  chiede l'inglese.
- **Sono solo istruzioni, non barriere.** Un comando descrive il processo corretto, ma nulla
  garantisce che venga usato: chi non lo invoca non incontra nessun controllo.

**Perché è rimandato:** rinominare i comandi è facile, ma ha senso farlo insieme alla decisione sui
controlli git qui sopra — altrimenti si rinomina ora e si riscrive tutto dopo. Da riprendere come
attività unica.
