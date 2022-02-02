BIN_NAME=dicious
BIN_VERSION?=latest
GOFMT_FILES?=$$(find . -name '*.go' |grep -v vendor)
INSTALL_PREFIX=/usr/local/bin
TEST?=$$(go list ./... |grep -v 'vendor')
GOVERSION?=rc-bullseye

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
default: build

build: fmt
	go build -o $(BIN_NAME)

install:
	install -m 0755 -t $(INSTALL_PREFIX) $(BIN_NAME)

test: fmtcheck
	go test -i $(TEST) || exit 1
	echo $(TEST) | \
		xargs -t -n4 go test $(TESTARGS) -timeout=30s -parallel=4 -test.v

vet:
	@echo "go vet ."
	@go vet $$(go list ./... | grep -v vendor/) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

fmt:
	gofmt -w $(GOFMT_FILES)

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

errcheck:
	@sh -c "'$(CURDIR)/scripts/errcheck.sh'"

test-compile:
	@if [ "$(TEST)" = "./..." ]; then \
		echo "ERROR: Set TEST to a specific package. For example,"; \
		echo "  make test-compile TEST=./$(BIN_NAME)"; \
		exit 1; \
	fi
	go test -c $(TEST) $(TESTARGS)


docker-go-%: ## make in docker
	@docker run --rm -e GOCACHE=/src/.cache -w /src -v $(PWD):/src -u $(shell id -u):$(shell id -g) golang:$(GOVERSION) make $*

docker-shell: ## run shell in docker
	@docker run --rm -it -e GOCACHE=/src/.cache -w /src -v $(PWD):/src -u $(shell id -u):$(shell id -g) golang:$(GOVERSION) bash

docker-build: ## build docker image
	@docker build -t $(BIN_NAME):$(BIN_VERSION) --build-arg GOIMAGE=golang:$(GOVERSION) .

.PHONY: build install test vet fmt fmtcheck errcheck test-compile docker-*
