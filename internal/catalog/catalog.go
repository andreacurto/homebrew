// Package catalog scarica e parsa i cataloghi di Donkey (app, font, temi).
// I cataloghi vivono nel repo e vengono letti live a ogni uso: nessuna cache,
// così l'utente ha sempre la lista più aggiornata.
package catalog

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// Entry è una voce di catalogo: l'etichetta mostrata, il valore (cask o file
// tema) e una descrizione breve opzionale.
type Entry struct {
	Label string
	Value string
	Desc  string
}

// Nomi dei cataloghi nel repo.
const (
	Apps   = "apps.list"
	Fonts  = "fonts.list"
	Themes = "themes.list"
)

const defaultBaseURL = "https://raw.githubusercontent.com/andreacurto/donkey/main/config"

// base ritorna la sorgente dei cataloghi. In sviluppo è override-abile con
// DONKEY_CATALOG_URL: un URL http(s) oppure un percorso locale alla cartella config.
func base() string {
	if v := strings.TrimSpace(os.Getenv("DONKEY_CATALOG_URL")); v != "" {
		return strings.TrimRight(v, "/")
	}
	return defaultBaseURL
}

// Fetch scarica e parsa il catalogo indicato (es. catalog.Apps). Niente cache.
func Fetch(name string) ([]Entry, error) {
	src := base() + "/" + name

	if isLocalPath(src) {
		f, err := os.Open(strings.TrimPrefix(src, "file://"))
		if err != nil {
			return nil, fmt.Errorf("apertura catalogo %q: %w", name, err)
		}
		defer f.Close()
		return Parse(f)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(src)
	if err != nil {
		return nil, fmt.Errorf("download catalogo %q: %w", name, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("download catalogo %q: stato %s", name, resp.Status)
	}
	return Parse(resp.Body)
}

func isLocalPath(src string) bool {
	return strings.HasPrefix(src, "/") ||
		strings.HasPrefix(src, ".") ||
		strings.HasPrefix(src, "file://")
}

// Parse legge righe nel formato "Etichetta|valore[|descrizione]", saltando
// righe vuote e commenti ('#'). La descrizione è opzionale. Le righe malformate
// o con etichetta/valore vuoti vengono ignorate.
func Parse(r io.Reader) ([]Entry, error) {
	var out []Entry
	sc := bufio.NewScanner(r)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "|", 3)
		if len(parts) < 2 {
			continue
		}
		label, value := strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1])
		if label == "" || value == "" {
			continue
		}
		var desc string
		if len(parts) == 3 {
			desc = strings.TrimSpace(parts[2])
		}
		out = append(out, Entry{Label: label, Value: value, Desc: desc})
	}
	return out, sc.Err()
}
