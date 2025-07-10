#!/usr/bin/env zsh

DAYS_OLD=${1:-180}

repos=("sre" "database" "sre-libs")

# Iterate over the array
for repo in "${repos[@]}"; do
  cat <<EOF > .env
REPO_OWNER=dexcom-inc
REPO_NAME=${repo}
DAYS_OLD=${DAYS_OLD}
EOF

  make run
done

