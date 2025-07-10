# Makefile for delete-old-workflow-runs

.PHONY: install run clean help format lint lint-fix

# Default target
.DEFAULT_GOAL := help

# Install dependencies
install:
	poetry install

# Run the script
run:
	poetry run delete-old-workflow-runs

# Format code
format:
	poetry run ruff format delete_old_workflow_runs.py

# Lint code
lint:
	poetry run ruff check delete_old_workflow_runs.py

# Fix linting issues
lint-fix:
	poetry run ruff check --fix delete_old_workflow_runs.py

# Clean up
clean:
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist/
	rm -rf *.egg-info/

# Show help
help:
	@echo ""
	@echo "Delete Old Workflow Runs - Available targets:"
	@echo ""
	@echo "  install   - Install dependencies with Poetry"
	@echo "  run       - Run the delete script"
	@echo "  format    - Format code with Ruff"
	@echo "  lint      - Lint code with Ruff"
	@echo "  lint-fix  - Fix linting issues with Ruff"
	@echo "  clean     - Clean up temporary files"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make install && make run"
	@echo "  poetry run delete-old-workflow-runs"
	@echo ""
