#!/usr/bin/env zsh

set -e

PR_NUMBER=${1}
if [ -z ${PR_NUMBER} ]; then
  echo "Missing pull request number"
  exit 1
fi

gh pr review ${PR_NUMBER} --approve
gh pr merge ${PR_NUMBER} --squash --delete-branch

