# Makefile for delete-old-workflow-runs

.PHONY: install-deps run clean help format lint lint-fix lock

# Default target
.DEFAULT_GOAL := help

# Install dependencies
install-deps:
	poetry install

# Update lock file
lock:
	poetry lock

# Run the script (pass ARGS="--gh-token ..." as needed)
run: install-deps
	poetry run python main.py $(ARGS)

# Format code
format:
	poetry run ruff format main.py

# Lint code
lint:
	poetry run ruff check main.py

# Fix lint issues
lint-fix:
	poetry run ruff check --fix main.py

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
	@echo "  install-deps - Install dependencies with Poetry"
	@echo "  run          - Run the delete script (installs deps first)"
	@echo "  format       - Format code with Ruff"
	@echo "  lint         - Lint code with Ruff"
	@echo "  lint-fix     - Fix linting issues with Ruff"
	@echo "  lock         - Update Poetry lock file"
	@echo "  clean        - Clean up temporary files"
	@echo "  help         - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make run ARGS=\"--gh-token $$GH_TOKEN --repo-owner dexcom-inc --repo-name sre --days-old 180\""
	@echo "  poetry run python main.py --gh-token $$GH_TOKEN --repo-owner dexcom-inc --repo-name sre --days-old 180"
	@echo ""
