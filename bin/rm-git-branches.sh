#!/usr/bin/env bash

BRANCH_AGE=${1:-7}

echo "Looking for branches older than $BRANCH_AGE days..."

# Get the current date in seconds since epoch
current_date=$(date +%s)

# List all local branches except the current one
branches=$(git branch --format='%(refname:short)')

skip_branches=("main" "master" "stage" "dev")

for branch in $branches; do
  # Check if the branch is in the skip list
  if [[ " ${skip_branches[@]} " =~ " $branch " ]]; then
    echo "Skipping branch '$branch'"
    continue
  fi

  # Get the last commit date of the branch in seconds since epoch
  last_commit_date=$(git log -1 --format=%ct $branch)

  # Calculate the age of the branch in days
  branch_age=$(( (current_date - last_commit_date) / 86400 ))

  # Check if the branch is older than X days
  if [ $branch_age -gt ${BRANCH_AGE} ]; then
    # echo "Branch '$branch' is $branch_age days old."
    # Red 31
    # Green 32
    # Yellow 33
    # Blue 34
    # Magenta 35
    # Cyan 36
    # White 37
    echo -e "Branch '\033[0;32m$branch\033[0m' is $branch_age days old."

    read -p "Do you want to delete this branch? (y/n) " answer
    if [ "$answer" = "y" ]; then
      git branch -D $branch
    fi
  fi
done
