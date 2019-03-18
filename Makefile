sources := "$(shell find src -type f | sort | xargs ls -l)"

.PHONY: all
all: .installed lint test dist

.PHONY: install
install:
	@rm -rf .installed
	@make .installed

.installed: package.json package-lock.json elm.json
	@echo "Dependencies files are newer than .installed; (re)installing."
	@npm ci
	@echo "This file is used by 'make' for keeping track of last install time. If package.json, package-lock.json or elm.json are newer then this file (.installed) then all 'make *' commands that depend on '.installed' know they need to run npm install first." \
		> .installed

# Testing and linting targets
lint: .installed
	@npx elm-analyse

test: tests
tests: .installed
	@npx elm-test

# Run development server
.PHONY: run
run: .installed
	@npx parcel src/index.html

# Build distribution files and place them where they are expected
.PHONY: dist
dist: .installed
	@npx parcel build src/index.html
	@npx parcel build src/index.js

# Nuke from orbit
clean:
	@rm -rf elm-stuff/ dist/
	@rm -f .installed
