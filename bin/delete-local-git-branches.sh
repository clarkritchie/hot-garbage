#!/usr/bin/env bash

# Get the current date in seconds since epoch
current_date=$(date +%s)

# List all local branches except the current one
branches=$(git branch --format='%(refname:short)')

for branch in $branches; do
  # Get the last commit date of the branch in seconds since epoch
  last_commit_date=$(git log -1 --format=%ct $branch)

  # Calculate the age of the branch in days
  branch_age=$(( (current_date - last_commit_date) / 86400 ))

  # Check if the branch is older than 14 days
  if [ $branch_age -gt 14 ]; then
    echo "Branch '$branch' is $branch_age days old."
    read -p "Do you want to delete this branch? (y/n) " answer
    if [ "$answer" = "y" ]; then
      git branch -d $branch
    fi
  fi
done