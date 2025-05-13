#!/usr/bin/env zsh

for branch in $(git branch -r | grep job); do
  # Remove the 'origin/' prefix
  clean_branch=${branch#origin/}
  echo $clean_branch
  git push origin --delete $clean_branch
done
