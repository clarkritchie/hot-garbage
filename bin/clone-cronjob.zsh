#!/usr/bin/env zsh
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
    ${JOB} \
    --namespace ${NS}
