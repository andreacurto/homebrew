BINARY := dk

.PHONY: build run run-setup test lint tidy clean fonts

build: ## compila il binario in bin/
	go build -o bin/$(BINARY) .

run: ## lancia la TUI (menù)
	go run .

run-setup: ## lancia il wizard di setup coi cataloghi locali (sviluppo)
	DONKEY_CATALOG_URL=$(CURDIR)/config go run . setup

test: ## esegue i test
	go test ./...

lint: ## formattazione + analisi statica
	gofmt -l .
	go vet ./...

tidy: ## sistema le dipendenze del modulo
	go mod tidy

fonts: ## rigenera config/fonts.list con tutti i Nerd Font (da Homebrew)
	python3 scripts/gen-fonts.py

clean: ## rimuove gli artefatti di build
	rm -rf bin
