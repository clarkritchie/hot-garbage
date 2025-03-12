#!/usr/bin/env bash

#!/bin/bash

JOB=$1
NAMESPACE=$2

# kubectl get job $JOB -n $NAMESPACE -o json | jq 'del(.spec.selector)' | jq 'del(.spec.template.metadata.labels)' | kubectl replace --force -f -
# kubectl wait --for=condition=complete job/$JOB -n $NAMESPACE --timeout 120s

JOB="spanner-restore-job"
NAMESPACE="spanner-restore"
kubectl get job $JOB -n $NAMESPACE -o json | \
  jq 'del(.spec.selector)' | \
  jq 'del(.spec.template.metadata.labels)' | \
  kubectl replace --force -f -


# kubectl wait --for=condition=complete job/$JOB -n $NAMESPACE --timeout 120s