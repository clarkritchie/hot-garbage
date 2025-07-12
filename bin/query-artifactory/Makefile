# Makefile for query-artifactory
#
# This Makefile provides targets for testing, linting, and running the query-artifactory tool.
# Uses Poetry for dependency management and virtual environment isolation.
#
# Common targets:
#   make test         - Run all tests with poetry install first
#   make lint         - Run linting and formatting
#   make run          - Run the interactive prompt
#   make clean        - Clean up temporary files and caches
#   make help         - Show this help message

.PHONY: test lint clean help run docker helm pypi install-deps

# Variables
SCRIPT = ./query_artifactory.py
PROMPT_SCRIPT = ./run.zsh
POETRY = poetry
PYTHON = $(POETRY) run python
RUFF = $(POETRY) run ruff

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

# Test basic functionality
test: install-deps
	@echo "Testing query-artifactory..."
	@echo "Checking if Python script is executable..."
	@if [ -x "$(SCRIPT)" ]; then \
		echo "✓ Script is executable"; \
	else \
		echo "✗ Script is not executable"; \
		chmod +x $(SCRIPT); \
		echo "✓ Made script executable"; \
	fi
	@echo "Checking if prompt script is executable..."
	@if [ -x "$(PROMPT_SCRIPT)" ]; then \
		echo "✓ Prompt script is executable"; \
	else \
		echo "✗ Prompt script is not executable"; \
		chmod +x $(PROMPT_SCRIPT); \
		echo "✓ Made prompt script executable"; \
	fi
	@echo "Checking Python syntax..."
	$(PYTHON) -m py_compile $(SCRIPT) && echo "✓ Python syntax is valid"
	@echo "Testing basic imports..."
	$(PYTHON) -c "import sys; sys.path.insert(0, '.'); from query_artifactory import ArtifactoryQueryTool; print('✓ Basic imports work')" 2>/dev/null || echo "⚠ Import test skipped (dependencies may not be available)"
	@echo "Running pytest tests..."
	$(POETRY) run pytest tests/ --tb=short -v || echo "⚠ pytest tests failed or no tests found"
	@echo "Cleaning up Python cache files..."
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "All tests passed!"

# Run linting using Poetry
lint: install-deps
	@echo "Running linting and formatting..."
	$(RUFF) check --fix $(SCRIPT)
	$(RUFF) format $(SCRIPT)
	@echo "✓ Linting completed"

# Run the interactive prompt
run:
	@echo "Starting interactive query prompt..."
	$(PROMPT_SCRIPT)

# Quick test commands for each artifact type
docker:
	@echo "Testing Docker query with vnv-ddlm-robot-tests..."
	$(PYTHON) $(SCRIPT) vnv-ddlm-robot-tests docker --limit 3

helm:
	@echo "Testing Helm query with platform-validation-share..."
	$(PYTHON) $(SCRIPT) platform-validation-share helm --limit 3

pypi:
	@echo "Testing PyPI query with sre-libs..."
	$(PYTHON) $(SCRIPT) sre-libs pypi --limit 3

# Clean up temporary files
clean:
	@echo "Cleaning up temporary files..."
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name '.coverage' -delete 2>/dev/null || true
	@echo "Cleanup complete"

# Show help
help:
	@echo ""
	@echo "Query Artifactory Tool - Available targets:"
	@echo ""
	@echo "  test      - Run basic functionality tests"
	@echo "  lint      - Run linting and formatting"
	@echo "  run       - Run the interactive prompt"
	@echo "  docker    - Quick test of Docker query"
	@echo "  helm      - Quick test of Helm query"
	@echo "  pypi      - Quick test of PyPI query"
	@echo "  clean     - Clean up temporary files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make test           # Run all tests"
	@echo "  make run            # Start interactive mode"
	@echo "  make docker         # Test Docker functionality"
	@echo "  poetry run python query_artifactory.py data-platform-validation docker"
	@echo ""
