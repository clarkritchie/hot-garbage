#!/usr/bin/env zsh

# Use first argument as PR message if provided
pr_message="$1"

# Prompt if PR message is not provided
if [[ -z "$pr_message" ]]; then
  # Get the last commit message as default
  last_commit_message=$(git log -1 --pretty=format:"%s")
  read "pr_message?Enter PR title/body [default: $last_commit_message]: "
  if [[ -z "$pr_message" ]]; then
    pr_message="$last_commit_message"
  fi
fi

# Prompt for draft or regular PR, default is no
read -r "draft_choice?Create as draft PR? (Y/n): "
if [[ -z "$draft_choice" || "$draft_choice" =~ ^[Nn]$ ]]; then
  draft_flag=""
else
  draft_flag="--draft"
fi

# Prompt for reviewers
echo "Select reviewers:"
echo "1) None"
echo "2) Nitesh"
echo "3) Sai"
echo "4) Robby"
echo "5) Ashok"
echo "6) Brandon"
echo "7) Enter other name"
read "reviewer_choice?Choose option (1-7) [default: 1]: "
reviewer_choice="${reviewer_choice:-1}"

case "$reviewer_choice" in
  1)
    reviewers=""
    ;;
  2)
    reviewers="nxk0122"
    ;;
  3)
    reviewers="sainathvadyala"
    ;;
  4)
    reviewers="dexcom-robby"
    ;;
  5)
    reviewers="ashok-danaraddi"
    ;;
  6)
    reviewers="BrandonCsSanders"
    ;;
  7)
    read "reviewers?Enter reviewers (comma-separated): "
    ;;
  *)
    echo "Invalid choice, defaulting to none"
    reviewers=""
    ;;
esac

# Prompt for base branch
echo "Select base branch:"
echo "1. main"
echo "2. stage"
echo "3. other"
read "branch_choice?Enter choice [1-3, default: 1]: "
branch_choice="${branch_choice:-1}"

case $branch_choice in
  1)
    base_branch="main"
    ;;
  2)
    base_branch="stage"
    ;;
  3)
    read "base_branch?Enter custom base branch name: "
    ;;
  *)
    echo "Invalid choice, defaulting to main"
    base_branch="main"
    ;;
esac

# Commit and create PR
git commit --no-verify -m "$pr_message"
if [[ -n "$reviewers" ]]; then
  gh pr create --title="$pr_message" --body="$pr_message" --base="$base_branch" --reviewer="$reviewers" $draft_flag
else
  gh pr create --title="$pr_message" --body="$pr_message" --base="$base_branch" $draft_flag
fi

read -r "open_browser?Open PR in browser? (Y/n): "
if [[ -z "$open_browser" || "$open_browser" =~ ^[Nn]$ ]]; then
  gh pr view --web
fi
