#!/usr/bin/env bash

OWNER=${1:-clarkritchie}
REPO=${2}
WORKFLOW_ID=${3}

if [ -z "$REPO" ] || [ -z "$WORKFLOW_ID" ]; then
  echo "Error: REPO and WORKFLOW_ID must be set."
  exit 1
fi


# May want to do one of these beforehand:
# gh config set pager cat
# GH_PAGER=cat

cat <<EOF
You are about to delete the workflow run history for:
- Owner: $OWNER
- Repository: $REPO
- Workflow ID: $WORKFLOW_ID
EOF

read -p "Do you want to proceed? (yes/no): " confirmation

if [[ "$confirmation" == "yes" ]]; then
    gh api repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs --paginate -q '.workflow_runs[] | select(.head_branch != "master") | "\(.id)"' | \
    xargs -n1 -I % gh api repos/$OWNER/$REPO/actions/runs/% -X DELETE

else
    echo "Operation cancelled."
fi


# List runs
# gh api -X GET /repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs | jq '.workflow_runs[] | .id' | while read run_id; do
#     # Delete run
#     # gh api -X DELETE /repos/$OWNER/$REPO/actions/runs/$run_id
#     echo $run_id
# done

# gh api repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs --paginate -q '.workflow_runs[] | select(.head_branch != "master") | "\(.id)"' | \
# xargs -n1 -I % gh api repos/$OWNER/$REPO/actions/runs/% -X DELETE


