MAKEFLAGS += --silent
GOBIN=bin
BINARY_PATH=$(GOBIN)/$(APP_NAME)
VERSION ?= $(shell git log --pretty=format:'%h' -n 1)
AUTHOR ?= $(shell git log --pretty=format:'%an' -n 1)

APP_NAME ?= api
PID=/tmp/.$(APP_NAME).pid

.PHONY: help
help: Makefile
	@sed -n 's|^##||p' $< | column -t -s ':' | sed -e 's|^| |'

.PHONY: $(APP_NAME)
## $(APP_NAME): Build app with dependencies download
$(APP_NAME): deps go

## go: Build App
.PHONY: go
go: format lint tst bench build

## name: Output name of app
.PHONY: name
name:
	@echo -n $(APP_NAME)

## dist: Output build output path
.PHONY: dist
dist:
	@echo -n $(BINARY_PATH)

## version: Output sha1 of last commit
.PHONY: version
version:
	@echo -n $(VERSION)

## author: Output author's name of last commit
.PHONY: author
author:
	@python -c 'import sys; import urllib; sys.stdout.write(urllib.quote_plus(sys.argv[1]))' "$(AUTHOR)"

## deps: Download dependencies
.PHONY: deps
deps:
	go get github.com/golang/dep/cmd/dep
	go get github.com/golang/lint/golint
	go get github.com/kisielk/errcheck
	go get golang.org/x/tools/cmd/goimports
	dep ensure

## format: Format code of app
.PHONY: format
format:
	goimports -w */*.go */*/*.go
	gofmt -s -w */*.go */*/*.go

## lint: Lint code of app
.PHONY: lint
lint:
	golint `go list ./... | grep -v vendor`
	errcheck -ignoretests `go list ./... | grep -v vendor`
	go vet ./...

## tst: Test code of app with coverage
.PHONY: tst
tst:
	script/coverage

## bench: Benchmark code of app
.PHONY: bench
bench:
	go test ./... -bench . -benchmem -run Benchmark.*

## build: Build binary of app
.PHONY: build
build:
	CGO_ENABLED=0 go build -ldflags="-s -w" -installsuffix nocgo -o $(BINARY_PATH) cmd/api.go

## start: Start app
.PHONY: start
start: stop build
	$(GOBIN)/$(APP_NAME) \
		-tls=false \
	& echo $$! > $(PID)

## stop: Stop app
.PHONY: stop
stop:
	touch $(PID)
	kill -9 `cat $(PID)` 2> /dev/null || true
	rm $(PID)

## debug: Debug app
.PHONY: debug
debug:
	dlv debug \
		cmd/api.go -- \
		-tls=false
