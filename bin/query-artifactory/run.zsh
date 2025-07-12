#!/bin/zsh
# Interactive prompt for Artifactory Python query tool

echo "🔍 Artifactory Query Tool"
echo "=========================="

export PYTHONPATH=$(poetry env info --path)/lib/python3.12/site-packages

EXTRA_ARGS="$@"

export LOG_LEVEL=info

PYTHON_SCRIPT="./query_artifactory.py"

# Docker and Helm menu options
DOCKER_OPTIONS=(
  "vnv-ddlm-robot-tests"
  "data-platform-validation"
  "data-platform-validation-v2"
  "cams-tests"
  "spanner-backup-monitor"
)

HELM_OPTIONS=(
  "platform-validation-share"
  "data-platform-validation"
  "data-platform-validation-v2"
  "cams-tests"
  "spanner-backup-monitor"
)

PYPI_OPTIONS=(
  "sre-libs"
)

# Prompt for artifact type
echo "Select artifact type:"
select ARTIFACT_TYPE in docker helm pypi; do
  if [[ -n "$ARTIFACT_TYPE" ]]; then
    break
  fi
  echo "Invalid selection. Please choose 1, 2, or 3."
done

# Prompt for item name based on type
if [[ "$ARTIFACT_TYPE" == "docker" ]]; then
  echo "Select Docker image:"
  select ITEM_NAME in $DOCKER_OPTIONS "Enter custom name"; do
    if [[ "$ITEM_NAME" == "Enter custom name" ]]; then
      echo -n "Enter Docker image name: "
      read ITEM_NAME
      break
    elif [[ -n "$ITEM_NAME" ]]; then
      break
    fi
    echo "Invalid selection. Please choose a valid option."
  done
elif [[ "$ARTIFACT_TYPE" == "helm" ]]; then
  echo "Select Helm chart:"
  select ITEM_NAME in $HELM_OPTIONS "Enter custom name"; do
    if [[ "$ITEM_NAME" == "Enter custom name" ]]; then
      echo -n "Enter Helm chart name: "
      read ITEM_NAME
      break
    elif [[ -n "$ITEM_NAME" ]]; then
      break
    fi
    echo "Invalid selection. Please choose a valid option."
  done
elif [[ "$ARTIFACT_TYPE" == "pypi" ]]; then
  echo "Select PyPI package:"
  select ITEM_NAME in $PYPI_OPTIONS "Enter custom name"; do
    if [[ "$ITEM_NAME" == "Enter custom name" ]]; then
      echo -n "Enter PyPI package name: "
      read ITEM_NAME
      break
    elif [[ -n "$ITEM_NAME" ]]; then
      break
    fi
    echo "Invalid selection. Please choose a valid option."
  done
fi

# Run the Python script with the selected arguments
if [[ -z "$ITEM_NAME" ]]; then
  echo "❌ Error: No item name specified"
  exit 1
fi

echo "\n🚀 Running: $PYTHON_SCRIPT $ITEM_NAME $ARTIFACT_TYPE $EXTRA_ARGS\n"
$PYTHON_SCRIPT "$ITEM_NAME" "$ARTIFACT_TYPE" $EXTRA_ARGS
