# Makefile for climenu R package
#
# Usage:
#   make install    - Install package dependencies
#   make test       - Run tests
#   make check      - Run R CMD check
#   make document   - Generate documentation
#   make build      - Build package tarball
#   make clean      - Clean build artifacts

.PHONY: help install test check lint document build clean coverage deps

# Default target
help:
	@echo "climenu package - Available targets:"
	@echo ""
	@echo "  make install      Install package locally"
	@echo "  make deps         Install package dependencies"
	@echo "  make test         Run test suite"
	@echo "  make test-file    Run specific test file (FILE=test-name.R)"
	@echo "  make check        Run R CMD check"
	@echo "  make lint         Lint package code"
	@echo "  make document     Generate documentation with roxygen2"
	@echo "  make build        Build source package"
	@echo "  make clean        Remove build artifacts"
	@echo "  make coverage     Generate test coverage report"
	@echo "  make style        Auto-format code with styler"
	@echo "  make all          Run document, test, lint, and check"
	@echo ""

# Install package dependencies
deps:
	@echo "Installing package dependencies..."
	@Rscript -e "if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools')"
	@Rscript -e "devtools::install_deps(dependencies = TRUE, upgrade = 'never')"

# Install package locally
install: deps
	@echo "Installing climenu package..."
	@Rscript -e "devtools::install()"

# Run all tests
test:
	@echo "Running tests..."
	@Rscript -e "devtools::test()"

# Run specific test file
test-file:
ifndef FILE
	@echo "Error: FILE not specified. Usage: make test-file FILE=test-climenu.R"
	@exit 1
endif
	@echo "Running tests in $(FILE)..."
	@Rscript -e "devtools::test_active_file('tests/testthat/$(FILE)')"

# Run R CMD check
check:
	@echo "Running R CMD check..."
	@Rscript -e "devtools::check()"

# Check without installation (faster for iterative development)
check-fast:
	@echo "Running R CMD check (without installation)..."
	@Rscript -e "devtools::check(args = c('--no-install'))"

# Lint package
lint:
	@echo "Linting package..."
	@Rscript -e "lintr::lint_package()"

# Generate documentation
document:
	@echo "Generating documentation..."
	@Rscript -e "devtools::document()"

# Build package tarball
build: document
	@echo "Building package..."
	@Rscript -e "devtools::build()"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf *.tar.gz
	@rm -rf .Rcheck
	@rm -rf man/*.Rd
	@rm -rf doc
	@rm -rf Meta
	@find . -name ".Rhistory" -delete
	@find . -name ".DS_Store" -delete

# Generate test coverage report
coverage:
	@echo "Generating test coverage report..."
	@Rscript -e "covr::package_coverage()"

# Interactive coverage report
coverage-report:
	@echo "Opening interactive coverage report..."
	@Rscript -e "covr::report(covr::package_coverage())"

# Auto-format code with styler
style:
	@echo "Styling R code..."
	@Rscript -e "styler::style_pkg()"

# Normalize DESCRIPTION file
desc-normalize:
	@echo "Normalizing DESCRIPTION file..."
	@Rscript -e "desc::desc_normalize()"

# Run all quality checks
all: document test lint check
	@echo "All checks passed!"

# Development mode - load package for interactive use
dev:
	@echo "Loading package for development..."
	@R -e "devtools::load_all(); library(climenu)"

# Quick development cycle
quick: document test
	@echo "Quick dev cycle complete!"
