.PHONY: all
all: .installed lint test dist

.PHONY: install
install:
	@rm -rf .installed
	@make .installed

.installed: package.json package-lock.json
	@echo "Dependencies files are newer than .installed; (re)installing."
	@npm ci
	@echo "This file is used by 'make' for keeping track of last install time. If package.json, package-lock.json or elm.json are newer then this file (.installed) then all 'make *' commands that depend on '.installed' know they need to run npm install first." \
		> .installed

# Testing and linting targets
.PHONY: lint
lint: .installed
	@echo "Linting is not implemented for this project"

.PHONY: tests
test: tests
tests: .installed
	@echo "Testing is not implemented for this project"

# Run development server
.PHONY: run
run: .installed
	@echo "What would that mean for this project? Try: make dist"


# Build distribution files and place them where they are expected
.PHONY: dist
dist: .installed
	mkdir -p dist/salary-calculator
	cp -r node_modules/salary-calculator/dist/ dist/
	cp custom.html bootstrap-sketchy.min.css dist/

# Nuke from orbit
clean:
	@rm -rf dist/
	@rm -f .installed
