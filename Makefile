# Convenience makefile to build the dev env and run common commands
# Based on https://github.com/niteoweb/Makefile

.PHONY: all
all: tests dist

# Lock version pins for Python, JavaScript & Elm dependencies
.PHONY: lock
lock:
	@rm -rf .venv/
	@poetry lock
	@rm -rf .venv/
	@rm -rf node_modules
	@elm2nix convert > elm-srcs.nix
	@elm2nix snapshot > registry.dat
	@nix-shell --run true

# Testing and linting targets
.PHONY: lint
lint:
# 1. get all unstaged modified files
# 2. get all staged modified files
# 3. get all untracked files
# 4. run pre-commit checks on them
ifeq ($(all),true)
	@pre-commit run --hook-stage push --all-files
else
	@{ git diff --name-only ./; git diff --name-only --staged ./;git ls-files --other --exclude-standard; } \
			| sort | uniq | sed 's|backend/||' \
			| xargs pre-commit run --hook-stage push --files
endif

.PHONY: test
test: tests

.PHONY: tests
tests: coverage

.PHONY: coverage
coverage: verify-examples
	@npx elm-coverage --report codecov

.PHONY: verify-examples
verify-examples:
	@npx elm-verify-examples

.coverage/codecov.json: test

# Run development server
.PHONY: run
run:
	@npx parcel --global SalaryCalculator src/index.html

.PHONY: codecov
codecov: .coverage/codecov.json
	npx codecov --disable=gcov --file=.coverage/codecov.json

# Build distribution files and place them where they are expected
.PHONY: dist
dist:
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


# Fetch salaries, location factors and currencies from the Internet
.PHONY: config
config: .python.installed
	@python scripts/fetch_config_values.py
