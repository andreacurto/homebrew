---
description: Rilascia il branch corrente su master — squash merge, bump versione, tag e cleanup
---

Stai rilasciando il branch corrente su `master`. Segui il "Processo di Sviluppo" di `CLAUDE.md`, passi 3 e 4 (strategia **squash merge**).

## Passi da eseguire

1. **Review pre-merge (passo 3).** Mostra all'utente il riepilogo del branch e **chiedi conferma esplicita** prima di mergiare:
   ```bash
   git log master..HEAD --format="- %s" --reverse
   ```
   Se l'utente chiede altre modifiche, valuta se tenerle nello stesso branch o aprirne uno nuovo, e proponi la soluzione. **Non procedere senza OK.**

2. **Bump `SCRIPT_VERSION` come ultimo commit sul branch** (deve SEMPRE corrispondere al tag che creerai):
   ```bash
   sed -i '' 's/SCRIPT_VERSION="x.y.z"/SCRIPT_VERSION="a.b.c"/' update.sh
   ```
   Aggiorna anche il **changelog + footer versione** in `CLAUDE.md` e, se coinvolto dalla modifica, `README.md`. Poi:
   ```bash
   git add -A && git commit -m "Chore: bump version to a.b.c" && git push
   ```

3. **Squash merge su master** (tutti i commit del branch → uno solo):
   ```bash
   git checkout master
   git pull --ff-only
   git merge --squash <tipo>/<nome>
   ```

4. **Commit unico con changelog** (sintetizza, filtrando i fix intermedi di testing). Formato: prima riga sintetica, poi `Versione: X → Y`, poi `Modifiche:` con i cambiamenti significativi:
   ```
   Tipo: titolo descrittivo

   Versione: x.y.z → a.b.c

   Modifiche:
   - Feat: descrizione funzionalità
   - Fix: descrizione bug fix significativo
   ```

5. **Push + tag + cleanup**. Il tag deve SEMPRE avere il prefisso `v`:
   ```bash
   git push
   git tag va.b.c && git push origin va.b.c
   git branch -d <tipo>/<nome>
   git push origin --delete <tipo>/<nome>
   ```

6. **Verifica finale**: conferma che `SCRIPT_VERSION` in `update.sh` coincida esattamente col tag appena creato (`va.b.c`). È l'invariante che fa funzionare l'auto-update tag-based.

Esegui i passi 2-6 in autonomia dopo l'OK al merge, senza chiedere ulteriori permessi.
