package state

import (
	"path/filepath"
	"testing"
)

func TestLoadMissingReturnsEmpty(t *testing.T) {
	s := New(filepath.Join(t.TempDir(), "donkey"))
	m, err := s.Load()
	if err != nil {
		t.Fatalf("Load su registro inesistente non deve fallire: %v", err)
	}
	if m.HomebrewByDonkey || len(m.Packages) != 0 {
		t.Error("un registro inesistente deve dare un manifest vuoto")
	}
}

func TestSaveLoadRoundTrip(t *testing.T) {
	s := New(filepath.Join(t.TempDir(), "donkey"))
	m := &Manifest{HomebrewByDonkey: true, AutoUpdate: true, ZshrcConfigured: true}
	m.AddPackage("figma")
	m.AddPackage("gh")
	m.AddTap("domt4/autoupdate")

	if err := s.Save(m); err != nil {
		t.Fatalf("Save: %v", err)
	}
	got, err := s.Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if !got.HomebrewByDonkey || !got.AutoUpdate || !got.ZshrcConfigured {
		t.Error("i flag non sono stati persistiti correttamente")
	}
	if len(got.Packages) != 2 || got.Packages[0] != "figma" || got.Packages[1] != "gh" {
		t.Errorf("packages = %v, atteso [figma gh]", got.Packages)
	}
	if len(got.Taps) != 1 || got.Taps[0] != "domt4/autoupdate" {
		t.Errorf("taps = %v, atteso [domt4/autoupdate]", got.Taps)
	}
}

func TestAddPackageDedup(t *testing.T) {
	m := &Manifest{}
	m.AddPackage("gh")
	m.AddPackage("gh")
	m.AddPackage("node")
	if len(m.Packages) != 2 {
		t.Errorf("i duplicati non devono essere aggiunti: %v", m.Packages)
	}
}

func TestRemove(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "donkey")
	s := New(dir)
	if err := s.Save(&Manifest{HomebrewByDonkey: true}); err != nil {
		t.Fatalf("Save: %v", err)
	}
	if err := s.Remove(); err != nil {
		t.Fatalf("Remove: %v", err)
	}
	// Dopo la rimozione, Load riparte da un manifest vuoto.
	m, err := s.Load()
	if err != nil || m.HomebrewByDonkey {
		t.Error("dopo Remove il registro deve risultare assente/vuoto")
	}
	// Remove su registro assente è idempotente.
	if err := s.Remove(); err != nil {
		t.Errorf("Remove idempotente: %v", err)
	}
}
