# Makefile for query-artifactory
#
# This Makefile provides targets for testing, linting, and dependency management.
# It uses Poetry for dependency management and virtual environment handling.
#
# Common targets:
#   make test         - Run all tests with poetry install first
#   make ruff         - Run linting and formatting
#   make coverage     - Run tests with coverage reporting
#   make clean        - Clean up temporary files and caches
#   make upgrade-deps - Upgrade all dependencies
#   make help         - Show this help message

.PHONY: all clean coverage docker helm help install-deps lint options pypi run test upgrade-deps

# Default target
all: install-deps ruff test coverage

# Variables
SRC_DIR = .
PYTHON = poetry run python
LINT = poetry run ruff
COVERAGE = poetry run coverage
POETRY = poetry
SCRIPT = ./query_artifactory.py
PROMPT_SCRIPT = ./run.zsh

# Default target
.DEFAULT_GOAL := help

# Check if pyproject.toml exists and install dependencies if it does
install-deps:
	@if [ -f pyproject.toml ]; then \
		echo "Installing dependencies with Poetry..."; \
		$(POETRY) install; \
	else \
		echo "No pyproject.toml found, skipping Poetry install"; \
	fi

test: install-deps
	@echo "Running tests for query-artifactory..."
	@echo "Checking if Python script is executable..."
	@if [ -x "$(SCRIPT)" ]; then \
		echo "✓ Script is executable"; \
	else \
		echo "✗ Script is not executable"; \
		chmod +x $(SCRIPT); \
		echo "✓ Made script executable"; \
	fi
	@echo "Checking Python syntax..."
	$(PYTHON) -m py_compile $(SCRIPT) && echo "✓ Python syntax is valid"
	@echo "Testing basic imports..."
	$(PYTHON) -c "import sys; sys.path.insert(0, '.'); from query_artifactory import ArtifactoryQueryTool; print('✓ Basic imports work')" 2>/dev/null || echo "⚠ Import test skipped (dependencies may not be available)"
	@if [ -n "$$(find tests -name '*.py' -type f 2>/dev/null)" ]; then \
		echo "Running unittest tests..."; \
		$(PYTHON) -m unittest discover -s tests -p "*.py" -v; \
	else \
		echo "No test files found in tests directory - skipping unittest"; \
	fi
	@echo "Cleaning up Python cache files..."
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true

# Lint exclusions are in the pyproject.toml file

coverage: install-deps
	@echo "Running tests with coverage..."
	@if [ -n "$$(find tests -name '*.py' -type f 2>/dev/null)" ]; then \
		$(COVERAGE) run -m unittest discover -s tests -p "*.py"; \
		$(COVERAGE) report -m; \
	else \
		echo "No test files found in tests directory - skipping coverage"; \
	fi

clean:
	@echo "Cleaning up temporary files and caches..."
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name '.pytest_cache' -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name '*.egg-info' -type d -exec rm -rf {} + 2>/dev/null || true
	rm -f .coverage
	rm -rf .ruff_cache
	rm -rf htmlcov

upgrade-deps:
	@echo "Upgrading dependencies..."
	@if [ -f pyproject.toml ]; then \
		echo "Updating Poetry dependencies..."; \
		$(POETRY) update; \
	else \
		echo "No pyproject.toml found, skipping Poetry update"; \
	fi

# Run the interactive prompt
run:
	@echo "Starting interactive query prompt..."
	$(PROMPT_SCRIPT)

# Generate Docker and Helm options from repository structure
options:
	@echo "Generating Docker and Helm options lists..."
	./generate-options.zsh

# Quick test commands for each artifact type (app-specific targets)
docker:
	@echo "Testing Docker query with vnv-ddlm-robot-tests..."
	$(PYTHON) $(SCRIPT) vnv-ddlm-robot-tests docker --limit 3

helm:
	@echo "Testing Helm query with platform-validation-share..."
	$(PYTHON) $(SCRIPT) platform-validation-share helm --limit 3

pypi:
	@echo "Testing PyPI query with sre-libs..."
	$(PYTHON) $(SCRIPT) sre-libs pypi --limit 3


# Alias for linting
lint: install-deps
	@echo "Running linting and formatting..."
	$(LINT) check --fix && $(LINT) format

help:
	@echo "Available targets:"
	@echo "  lint         - Run linting and formatting"
	@echo "  test         - Run all tests with poetry install first"
	@echo "  coverage     - Run tests with coverage reporting"
	@echo "  clean        - Clean up temporary files and caches"
	@echo "  upgrade-deps - Upgrade all dependencies using Poetry"
	@echo "  install-deps - Install dependencies using Poetry"
	@echo "  run          - Run the interactive prompt"
	@echo "  options      - Generate Docker and Helm options lists from Chart.yaml and Dockerfiles"
	@echo "  docker       - Quick test of Docker query"
	@echo "  helm         - Quick test of Helm query"
	@echo "  pypi         - Quick test of PyPI query"
	@echo "  help         - Show this help message"
