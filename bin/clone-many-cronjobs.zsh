#!/usr/bin/env zsh
#
# This is nearly identical to clone-cronjob.zsh except that
# given a namespace -- or namespace prefix -- it will iterate through
# them all.
#
# For example:  ./clone-many-cronjobs.zsh cams-ui
#
# This will find all namespaces starting with "cams-ui" and
# prompt the user to confirm each one before cloning the
# cronjob in that namespace.
#

NAMESPACE_PREFIX="${1:-vnv}"

echo "Collecting namespaces starting with: $NAMESPACE_PREFIX"

# Initialize an array to hold confirmed namespaces
confirmed_namespaces=()

# iterate through namespaces and prompt for confirmation
while read -r ns; do
  echo "Namespace: $ns"
  read -q "REPLY?Type 'y' to include or any other key to skip: "
  echo ""

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    confirmed_namespaces+=("$ns")
  else
    echo "Skipping $ns"
  fi
done < <(kubectl get ns | grep "${NAMESPACE_PREFIX}" | awk '{ print $1 }')

# Do the actual work of deleting jobs in confirmed namespaces
for ns in "${confirmed_namespaces[@]}"; do
  kubectl config set-context --current --namespace="$ns"
  echo "🟢 Switching to namespace: $ns"

  export CRON_JOB=$(kubectl get cronjob -o custom-columns=NAME:.metadata.name --no-headers)
  export NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
  export JOB="clone-of-${CRON_JOB}"
  echo "Cloning $CRON_JOB as $JOB in namespace $NS"

  kubectl delete job.batch/${JOB} --ignore-not-found
  kubectl create job \
    --from="cronjob.batch/${CRON_JOB}" \
    ${JOB} \
    --namespace ${NS}
  echo ""
done