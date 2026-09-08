# Donkey — Styleguide

Il look & feel dell'interfaccia. Tutto lo stile vive in
[`internal/tui/style/style.go`](../internal/tui/style/style.go): **è l'unica fonte del look**, e
questo documento lo descrive. Non scrivere colori o simboli a mano altrove.

> Se codice e documento divergono, **vince il codice**: si corregge questo file.
> I testi a schermo seguono anche le regole invalicabili di [`AGENTS.md`](../AGENTS.md).

---

## Principi di UX

- **Terminal-native e calmo**: schermo intero, layout stabile, allineamenti curati, colori coerenti.
  Un'estetica, non una somma di `echo`.
- **Tastiera-first**: `↑↓`/`j k` per muoversi, `Spazio` per selezionare, `Invio` per confermare,
  `Esc` per indietro, `Q` per uscire. **Footer sempre visibile** con i tasti disponibili.
- **Mai un vicolo cieco**: da ogni schermata si torna indietro. Niente flusso lineare rigido.
- **Anteprima prima di agire**: nessuna installazione o rimozione parte senza un **riepilogo**
  confermabile.
- **Segnale non rumore**: il log verboso resta dietro le quinte; errori e output utile vanno in un
  pannello scrollabile leggibile, coi suggerimenti copiabili.
- **Errori con dignità**: i fallimenti (es. rete assente dove serve) sono schermate curate, non
  crash o testo grezzo.

---

## Palette

| Nome | Hex | Ruolo |
|---|---|---|
| `Cream` | `#F3E9D2` | testo di base |
| `Ash` | `#838383` | testi secondari: descrizioni, footer, separatori, URL |
| `Coral` | `#FE3850` | brand "Donkey", elemento selezionato, cursore, errori |
| `Cheddar` | `#F1A90E` | slogan, avvisi, secondo livello dell'header |
| `Aquamarine` | `#01C5B4` | comando aperto, esiti riusciti |

### Regole di colore
- **Voce di lista**: titolo `Cream` → `Coral` **bold** quando selezionata; descrizione `Ash` →
  `Cream` quando selezionata.
- **Cursore** `Coral` bold · **"Donkey"** `Coral` bold · **slogan e breadcrumb** `Cheddar` ·
  **URL del repo** `Ash` sottolineato.
- **Scrollbar** delle liste lunghe: binario `Ash`, cursore `Cream`.
- **Footer**: il tasto in `Cream`, la sua descrizione e i separatori in `Ash`.

---

## Struttura di una schermata

Ogni schermata ha la stessa intestazione, composta da `style.Header`:

```
🐵 Donkey • <secondo livello> [• <terzo livello>]
github.com/andreacurto/donkey
```

- **Secondo livello**: lo slogan nel menù principale, il nome della vista altrove.
- **Terzo livello**: breadcrumb opzionale, sempre in `Ash`.
- **Brand mark**: emoji **🐵** prima di "Donkey", presente in **tutte** le schermate.
  **Niente logo ASCII.**

In fondo, la barra comandi composta da `style.Hints`, con i comandi divisi da `•`:

```
↑ ↓ • Invio Avanti • Esc Indietro • Q Esci
```

---

## Simboli

| Simbolo | Costante | Uso |
|---|---|---|
| `❖` | `SymCursor` | cursore della riga selezionata |
| `✓` | `SymSuccess` | riuscito |
| `✗` | `SymError` | errore |
| `▲` | `SymWarning` | avviso |
| `◆` | `SymInfo` | informazione |
| `■` / `□` | `SymCheckOn` / `SymCheckOff` | checkbox multi-selezione |
| `●` / `○` | `SymOn` / `SymOff` | acceso/spento, installato/non installato |

---

## Animazioni

Vibe **giocoso ma sobrio**: effetto "wow" dosato, mai da prodotto per bambini.

- **Spinner scimmietta** durante le attese: 🙈 🙉 🙊 🐵, cinque fotogrammi al secondo.
- **Cursore fisso**: niente pulsazione.
- **Niente fade** al cambio schermata, salvo transizioni leggerissime ed eleganti.
