#!/usr/bin/env zsh

FILE=${1:-"Chart.yaml"}
if [ ! -f "$FILE" ]; then
  echo "Helm chart \"$FILE\" not found!"
  exit 1
fi

increment_patch() {
  local version=$1
  local parts=("${(@s/./)version}")  # Split version by '.'
  local major=${parts[1]}
  local minor=${parts[2]}
  local patch=${parts[3]}
  patch=$((patch + 1))
  echo "$major.$minor.$patch"
}

current_version=$(yq eval '.version' ${FILE})
current_app_version=$(yq eval '.appVersion' ${FILE})

new_version=$(increment_patch "${current_version}")
new_app_version=$(increment_patch "${current_app_version}")

yq eval ".version = \"${new_version}\"" -i ${FILE}
yq eval ".appVersion = \"${new_app_version}\"" -i ${FILE}

echo "Updated versions in ${FILE}, version: ${new_version}, appVersion: ${new_app_version}"
