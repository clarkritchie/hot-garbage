#!/usr/bin/env zsh

NAMESPACE_PREFIX="${1:-vnv}"

echo "Collecting namespaces starting with: $NAMESPACE_PREFIX"

# Initialize an array to hold confirmed namespaces
confirmed_namespaces=()

# iterate through namespaces and prompt for confirmation
while read -r ns; do
  echo "Namespace: $ns"
  read -q "REPLY?Type 'y' to include, 'q' to quit, or any other key to skip: "
  echo ""

  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    confirmed_namespaces+=("$ns")
  else
    echo "Skipping $ns"
  fi
done < <(kubectl get ns | grep "${NAMESPACE_PREFIX}" | awk '{ print $1 }')

for ns in "${confirmed_namespaces[@]}"; do
  echo "🟢 Processing namespace: $ns"
  kubectl config set-context --current --namespace="$ns"
  kubectl config set-context --current --namespace=$ns
  
  CRON_JOB=$(kubectl get all | grep '^cronjob\.batch' | awk '{ print $1 }')

  if [[ "$CRON_JOB" != "" ]]; then
    echo "🟢 Cloning cronjob: $CRON_JOB"
    kubectl delete job "testing" --ignore-not-found
    kubectl create job \
      --from=${CRON_JOB} \
      "testing" \
      --namespace ${ns}
  fi
  echo ""
done
