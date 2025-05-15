#!/usr/bin/env zsh


increment_patch() {
  local version=$1
  local parts=("${(@s/./)version}")  # Split version by '.'
  local major=${parts[1]}
  local minor=${parts[2]}
  local patch=${parts[3]}
  patch=$((patch + 1))
  echo "$major.$minor.$patch"
}

current_version=$(yq eval '.version' Chart.yaml)
current_app_version=$(yq eval '.appVersion' Chart.yaml)

new_version=$(increment_patch "$current_version")
new_app_version=$(increment_patch "$current_app_version")

yq eval ".version = \"$new_version\"" -i Chart.yaml
yq eval ".appVersion = \"$new_app_version\"" -i Chart.yaml

echo "Updated version to $new_version and appVersion to $new_app_version"
