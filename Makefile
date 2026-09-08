BINARY := dk

# Modalità prova: "1" immagina un Mac senza il core, "present" uno che ce l'ha già.
DONKEY_DRY_RUN ?= 1

.PHONY: build run run-setup run-dry test lint tidy clean update-fonts update-themes

build: ## compila il binario in bin/
	go build -o bin/$(BINARY) .

run: ## lancia la TUI (menù)
	go run .

run-setup: ## lancia il wizard di setup coi cataloghi locali (sviluppo)
	DONKEY_CATALOG_URL=$(CURDIR)/config go run . setup

run-dry: ## lancia il wizard in modalità prova: flusso reale, nessun comando eseguito
	DONKEY_CATALOG_URL=$(CURDIR)/config \
	DONKEY_DRY_RUN=$(DONKEY_DRY_RUN) \
	DONKEY_HOME=$(CURDIR)/bin/donkey-prova \
	go run . setup

test: ## esegue i test
	go test ./...

lint: ## formattazione + analisi statica
	gofmt -l .
	go vet ./...

tidy: ## sistema le dipendenze del modulo
	go mod tidy

update-fonts: ## rigenera config/fonts.list con tutti i Nerd Font (da Homebrew)
	@python3 scripts/gen-catalog.py fonts

update-themes: ## rigenera config/themes.list con tutti i temi Oh My Posh
	@python3 scripts/gen-catalog.py themes

clean: ## rimuove gli artefatti di build
	rm -rf bin
