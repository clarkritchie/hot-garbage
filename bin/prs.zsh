#!/usr/bin/env zsh

set -euo pipefail

usage() {
  echo "Usage: $0 [PR_NUMBER]"
  echo "Triggers CI on a PR by pushing an empty commit"
}

process_pr() {
  local pr_number="$1"

  # Get PR branch name
  local branch=$(gh pr view "$pr_number" --json headRefName --jq .headRefName)

  if [[ -z "$branch" ]]; then
    echo "❌ Could not determine branch for PR #${pr_number}"
    return 1
  fi

  # Ask about triggering CI
  echo -n "Trigger CI with an empty commit? [Y/n]: "
  read -r trigger_ci

  # Ask about approval
  echo -n "Approve this PR? [y/N]: "
  read -r approve_pr

  # Ask about auto-merge
  echo -n "Enable auto-merge (squash)? [y/N]: "
  read -r enable_auto

  # Trigger CI with empty commit, if requested
  if [[ "$trigger_ci" =~ ^[Yy]$ || -z "$trigger_ci" ]]; then
    echo "Fetching latest changes..."
    git fetch -q origin

    echo "Checking out branch '$branch'..."
    git checkout -q "$branch"

    echo "Updating to latest remote state..."
    git reset -q --hard "origin/$branch"

    echo "Rebasing from main..."
    git rebase -q origin/main

    echo "Creating empty commit..."
    git commit --allow-empty -m "trigger ci" > /dev/null

    echo "Pushing to origin..."
    git push -q --force-with-lease origin "$branch"

    echo "✅ Empty commit pushed - CI should trigger now"
    sleep 3
  fi

  # Approve, if requested
  if [[ "$approve_pr" =~ ^[Yy]$ ]]; then
    echo "Approving PR..."
    gh pr review "$pr_number" --approve
    echo "✅ PR approved"
    sleep 3
  fi

  # Enable auto-merge if requested
  if [[ "$enable_auto" =~ ^[Yy]$ ]]; then
    echo "Enabling auto-merge..."
    gh pr merge "$pr_number" --auto --squash
    echo "✅ Auto-merge enabled"
  fi
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  local pr_number="${1:-}"

  # If PR number provided via CLI, process it and exit
  if [[ -n "$pr_number" ]]; then
    process_pr "$pr_number"
    exit 0
  fi

  # Loop until user exits
  while true; do
    if command -v fzf &> /dev/null; then
      # Use fzf for interactive selection with arrow keys
      echo "Fetching unapproved PRs..."
      local selected=$(GH_PAGER="" gh pr list --state open --limit 50 --json number,title,reviewDecision --jq '.[] | select(.reviewDecision != "APPROVED") | "\(.number)\t\(.title)"' | fzf --height=20 --reverse --header="Select a PR (use arrow keys, ESC to exit)")
      if [[ -z "$selected" ]]; then
        echo "Exiting..."
        exit 0
      fi
      pr_number=$(echo "$selected" | awk '{print $1}')
    else
      # Fallback to simple prompt
      echo ""
      echo "Fetching unapproved PRs..."
      GH_PAGER="" gh pr list --state open --limit 50 --json number,title,reviewDecision --jq '.[] | select(.reviewDecision != "APPROVED") | "\(.number)\t\(.title)"'
      echo ""
      echo -n "Enter PR number (or 'exit' to quit): "
      read -r pr_input

      if [[ -z "$pr_input" || "$pr_input" == "exit" ]]; then
        echo "Exiting..."
        exit 0
      fi
      pr_number="$pr_input"
    fi

    process_pr "$pr_number"
  done
}

main "$@"
