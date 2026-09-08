# Donkey — Prodotto

Cosa è Donkey, per chi, e come si comporta. È la **fonte di verità di prodotto**: le decisioni su
*cosa deve fare* Donkey si prendono qui.

Per come è fatto il codice, vedi [`DEVELOPMENT.md`](DEVELOPMENT.md).
Per il look dell'interfaccia, vedi [`STYLEGUIDE.md`](STYLEGUIDE.md).

> **Come leggere questo documento.** Descrive Donkey 2.0 **finita**, non quella di oggi. Ciò che
> non esiste ancora è marcato con 🔜. Cosa funziona davvero, oggi, sta in
> [`MIGRATION.md`](MIGRATION.md).

---

## 1. Direzione di prodotto

### Missione
**Un solo comando per avere il tuo Mac pronto e mantenerlo fresco senza pensarci.**
Donkey installa il proprio core e gli strumenti base, mette le **app che scegli**, **personalizza il
terminale** (shell, tema, suggerimenti) e — se lo decidi al setup — tiene **tutto aggiornato in
automatico in background**, per sempre.

### Per chi è
Utenti di **medio livello che amano il terminale**: sanno aprire una shell e muoversi tra i menù, ma
non vogliono ricordarsi *quali* app installare, *come* configurare zsh o *quando* aggiornare. Donkey
toglie loro questo carico.

### Il problema che risolve
Allestire un Mac (nuovo o resettato) è **tedioso, manuale e dimenticabile**. Donkey lo rende
**un'unica esperienza guidata, bella e ripetibile**, e poi sparisce nello sfondo.

### I pilastri
1. **Provisioning** — installa il core + strumenti + le app/font che scegli, in un flusso guidato.
2. **Personalizzazione terminale** — shell zsh, tema (Oh My Posh), suggerimenti *fish-like*
   (`zsh-autosuggestions`); modificabili in ogni momento.
3. **Set-and-forget** — configura l'auto-aggiornamento in background (opt-in) e non ci pensi più.
4. **Catalogo di app curato** — una selezione pronta di app installabili/disinstallabili con un
   gesto. Il catalogo vive nel repo ed è **sempre aggiornato** (§3).
5. **Visibilità** — una vista di stato che dice a colpo d'occhio cosa è installato, cosa è da
   aggiornare, se l'auto-update è attivo.
6. **Manutenzione on-demand** — quando vuoi, aggiorni/pulisci/diagnostichi a mano.

### Cosa Donkey NON fa (confini)
- **Non è Mole.** Niente pulizia profonda del sistema, niente uninstall di app fuori dal suo
  catalogo, niente analisi disco o salute hardware. Se serve, Donkey **installa Mole** e gli lascia
  quel mestiere.
- **Non gestisce pacchetti oltre Homebrew.**
- **Nessun agente proprio in background**: l'auto-update gira su `launchd` via `homebrew-autoupdate`.
- **Niente modifiche di sistema invasive** non reversibili. E all'uninstall **non lascia residui**
  (§5).

### Filtro per le decisioni di prodotto
Prima di aggiungere qualcosa, deve passare **tutti e tre**:
1. Serve a **mettere in piedi** un Mac o a **tenerlo aggiornato**?
2. È qualcosa che un utente medio-terminale **non vuole ricordarsi/fare a mano**?
3. **Non** è già il mestiere di Mole o di un altro tool dedicato?

---

## 2. Esperienza (schermata per schermata)

I principi di UX e il look sono in [`STYLEGUIDE.md`](STYLEGUIDE.md).

### 2.1 — Installazione & primo avvio (onboarding)
L'utente **non clona nulla**. 🔜 Installa con un comando, due canali:
- `brew install andreacurto/donkey/donkey` — se ha già Homebrew.
- `curl -fsSL …/install.sh | bash` — Mac fresco: installa il core **e** Donkey.

Al **primo avvio** parte automaticamente il **Setup**, un wizard navigabile, una schermata per passo:

