#!/usr/bin/env zsh
#
# Clones the first cronjob in the current namespace to a job
# This is useful for testing cronjobs without waiting for the schedule
# to trigger as the job will run immediately.
# It will delete any previous job with the same name.
#

echo "Cloning the first cronjob in the current namespace to a job"

export CRON_JOB=$(kubectl get cronjob -o custom-columns=NAME:.metadata.name --no-headers)
if [[ -z "$CRON_JOB" ]]; then
    echo "No cronjob found in the current namespace"
    exit 1
fi

export NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
export JOB="clone-of-${CRON_JOB}"
echo "Cloning $CRON_JOB as $JOB in namespace $NS"

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
