#!/bin/sh
#
# Installation script for global git hooks
#
# Run this to install the pre-commit hook to your system:
# bash install-hooks.sh
#

HOOKS_DIR="$HOME/.config/git/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Copy pre-commit hook
cp "$(dirname "$0")/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed to $HOOKS_DIR"
echo "💡 Make sure your ~/.gitconfig has:"
echo "   [core]"
echo "       hooksPath = ~/.config/git/hooks"
