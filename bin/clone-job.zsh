#!/usr/bin/env zsh
#
# Clones the first cronjob in the current namespace to a job
# This is useful for testing cronjobs without waiting for the schedule
# to trigger as the job will run immediately.
# It will delete any previous job with the same name.
#

echo "Cloning the first job in the current namespace"

export JOB=$(kubectl get job -o custom-columns=NAME:.metadata.name --no-headers)
if [[ -z "$JOB" ]]; then
    echo "No job found in the current namespace"
    exit 1
fi

export NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
export CLONED_JOB="clone-of-${JOB}"
echo "Cloning $JOB as $CLONED_JOB in namespace $NS"

# delete the previous clone, if it exists
kubectl delete job.batch/${CLONED_JOB} --ignore-not-found
kubectl get job $JOB -n $NS -o yaml | \
    sed "s/name: $JOB/name: $CLONED_JOB/" | \
    yq 'del(.spec.template.metadata.labels)' | \
    yq 'del(.spec.template.metadata.labels)' | \
    kubectl apply -n $NS -f -