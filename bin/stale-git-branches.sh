#!/usr/bin/env bash

DAYS_AGO=${1:-45}

# Fetch all branches from the remote
git fetch --all --prune

# Get today's date in seconds since the epoch
current_date=$(date +%s)

git for-each-ref --sort=committerdate refs/remotes/origin/ --format="%(committerdate:short) %(refname:short)" |
while read -r commit_date branch; do
  # Convert commit date to seconds since the epoch
  # Linux:
  # commit_date_seconds=$(date -d "$commit_date" +%s)
  # Mac OS:
  commit_date_seconds=$(date -j -f "%Y-%m-%d" "$commit_date" +"%s")

  # Calculate the age of the branch in days
  age_days=$(( (current_date - commit_date_seconds) / 86400 ))

  if [ "$age_days" -gt ${DAYS_AGO} ]; then
    echo "$commit_date - ${branch#refs/remotes/} is older than ${DAYS_AGO} days (age is $age_days days)"
  fi

  # if [[ $branch == *job* ]]; then
  #   stripped_branch=${branch#origin/}
  #   echo "Job branch: $stripped_branch"
  #   git push origin :$stripped_branch
  # fi
done