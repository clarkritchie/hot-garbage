#!/usr/bin/env zsh
git fetch --prune

for branch in ${(f)"$(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | grep '\[gone\]' | awk '{print $1}')"}; do
  echo "Deleting local branch: $branch"
  git branch -d "$branch"
done

