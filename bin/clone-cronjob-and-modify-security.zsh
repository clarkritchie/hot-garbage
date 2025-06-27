#!/usr/bin/env zsh
#
# Clone a cronjob to a job but amend the securityContext in-flight
#
# pipe this scripts output to:  kubectl apply -f -
#

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <cronjob-name> <namespace>"
  exit 1
fi

CRON_JOB=$1
ns=$2
kubectl get cronjob ${CRON_JOB} -n ${ns} -o json \
  | jq '.kind="Job" | .spec = .spec.jobTemplate.spec | del(.spec.schedule, .spec.jobTemplate, .status) | .spec.template.spec.containers[0].securityContext = {allowPrivilegeEscalation: false,runAsUser: 0,capabilities: { add: ["NET_RAW"] }}'

