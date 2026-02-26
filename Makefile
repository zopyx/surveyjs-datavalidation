SHELL := /bin/sh

ENTRY := validate.mjs
DIST := dist
JSON_FILES := survey.json data-valid.json data-invalid.json
BUN_CMD :=  bun
DENO_CMD := deno
DENO_FLAGS := --allow-read --allow-write --no-check --node-modules-dir=auto
DENO_TARGET_MAC := x86_64-apple-darwin
DENO_TARGET_LINUX := x86_64-unknown-linux-gnu
STRIP_CMD ?= strip

.PHONY: all baseline mac linux deno-mac deno-linux assets clean bun-install \
	docker docker-linux docker-mac docker-mac-extract test

all: install mac linux

deno: deno-mac deno-linux
bun: linux mac

test:
	python -m unittest discover -s tests
	node $(ENTRY) --version
	node $(ENTRY) --schema-json survey.json --form-json data-valid.json --result-json output.json
	node $(ENTRY) --schema-json survey.json --form-json data-invalid.json --result-json output.json; test $$? -eq 1


install:
	bun install

assets:
	mkdir -p $(DIST)
	cp -f $(JSON_FILES) $(DIST)/

mac: bun-install assets
	mkdir -p $(DIST)
	$(BUN_CMD) build --compile --target=bun-darwin-x64 --outfile $(DIST)/survey-validate-macos $(ENTRY)

linux: bun-install assets
	mkdir -p $(DIST)
	$(BUN_CMD) build --compile --target=bun-linux-x64 --outfile $(DIST)/survey-validate-linux $(ENTRY)

deno-install: 
	deno install

deno-mac: deno-install assets
	mkdir -p $(DIST)
	$(DENO_CMD) compile $(DENO_FLAGS) --target=$(DENO_TARGET_MAC) --output $(DIST)/survey-validate-macos-deno $(ENTRY)
	@if command -v $(STRIP_CMD) >/dev/null 2>&1; then $(STRIP_CMD) -x $(DIST)/survey-validate-macos-deno || true; fi

deno-linux: deno-install assets
	mkdir -p $(DIST)
	$(DENO_CMD) compile $(DENO_FLAGS) --target=$(DENO_TARGET_LINUX) --output $(DIST)/survey-validate-linux-deno $(ENTRY)
	@if command -v $(STRIP_CMD) >/dev/null 2>&1; then $(STRIP_CMD) $(DIST)/survey-validate-linux-deno || true; fi

clean:
	rm -rf $(DIST)

docker: docker-linux docker-mac

docker-linux:
	docker build -f Dockerfile.deno.linux -t survey-validate-deno:linux .

docker-mac:
	docker build -f Dockerfile.deno.macos -t survey-validate-deno:macos .

docker-mac-extract: docker-mac
	mkdir -p $(DIST)
	@cid=$$(docker create survey-validate-deno:macos /dist/survey-validate-macos-deno); \
	docker cp $$cid:/dist/survey-validate-macos-deno $(DIST)/survey-validate-macos-deno; \
	docker cp $$cid:/dist/survey.json $(DIST)/survey.json; \
	docker cp $$cid:/dist/data-valid.json $(DIST)/data-valid.json; \
	docker cp $$cid:/dist/data-invalid.json $(DIST)/data-invalid.json; \
	docker rm $$cid
