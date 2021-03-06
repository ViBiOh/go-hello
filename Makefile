SHELL = /bin/bash

ifneq ("$(wildcard .env)","")
	include .env
	export
endif

APP_NAME = api
PACKAGES ?= ./...
GO_FILES ?= $(shell find . -name "*.go")

MAIN_BINARY = bin/$(APP_NAME)
MAIN_SOURCE = cmd/api.go

MAIN_RUNNER = go run $(MAIN_SOURCE)
ifeq ($(DEBUG), true)
	MAIN_RUNNER = dlv debug $(MAIN_SOURCE) --
endif

.DEFAULT_GOAL := app

## help: Display list of commands
.PHONY: help
help: Makefile
	@sed -n 's|^##||p' $< | column -t -s ':' | sed -e 's|^| |'

## name: Output app name
.PHONY: name
name:
	@printf "%s" "$(APP_NAME)"

## version: Output last commit sha1
.PHONY: version
version:
	@printf "%s" "$(shell git rev-parse --short HEAD)"

## dev: Build app
.PHONY: dev
dev: format style test build

## app: Build whole app
.PHONY: app
app: init dev

## init: Download dependencies
.PHONY: init
init:
	@curl -q -sSL --max-time 10 "https://raw.githubusercontent.com/ViBiOh/scripts/master/bootstrap" | bash -s "git_hooks" "coverage"
	go get github.com/kisielk/errcheck
	go get golang.org/x/lint/golint
	go get golang.org/x/tools/cmd/goimports
	go mod tidy

## format: Format code
.PHONY: format
format:
	goimports -w $(GO_FILES)
	gofmt -s -w $(GO_FILES)

## style: Check code style
.PHONY: style
style:
	golint $(PACKAGES)
	errcheck -ignoretests $(PACKAGES)
	go vet $(PACKAGES)

## test: Test with coverage
.PHONY: test
test:
	scripts/coverage
	go test $(PACKAGES) -bench . -benchmem -run Benchmark.*

## build: Build binary
.PHONY: build
build:
	CGO_ENABLED=0 go build -ldflags="-s -w" -installsuffix nocgo -o $(MAIN_BINARY) $(MAIN_SOURCE)

## run: Run app
.PHONY: run
run:
	$(MAIN_RUNNER) \
		-csp "default-src 'self'; base-uri 'self'; script-src 'self' 'unsafe-inline' unpkg.com/swagger-ui-dist@3/; style-src 'self' 'unsafe-inline' unpkg.com/swagger-ui-dist@3/; img-src 'self' data:"
