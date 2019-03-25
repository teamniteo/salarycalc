sources := "$(shell find src -type f | sort | xargs ls -l)"

.PHONY: all
all: .installed lint test dist

.PHONY: install
install:
	@rm -rf .installed
	@make .installed

.installed: package.json package-lock.json elm.json
	@echo "Dependencies files are newer than .installed; (re)installing."
	@npm clean-install
	@echo "This file is used by 'make' for keeping track of last install time. If package.json, package-lock.json or elm.json are newer then this file (.installed) then all 'make *' commands that depend on '.installed' know they need to run npm install first." \
		> .installed

# Testing and linting targets
.PHONY: lint
lint: .installed
	@npx elm-analyse

.PHONY: test
test: tests

.PHONY: tests
tests: .installed
	@npx elm-coverage --report codecov

.coverage/codecov.json: .installed test

# Run development server
.PHONY: run
run: .installed
	@npx parcel --global SalaryCalculator src/index.html

.PHONY: codecov
codecov: .coverage/codecov.json
	npx codecov --disable=gcov --file=.coverage/codecov.json

# Build distribution files and place them where they are expected
.PHONY: dist
dist: .installed test
	# For modules (commonjs or ES6)
	@npx parcel build src/index.js
	# For html script tags
	@npx parcel build \
		--global SalaryCalculator \
		src/salary-calculator.js \
		src/index.html

# Publish a pre-release version to NPM
.PHONY: publish
publish: release = $(shell date +%Y-%m-%dT%H-%M-%S)
publish: dist
	@npm version \
		--no-git-tag-version \
		prerelease \
		--preid $(release)
	@npm publish
	@git checkout HEAD package.json package-lock.json

# Nuke from orbit
clean:
	@rm -rf elm-stuff/ dist/
	@rm -f .installed
