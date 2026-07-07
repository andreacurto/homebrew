// Package state è il registro locale di Donkey (`~/.donkey/`): annota **solo ciò
// che Donkey aggiunge** al sistema, così l'uninstall può tornare esattamente a
// prima senza lasciare residui (AGENTS §5). È stato d'azione, non un catalogo.
package state

import (
	"encoding/json"
	"os"
	"path/filepath"
)

// manifestFile è il nome del registro dentro la cartella di Donkey.
const manifestFile = "manifest.json"

// Manifest è ciò che Donkey ha aggiunto e che dovrà rimuovere all'uninstall.
// Registriamo solo le aggiunte nuove: mai ciò che preesisteva.
type Manifest struct {
	HomebrewByDonkey bool     `json:"homebrew_by_donkey"` // Homebrew installato da Donkey
	Packages         []string `json:"packages"`           // formule/cask installati da Donkey
	Taps             []string `json:"taps"`               // tap aggiunti (es. domt4/autoupdate)
	AutoUpdate       bool     `json:"auto_update"`        // job homebrew-autoupdate attivato
	ZshrcConfigured  bool     `json:"zshrc_configured"`   // blocco Donkey scritto in ~/.zshrc
}

// AddPackage registra un pacchetto installato da Donkey, senza duplicati.
func (m *Manifest) AddPackage(pkg string) { m.Packages = addUnique(m.Packages, pkg) }

// AddTap registra un tap aggiunto da Donkey, senza duplicati.
func (m *Manifest) AddTap(tap string) { m.Taps = addUnique(m.Taps, tap) }

func addUnique(list []string, v string) []string {
	for _, x := range list {
		if x == v {
			return list
		}
	}
	return append(list, v)
}

// Store legge e scrive il manifest in una cartella (iniettabile per i test).
type Store struct{ dir string }

// New crea uno Store su una cartella specifica.
func New(dir string) *Store { return &Store{dir: dir} }

// Default punta a `~/.donkey`, con override via DONKEY_HOME (sviluppo/test).
func Default() (*Store, error) {
	if d := os.Getenv("DONKEY_HOME"); d != "" {
		return New(d), nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	return New(filepath.Join(home, ".donkey")), nil
}

// Dir è la cartella del registro.
func (s *Store) Dir() string { return s.dir }

// path è il percorso completo del file manifest.
func (s *Store) path() string { return filepath.Join(s.dir, manifestFile) }

// Load legge il manifest; se non esiste ancora ne restituisce uno vuoto.
func (s *Store) Load() (*Manifest, error) {
	data, err := os.ReadFile(s.path())
	if os.IsNotExist(err) {
		return &Manifest{}, nil
	}
	if err != nil {
		return nil, err
	}
	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, err
	}
	return &m, nil
}

// Save scrive il manifest, creando la cartella se serve.
func (s *Store) Save(m *Manifest) error {
	if err := os.MkdirAll(s.dir, 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(s.path(), data, 0o644)
}

// Remove cancella l'intero registro (usato dall'uninstall).
func (s *Store) Remove() error {
	err := os.RemoveAll(s.dir)
	if os.IsNotExist(err) {
		return nil
	}
	return err
}
