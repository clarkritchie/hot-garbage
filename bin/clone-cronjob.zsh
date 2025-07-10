#!/usr/bin/env zsh
#
# Clones a selected cronjob in the current namespace to a job
# This is useful for testing cronjobs without waiting for the schedule
# to trigger as the job will run immediately.
# It will delete any previous job with the same name.
#

echo "Clone Cronjob to Job"
echo "===================="

# Get current namespace
export NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
if [[ -z "$NS" ]]; then
    NS="default"
fi
echo "Current namespace: $NS"
echo

# Get all cronjobs
CRONJOBS=($(kubectl get cronjob -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null))
if [[ ${#CRONJOBS[@]} -eq 0 ]]; then
    echo "No cronjobs found in namespace '$NS'"
    exit 1
fi

# Display cronjobs with numbers
echo "Available cronjobs:"
for i in {1..${#CRONJOBS[@]}}; do
    echo "  $i) ${CRONJOBS[$i]}"
done
echo

# Get user selection
while true; do
    read -r "selection?Select a cronjob to clone (1-${#CRONJOBS[@]}): "
    
    # Validate selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#CRONJOBS[@]} ]]; then
        export CRON_JOB=${CRONJOBS[$selection]}
        break
    else
        echo "Invalid selection. Please enter a number between 1 and ${#CRONJOBS[@]}."
    fi
done

export JOB="clone-of-${CRON_JOB}"
echo
echo "Cloning cronjob '$CRON_JOB' as job '$JOB' in namespace '$NS'"

# delete the previous clone, if it exists
kubectl delete job.batch/${JOB} --ignore-not-found
kubectl create job \
    --from="cronjob.batch/${CRON_JOB}" \
    "${JOB}" \
    --namespace ${NS}

# loop until the pod is ready, with a timeout
MAX_RETRIES=30  # Maximum number of retries (30 retries * 2 seconds = 1 minute timeout)
RETRY_COUNT=0
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  pod_status=$(kubectl get pods | grep clone | awk '{print $2}')
  if [[ "$pod_status" == "1/1" ]]; then
    echo "Pod is ready."
    break
  else
    echo "Waiting for pod to be ready... (Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 2
    ((RETRY_COUNT++))
  fi
done

if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
  echo "Timeout reached. Pod did not become ready."
  exit 1
fi
