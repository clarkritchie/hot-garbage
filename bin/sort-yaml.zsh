#!/usr/bin/env zsh

FILE=${1:-}
if [[ -z $FILE ]]; then
  echo "Usage: $0 <yaml-file>"
  exit 1
fi

tempfile=$(mktemp)
yq eval 'sort_keys(.)' ${FILE} > ${tempfile}
mv ${tempfile} ${FILE}
rm -f $tempfile