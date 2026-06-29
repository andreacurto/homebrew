#!/usr/bin/env python3
"""Rigenera config/fonts.list con tutti i Nerd Font disponibili come cask Homebrew.

Sorgente: API pubblica di Homebrew (formulae.brew.sh). Gira ovunque ci sia
Python 3 e una connessione — tipicamente sulla macchina di sviluppo o in CI,
MAI nel setup dell'utente (che legge solo il piccolo file committato).

Uso:
    make fonts        # oppure: python3 scripts/gen-fonts.py
"""
import json
import os
import sys
import urllib.request

API = "https://formulae.brew.sh/api/cask.json"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "config", "fonts.list")


def label_for(token, names):
    """Etichetta pulita: parte del 'name' prima di ' Nerd Font'.
    Fallback: derivata dal token (casing meno preciso)."""
    if names:
        label = names[0].split(" Nerd Font")[0].strip()
        if label:
            return label
    return token[len("font-"):-len("-nerd-font")].replace("-", " ").title()


def main():
    sys.stderr.write("Scarico l'indice cask di Homebrew…\n")
    with urllib.request.urlopen(API, timeout=60) as resp:
        casks = json.load(resp)

    rows = []
    for c in casks:
        token = c.get("token", "")
        if not token.endswith("-nerd-font"):
            continue
        rows.append((label_for(token, c.get("name") or []), token))
    rows.sort(key=lambda r: r[0].lower())

    with open(OUT, "w") as f:
        f.write("# Catalogo font di Donkey — GENERATO da scripts/gen-fonts.py.\n")
        f.write("# NON modificare a mano: rigenera con 'make fonts'.\n")
        f.write("# Tutti i Nerd Font come cask Homebrew, formato \"Etichetta|cask\".\n")
        for label, token in rows:
            f.write(f"{label}|{token}\n")

    sys.stderr.write(f"Scritte {len(rows)} voci in {OUT}\n")


if __name__ == "__main__":
    main()
