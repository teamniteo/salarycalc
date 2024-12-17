# Convenience makefile to build the dev env and run common commands
# Based on https://github.com/teamniteo/Makefile

.PHONY: all
all: tests dist

# Lock version pins for Python, JavaScript & Elm dependencies
.PHONY: lock
lock:
	@rm -rf .venv/
	@poetry lock --no-update
	@rm -rf .venv/
	@rm -rf node_modules
	@elm2nix convert > elm-srcs.nix
	@elm2nix snapshot > registry.dat
	@nix-shell --run true
	@direnv reload
	@nix-build shell.nix -A inputDerivation | cachix push niteo-public
	@rm result

# Build distribution files and place them where they are expected
.PHONY: dist
dist:
	@rm -rf dist
	# For modules (commonjs or ES6)
	@parcel build src/index.js
	# For html script tags
	@parcel build src/salary-calculator.js src/index.html

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
tests:
	@elm-verify-examples
	@elm-test

# Run development server
.PHONY: run
run:
	@parcel src/index.html


# Fetch salaries, location factors and currencies from the Internet
.PHONY: config
config:
	@PWDEBUG=1 python3.11 scripts/fetch_config_values.py
