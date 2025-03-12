#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: $0 <suffix>"
  exit 1
fi

suffix=$1

# Get a list of all local branches
branches=$(git branch --format='%(refname:short)')

# Loop through each branch
for branch in $branches; do
  new_branch="${branch}${suffix}"
  read -p "Do you want to rename branch '$branch' to '$new_branch' ? (y/n) " answer
  if [ "$answer" == "y" ]; then
    git branch -m "$branch" "$new_branch"
    echo "Renamed branch '$branch' to '$new_branch'"
  fi
done