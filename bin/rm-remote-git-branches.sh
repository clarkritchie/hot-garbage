#!/usr/bin/env bash

PATTERN=$1
BRANCH_AGE=${2:-7}

if [[ -z "${PATTERN}" ]]; then
  echo "Usage: $0 [pattern] [branch_age_in_days]"
  echo "Example: $0 'feature/.*' 30"
  echo "         $0 'hotfix/.*' 14"
  echo "         $0 'bugfix-.*' 7"
  echo "         $0 '.*' 30          # Evaluate ALL remote branches"
  echo "         $0 '*' 30           # Evaluate ALL remote branches"
  echo ""
  echo "Pattern supports regex matching for remote branch names"
  echo "Use '.*' or '*' to evaluate all remote branches"
  exit 1
fi

echo "Looking for remote branches older than $BRANCH_AGE days that match pattern '${PATTERN}'..."

# Fetch latest remote information
echo "Fetching latest remote branch information..."
git fetch --prune

# Get the current date in seconds since epoch
current_date=$(date +%s)

# List all remote branches and filter by pattern
if [[ "${PATTERN}" == "*" || "${PATTERN}" == ".*" ]]; then
  echo "Evaluating ALL remote branches..."
  branches=$(git branch -r --format='%(refname:short)' | grep -v "origin/HEAD" | sed 's/origin\///')
else
  branches=$(git branch -r --format='%(refname:short)' | grep -E "^origin/${PATTERN}" | sed 's/origin\///')
fi

if [[ -z "$branches" ]]; then
  if [[ "${PATTERN}" == "*" || "${PATTERN}" == ".*" ]]; then
    echo "No remote branches found (excluding HEAD)"
  else
    echo "No remote branches found matching pattern '${PATTERN}'"
  fi
  exit 0
fi

skip_branches=("main" "master" "stage" "dev" "HEAD")

# Add extra confirmation for wildcard patterns
if [[ "${PATTERN}" == "*" || "${PATTERN}" == ".*" ]]; then
  echo ""
  echo "⚠️  WARNING: You are about to evaluate ALL remote branches for deletion!"
  echo "This will check $(echo "$branches" | wc -w) remote branches (excluding protected branches)."
  echo ""
  read -p "Are you sure you want to continue? (y/n) " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Operation cancelled."
    exit 0
  fi
  echo ""
fi

echo "Found $(echo "$branches" | wc -w) remote branches to evaluate:"
echo "$branches" | tr ' ' '\n' | sed 's/^/  - /'
echo ""

for branch in $branches; do
  # Check if the branch is in the skip list
  if [[ " ${skip_branches[@]} " =~ " $branch " ]]; then
    echo "Skipping protected branch '$branch'"
    continue
  fi

  # Get the last commit date of the remote branch in seconds since epoch
  last_commit_date=$(git log -1 --format=%ct origin/$branch 2>/dev/null)

  # Skip if we can't get the commit date (branch might not exist)
  if [[ -z "$last_commit_date" ]]; then
    echo "Skipping branch '$branch' - unable to get commit date"
    continue
  fi

  # Calculate the age of the branch in days
  branch_age=$(( (current_date - last_commit_date) / 86400 ))

  # Check if the branch is older than X days
  if [ $branch_age -gt ${BRANCH_AGE} ]; then
  # \033[0;32mIAM Policy\033[0m
    echo "Remote branch 'origin/$branch' is $branch_age days old."
    read -p "Do you want to delete this remote branch? (y/n) " answer
    if [ "$answer" = "y" ]; then
      echo "Deleting remote branch 'origin/$branch'..."
      git push origin --delete $branch
      if [ $? -eq 0 ]; then
        echo "✅ Successfully deleted remote branch 'origin/$branch'"
        # Also delete the local tracking branch if it exists
        if git show-ref --verify --quiet refs/heads/$branch; then
          git branch -D $branch
          echo "✅ Also deleted local tracking branch '$branch'"
        fi
      else
        echo "❌ Failed to delete remote branch 'origin/$branch'"
      fi
    fi
  else
    echo "Remote branch 'origin/$branch' is only $branch_age days old (keeping)"
  fi
done

echo ""
echo "✅ Remote branch cleanup completed!"
