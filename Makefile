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

.PHONY: tests
test: tests
tests: .installed
	@npx elm-coverage

# Run development server
.PHONY: run
run: .installed
	@npx parcel --global SalaryCalculator src/index.html

# Build distribution files and place them where they are expected
.PHONY: dist
dist: .installed
	# For modules (commonjs or ES6)
	@npx parcel build src/index.js
	# For html script tags
	@npx parcel build \
		--global SalaryCalculator \
		src/salary-calculator.js \
		src/index.html

# Nuke from orbit
clean:
	@rm -rf elm-stuff/ dist/
	@rm -f .installed
