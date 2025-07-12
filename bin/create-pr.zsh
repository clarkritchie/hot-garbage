#!/usr/bin/env zsh

# Use first argument as PR message if provided
pr_message="$1"

# Prompt if PR message is not provided
if [[ -z "$pr_message" ]]; then
  read "pr_message?Enter PR title/body: "
  if [[ -z "$pr_message" ]]; then
    echo "Error: Title/body cannot be empty."
    return 1
  fi
fi

# Prompt for draft or regular PR
read "draft_choice?Create as draft PR? (y/N): "
if [[ "$draft_choice" =~ "^[Yy]$" ]]; then
  draft_flag="--draft"
else
  draft_flag=""
fi

# Prompt for reviewers
echo "Select reviewers:"
echo "1) Nitesh"
echo "2) Sai"
echo "3) Robby"
echo "4) Ashok"
echo "5) Brandon"
echo "6) None"
echo "7) Custom (enter manually)"
read "reviewer_choice?Choose option (1-6) [default: 1]: "
reviewer_choice="${reviewer_choice:-1}"

case "$reviewer_choice" in
  1)
    reviewers="nxk0122"
    ;;
  2)
    reviewers="sainathvadyala"
    ;;
  3)
    reviewers="dexcom-robby"
    ;;
  4)
    reviewers="ashok-danaraddi"
    ;;
  5)
    reviewers="BrandonCsSanders"
    ;;
  6)
    reviewers=""
    ;;
  7)
    read "reviewers?Enter reviewers (comma-separated): "
    ;;
  *)
    echo "Invalid choice, defaulting to nxk0122"
    reviewers="nxk0122"
    ;;
esac

# Prompt for base branch
read "base_branch?Enter base branch [default: main]: "
base_branch="${base_branch:-main}"

# Commit and create PR
git commit --no-verify -m "$pr_message"
if [[ -n "$reviewers" ]]; then
  gh pr create --title="$pr_message" --body="$pr_message" --base="$base_branch" --reviewer="$reviewers" $draft_flag
else
  gh pr create --title="$pr_message" --body="$pr_message" --base="$base_branch" $draft_flag
fi

