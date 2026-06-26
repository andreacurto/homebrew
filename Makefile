BINARY := dk

.PHONY: build run test lint tidy clean

build: ## compila il binario in bin/
	go build -o bin/$(BINARY) .

run: ## lancia la TUI
	go run .

test: ## esegue i test
	go test ./...

lint: ## formattazione + analisi statica
	gofmt -l .
	go vet ./...

tidy: ## sistema le dipendenze del modulo
	go mod tidy

clean: ## rimuove gli artefatti di build
	rm -rf bin
