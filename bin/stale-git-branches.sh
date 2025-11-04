#!/usr/bin/env bash

DAYS_AGO=${1:-45}

# Fetch all branches from the origin remote
git fetch origin --prune

# Get today's date in seconds since the epoch
current_date=$(date +%s)

# Check OS for date command compatibility
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  date_cmd() {
    date -j -f "%Y-%m-%d" "$1" +"%s"
  }
else
  # Linux
  date_cmd() {
    date -d "$1" +%s
  }
fi

stale_branches=()
while read -r commit_date branch; do
  # Convert commit date to seconds since the epoch
  commit_date_seconds=$(date_cmd "$commit_date")

  # Calculate the age of the branch in days
  age_days=$(((current_date - commit_date_seconds) / 86400))

  if [ "$age_days" -gt ${DAYS_AGO} ]; then
    stale_branches+=("${branch}")
  fi
done < <(git for-each-ref --sort=committerdate refs/remotes/origin/ --format="%(committerdate:short) %(refname:short)")

if [ ${#stale_branches[@]} -eq 0 ]; then
  echo "No stale branches found older than ${DAYS_AGO} days."
  exit 0
fi

echo "The following branches are older than ${DAYS_AGO} days:"
for branch in "${stale_branches[@]}"; do
  echo "  - ${branch#origin/}"
done
echo

read -p "Do you want to delete these branches from the remote? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Deleting branches..."
  for branch in "${stale_branches[@]}"; do
    branch_name=${branch#origin/}
    echo "Deleting ${branch_name}..."
    git push origin --delete "${branch_name}"
  done
  echo "All specified branches have been deleted."
else
  echo "Aborting. No branches were deleted."
fi
lis