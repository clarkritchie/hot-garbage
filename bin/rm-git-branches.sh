#!/usr/bin/env bash

BRANCH_AGE=${1:-7}

# any branch in this list is skipped
skip_branches=("main" "master" "stage" "dev")

# Get the current date in seconds since epoch
current_date=$(date +%s)

# List all local branches except the current one
branches=$(git branch --format='%(refname:short)')

echo "Looking for branches older than $BRANCH_AGE days..."
for branch in $branches; do
  # Check if the branch is in the skip list
  if [[ " ${skip_branches[@]} " =~ " $branch " ]]; then
    echo "Skipping protected branch: '$branch'"
    continue
  fi

  # Get the last commit date of the branch in seconds since epoch
  last_commit_date=$(git log -1 --format=%ct $branch)

  # Get current date at midnight (start of day)
  current_date_midnight=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-%d)" +%s)
  
  # Get last commit date at midnight (start of that day)
  last_commit_midnight=$(date -j -f "%Y-%m-%d" "$(date -r $last_commit_date +%Y-%m-%d)" +%s)

  # Calculate the age of the branch in calendar days
  branch_age=$(( (current_date_midnight - last_commit_midnight) / 86400 ))

  # Check if the branch is equal to or older than X days
  if [ $branch_age -ge ${BRANCH_AGE} ]; then
    # Red 31
    # Green 32
    # Yellow 33
    # Blue 34
    # Magenta 35
    # Cyan 36
    # White 37
    echo -e "Branch '\033[0;32m$branch\033[0m' is $branch_age days old."
    # date uses BSD syntax for Mac OS
    echo "  The last commit was on: $(date -r "$last_commit_date" '+%Y-%m-%d %H:%M:%S')"

    read -p "Do you want to delete this branch? (y/n) " answer
    if [ "$answer" = "y" ]; then
      git branch -D $branch
    fi
  fi
done
