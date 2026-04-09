#!/usr/bin/env zsh

set -euo pipefail

usage() {
  echo "Usage: $0 [PR_NUMBER]"
  echo "Triggers CI on a PR by pushing an empty commit using GitHub API"
  echo ""
  echo "Supports batch processing with fzf multi-select (Tab to select multiple PRs)"
}

# Get repo owner and name from git remote
get_repo_info() {
  local remote_url=$(git config --get remote.origin.url)
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/\.]+) ]]; then
    echo "${match[1]}/${match[2]}"
  else
    echo "❌ Could not parse GitHub repo from remote URL"
    exit 1
  fi
}

# Trigger CI using GitHub API (no local git operations)
trigger_ci_via_api() {
  local pr_number="$1"
  local repo="$2"

  # Get PR branch name and latest commit SHA
  local pr_data=$(gh pr view "$pr_number" --json headRefName,headRefOid --jq '{branch: .headRefName, sha: .headRefOid}')
  local branch=$(echo "$pr_data" | jq -r .branch)
  local head_sha=$(echo "$pr_data" | jq -r .sha)

  if [[ -z "$branch" || -z "$head_sha" ]]; then
    echo "❌ PR #${pr_number}: Could not get branch or SHA"
    return 1
  fi

  echo "  → Branch: ${branch}, SHA: ${head_sha:0:7}"

  # Create empty commit directly via GitHub API
  local tree_sha=$(gh api "repos/${repo}/git/commits/${head_sha}" --jq .tree.sha)

  gh api "repos/${repo}/git/commits" \
    --method POST \
    --field message="trigger ci" \
    --field tree="$tree_sha" \
    --field 'parents[]'="$head_sha" \
    --jq .sha | \
  xargs -I {} gh api "repos/${repo}/git/refs/heads/${branch}" \
    --method PATCH \
    --field sha={} \
    --silent

  echo "✓ PR #${pr_number}: Empty commit pushed via API"
}

process_pr() {
  local pr_number="$1"
  local repo="$2"
  local trigger_ci="$3"
  local approve_pr="$4"
  local enable_auto="$5"

  echo "→ Processing PR #${pr_number}..."

  # Trigger CI with empty commit via API
  if [[ "$trigger_ci" == "true" ]]; then
    echo "  → Triggering CI for PR #${pr_number}..."
    trigger_ci_via_api "$pr_number" "$repo"
  fi

  # Approve PR
  if [[ "$approve_pr" == "true" ]]; then
    echo "  → Attempting to approve PR #${pr_number}..."
    if gh pr review "$pr_number" --approve 2>&1; then
      echo "✓ PR #${pr_number}: Approved"
    else
      echo "⚠ PR #${pr_number}: Approval failed or already approved"
    fi
  fi

  # Enable auto-merge
  if [[ "$enable_auto" == "true" ]]; then
    echo "  → Attempting to enable auto-merge for PR #${pr_number}..."
    if gh pr merge "$pr_number" --auto --squash 2>&1; then
      echo "✓ PR #${pr_number}: Auto-merge enabled"
    else
      echo "⚠ PR #${pr_number}: Auto-merge failed (may already be enabled)"
    fi
  fi

  echo ""
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  local repo=$(get_repo_info)
  local pr_number="${1:-}"

  # If PR number provided via CLI, process it and exit
  if [[ -n "$pr_number" ]]; then
    echo -n "Trigger CI? [Y/n]: "
    read -r trigger_ci
    echo -n "Approve? [y/N]: "
    read -r approve_pr
    echo -n "Auto-merge? [y/N]: "
    read -r enable_auto

    local trigger=$([[ "$trigger_ci" =~ ^[Yy]$ || -z "$trigger_ci" ]] && echo "true" || echo "false")
    local approve=$([[ "$approve_pr" =~ ^[Yy]$ ]] && echo "true" || echo "false")
    local auto=$([[ "$enable_auto" =~ ^[Yy]$ ]] && echo "true" || echo "false")

    process_pr "$pr_number" "$repo" "$trigger" "$approve" "$auto"
    exit 0
  fi

  # Check for fzf
  if ! command -v fzf &> /dev/null; then
    echo "❌ fzf is required for batch processing"
    echo "Install with: brew install fzf"
    exit 1
  fi

  # Batch mode: loop until user exits
  while true; do
    # Select multiple PRs upfront
    echo ""
    echo "→ Fetching unapproved PRs..."
    local selected=$(GH_PAGER="" gh pr list --state open --limit 50 --json number,title,reviewDecision --jq '.[] | select(.reviewDecision != "APPROVED") | "\(.number)\t\(.title)"' | fzf --multi --height=20 --reverse --header="Select PRs (Tab to select multiple, Enter to confirm, ESC to exit)")

    if [[ -z "$selected" ]]; then
      echo ""
      echo "✓ Done"
      exit 0
    fi

    # Extract PR numbers (first field before tab)
    local pr_numbers=()
    while IFS=$'\t' read -r number title; do
      pr_numbers+=("$number")
    done <<< "$selected"

    local count=${#pr_numbers[@]}
    echo ""
    echo "Selected ${count} PR(s)"
    echo ""

    # Get default actions for all PRs
    echo "Default actions for all ${count} PR(s):"
    echo -n "  Trigger CI? [Y/n]: "
    read -r trigger_ci
    echo -n "  Approve? [Y/n]: "
    read -r approve_pr
    echo -n "  Auto-merge? [y/N]: "
    read -r enable_auto

    local trigger=$([[ "$trigger_ci" =~ ^[Yy]$ || -z "$trigger_ci" ]] && echo "true" || echo "false")
    local approve=$([[ "$approve_pr" =~ ^[Yy]$ || -z "$approve_pr" ]] && echo "true" || echo "false")
    local auto=$([[ "$enable_auto" =~ ^[Yy]$ ]] && echo "true" || echo "false")

    echo ""
    echo "→ Processing ${count} PR(s) in parallel (max 5 concurrent)..."
    echo ""

    # Process PRs in parallel with concurrency limit
    local max_jobs=5
    for pr in "${pr_numbers[@]}"; do
      # Process in background
      (process_pr "$pr" "$repo" "$trigger" "$approve" "$auto") &

      # Limit concurrent jobs
      while [[ $(jobs -r | wc -l) -ge $max_jobs ]]; do
        sleep 0.1
      done
    done

    # Wait for all background jobs to complete
    wait

    echo "✓ Completed processing ${count} PR(s)"
  done
}

main "$@"
