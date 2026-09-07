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
(`homebrew` → `donkey`, prevista in roadmap). In sviluppo il problema non si vede perché
`make run-setup` legge i cataloghi dalla cartella locale. **Va sistemato prima di qualsiasi
distribuzione**, altrimenti i cataloghi non si scaricano.
