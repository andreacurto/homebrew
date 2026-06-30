#!/usr/bin/env python3
"""Rigenera i cataloghi di Donkey dalle sorgenti ufficiali.

I cataloghi (font, temi) vivono nel repo e vengono letti live a runtime dal
setup. Questo script li rigenera a monte — sulla macchina di sviluppo o in CI,
MAI nel setup dell'utente.

Uso:
    make update-fonts     # python3 scripts/gen-catalog.py fonts
    make update-themes    # python3 scripts/gen-catalog.py themes
"""
import json
import os
import re
import sys
import threading
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Palette Donkey in ANSI truecolor.
CORAL = "\033[38;2;254;56;80m"
CHEDDAR = "\033[38;2;241;169;14m"
AQUA = "\033[38;2;1;197;180m"
ASH = "\033[38;2;131;131;131m"
RESET = "\033[0m"


class Spinner:
    """Spinner brandizzato su stderr; statico se l'output non è un terminale."""

    FRAMES = ["🙈", "🙉", "🙊", "🐵"]

    def __init__(self, text):
        self.text = text
        self.run = False
        self.thread = None
        self.tty = sys.stderr.isatty()

    def __enter__(self):
        if self.tty:
            self.run = True
            self.thread = threading.Thread(target=self._spin, daemon=True)
            self.thread.start()
        else:
            sys.stderr.write(self.text + "\n")
        return self

    def _spin(self):
        i = 0
        while self.run:
            frame = self.FRAMES[i % len(self.FRAMES)]
            sys.stderr.write(f"\r{CHEDDAR}{frame}{RESET}  {ASH}{self.text}{RESET}")
            sys.stderr.flush()
            i += 1
            time.sleep(0.15)

    def __exit__(self, *_):
        if self.tty:
            self.run = False
            self.thread.join()
            sys.stderr.write("\r\033[2K")  # pulisce la riga dello spinner


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "donkey"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def write_catalog(name, header, rows):
    out = os.path.join(ROOT, "config", name)
    with open(out, "w") as f:
        f.write("# Catalogo di Donkey — GENERATO da scripts/gen-catalog.py, NON modificare a mano.\n")
        f.write(f"# {header} Rigenera con: make update-{name.split('.')[0]}\n")
        for label, value in rows:
            f.write(f"{label}|{value}\n")


def font_label(token, names):
    """Etichetta leggibile (con spazi): nome umano tra parentesi del campo
    'name'; fallback al nome famiglia, poi al token."""
    n = names[0] if names else ""
    m = re.search(r"\(([^)]+)\)", n)
    if m:
        return m.group(1).strip()
    fam = n.split(" Nerd Font")[0].strip()
    return fam or token[len("font-"):-len("-nerd-font")].replace("-", " ").title()


def gen_fonts():
    with Spinner("Scarico i Nerd Font da Homebrew…"):
        casks = fetch_json("https://formulae.brew.sh/api/cask.json")
    rows = []
    for c in casks:
        token = c.get("token", "")
        if token.endswith("-nerd-font"):
            rows.append((font_label(token, c.get("name") or []), token))
    rows.sort(key=lambda r: r[0].lower())
    write_catalog("fonts.list", "Tutti i Nerd Font come cask Homebrew.", rows)
    return len(rows), "Nerd Font"


def theme_label(value):
    """Etichetta leggibile dal nome del tema: separatori → spazi, iniziali
    maiuscole preservando il casing esistente (es. M365Princess)."""
    s = re.sub(r"[-_.]+", " ", value).strip()
    return " ".join(w[:1].upper() + w[1:] if w else w for w in s.split())


def gen_themes():
    with Spinner("Scarico i temi Oh My Posh…"):
        data = fetch_json(
            "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes"
        )
    rows = []
    for f in data:
        name = f.get("name", "")
        if name.endswith(".omp.json"):
            value = name[: -len(".omp.json")]
            rows.append((theme_label(value), value))
    rows.sort(key=lambda r: r[0].lower())
    write_catalog("themes.list", "Tutti i temi di Oh My Posh.", rows)
    return len(rows), "temi"


GENERATORS = {"fonts": gen_fonts, "themes": gen_themes}


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else ""
    if kind not in GENERATORS:
        sys.stderr.write("Uso: gen-catalog.py [fonts|themes]\n")
        sys.exit(2)
    sys.stderr.write(f"🐵  {ASH}Donkey · aggiorno il catalogo {kind}{RESET}\n")
    count, word = GENERATORS[kind]()
    sys.stderr.write(
        f"{AQUA}✓{RESET}  {CHEDDAR}{count}{RESET} {word} "
        f"in {ASH}config/{kind}.list{RESET}\n"
    )


if __name__ == "__main__":
    main()