| # | Schermata | Cosa fa |
|---|-----------|---------|
| S1 | **Benvenuto** | Spiega in poche righe cosa accadrà. `Continua` / `Esci`. |
| S2 | **App** | Catalogo multi-selezione con descrizioni (scaricato live, §3). |
| S3 | **Strumenti terminale** | Multi-selezione: CLI utili e suggerimenti *fish-like*. |
| S4 | **Font terminale** | Multi-selezione font (Nerd Font, richiesti dai temi). |
| S5 | **Tema terminale** | Selezione singola del tema Oh My Posh. |
| S6 | **Auto-update** | Toggle "tieni tutto aggiornato da solo". |
| S7 | **Riepilogo** | "Ecco cosa farò": elenco del selezionato. `Conferma e installa` / `Indietro`. |
| S8 | **Installazione** | Avanzamento live, raggruppato per fase, con esito per fase. |

Il Setup **non è una voce del menù** `dk`: resta come comando `dk setup` (lo usa l'installer) e il
primo avvio lo propone se il Mac non è configurato.

🔜 La configurazione del terminale viene **appesa** al `~/.zshrc` in un blocco delimitato — Donkey
non sovrascrive mai un `.zshrc` esistente (§5).

### 2.2 — `dk` (menù principale, di gestione)

| Voce | Cosa fa |
|---|---|
| **App** | Installa o disinstalla singole app |
| **Terminale** | Personalizza il terminale con tema, font e autocompletamento |
| **Aggiornamento manuale** | Aggiorna ora le app e pulisci il Mac |
| **Aggiornamento automatico** | Gestisci l'aggiornamento automatico |
| **Status** | Lo stato di Donkey a colpo d'occhio |

🔜 I sottocomandi (`dk app`, `dk terminal`, `dk update`, `dk autoupdate`, `dk status`) saltano dritti
al flusso corrispondente.

### 2.3 — **App** 🔜
Scarica il catalogo `apps.list` **live dal repo a ogni avvio** (§3): sempre la lista più aggiornata.

| # | Schermata | Cosa fa |
|---|-----------|---------|
| A1 | **Catalogo** | Le app con lo stato (installata `●` / non installata `○`); si marca cosa installare o rimuovere. |
| A2 | **Riepilogo** | "Installerò X, rimuoverò Y". `Conferma` / `Indietro`. |
| A3 | **Esecuzione + Fatto** | Avanzamento live, poi esito. |

### 2.4 — **Terminale** 🔜
Come App ma per il terminale (cataloghi font/temi scaricati live):

| Voce | Cosa fa |
|------|---------|
| **Tema** | Cambia il tema Oh My Posh; aggiorna la riga nel blocco Donkey del `~/.zshrc` (mai il resto). |
| **Font** | Installa/seleziona un Nerd Font dal catalogo font. |
| **Suggerimenti** | Attiva/**disattiva** `zsh-autosuggestions` (aggiunge o rimuove la riga `source …`). |

È anche la risposta a "come disabilito i suggerimenti?": da qui, senza editare file a mano.

### 2.5 — **Aggiornamento manuale** 🔜
| # | Schermata | Cosa fa |
|---|-----------|---------|
| U1 | **Scegli** | Multi-selezione operazioni (aggiorna, rimuovi inutilizzati, pulizia, diagnostica), default sensati. |
| U2 | **Esecuzione** | Avanzamento live; l'output utile mostrato in un pannello scrollabile. |
| U3 | **Fatto** | Esito sintetico. |

### 2.6 — **Aggiornamento automatico** 🔜
- **Se spento** → *Attivalo*: intervallo + opzioni + `pinentry-mac` per il prompt password GUI.
- **Se acceso** → *Modifica impostazioni* o *Disattivalo*.

### 2.7 — **Status** 🔜 (sola lettura, funziona anche offline)
```
 Donkey core   6.0.3  ·  4 pacchetti da aggiornare
 Auto-update   attivo · ogni settimana · ultimo run: 2 giorni fa
 Terminale     tema zash · suggerimenti attivi
 App Donkey    11/14 dal catalogo installate
 Donkey        v2.0.0 (aggiornato)
```

---

## 3. I cataloghi

Le app, gli strumenti, i font e i temi che Donkey propone **vivono solo nel repo**, non dentro il
binario: vengono scaricati al momento. Due conseguenze volute:

- L'utente vede **sempre la lista più aggiornata**, senza installare una nuova versione di Donkey.
- Il catalogo si arricchisce **editando il repo**, senza far uscire una release.

Il prezzo è la rete, data per scontata sui comandi che la richiedono (`app`, `terminal`, `setup`,
`update`); **non** serve a `status` e `uninstall`. Se manca dove serve → schermata d'errore curata.
Niente liste salvate sul Mac significa anche niente residui da ripulire (§5).

Come sono fatti i file e come si prova in locale: [`DEVELOPMENT.md`](DEVELOPMENT.md).

---

## 4. Command surface

| Comando | Cosa fa | Stato |
|---|---|---|
| `dk` | menù principale | ✅ navigabile, voci segnaposto |
| `dk setup` | onboarding completo | ✅ interfaccia completa |
| `dk version` / `-v` | mostra la versione | ✅ |
| `dk help` / `-h` | mostra l'aiuto | ✅ |
| `dk app` | catalogo: installa/disinstalla app | 🔜 |
| `dk terminal` | personalizza il terminale | 🔜 |
| `dk update` | manutenzione on-demand | 🔜 |
| `dk autoupdate` | gestisce l'aggiornamento automatico | 🔜 |
| `dk status` | vista di stato (anche offline) | 🔜 |
| `dk uninstall` | rimuove Donkey senza lasciare residui | 🔜 |
| `dk completion` | genera il completamento Tab | 🔜 |

---

## 5. Sicurezza, reversibilità e uninstall

**Invariante**: Donkey è un *layer* sopra Homebrew — lo semplifica, non lo sostituisce. Tocca **solo
le proprie aggiunte**; **tutto ciò che preesisteva resta identico**, qualunque fosse.

Due meccanismi lo garantiscono:
- **Registro locale** (`~/.donkey/`, gestito da `internal/state/`): a ogni installazione Donkey
  annota **solo ciò che non era già presente** (core sì/no, formule, cask, tap, job auto-update). È
  *stato d'azione*, non un catalogo; viene rimosso all'uninstall.
- 🔜 **Blocco `.zshrc` delimitato**: Donkey **appende** la sua configurazione dentro marcatori
  `# >>> donkey >>>` … `# <<< donkey <<<`; **non sovrascrive mai** il `.zshrc` esistente. La
  rimozione è chirurgica, il resto (anche le modifiche fatte dopo) resta intatto. Backup
  `~/.zshrc.bak` come rete di sicurezza.

### `dk uninstall` 🔜
Mostra un riepilogo e offre **due strade** (conferma esplicita):
1. **Togli solo Donkey** — rimuove il *layer*: binario, `~/.donkey/`, blocco `.zshrc`, job
   auto-update + tap. **Lascia** i pacchetti installati (sono tuoi).
2. **Pulizia totale** — torna **esattamente a prima di Donkey**: rimuove anche i pacchetti del
   registro (mai quelli preesistenti).

**Il core**: se **preesisteva** → mai toccato. Se **l'ha installato Donkey** → rimosso solo in
*pulizia totale*, e solo se non restano pacchetti estranei a Donkey; altrimenti **lasciato** con
avviso.

In ogni caso: niente `rm -rf` "creativi", e **zero residui** dopo la pulizia totale.

---

## 6. Distribuzione & release 🔜

- **Canali**: formula Homebrew (`brew install …`), `install.sh` (`curl | bash`), binari nelle release
  GitHub.
- **Cataloghi disaccoppiati dal binario**: le liste si aggiornano editando il repo, senza release.
- **Versioning**: le regole sono in [`WORKFLOW.md`](WORKFLOW.md).

---

## 7. In che ordine viene costruito

Il percorso che porta alla 2.0 — cosa è già fatto, cosa manca e in che ordine — sta in
[`MIGRATION.md`](MIGRATION.md): è la stessa cosa vista dal lato dello sviluppo, e finirà insieme
alla migrazione.
