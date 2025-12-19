#!/bin/zsh
# Interactive prompt for Artifactory Python query tool

#
# Make sure to run jf login!
#

echo "🔍 Artifactory Query Tool"
echo "=========================="

export PYTHONPATH=$(poetry env info --path)/lib/python3.12/site-packages

#
# EXTRA_ARGS can be anything that gets passed on to the Python script
# so for example, the default is to query for tags that are 7 chars
# But there is an argument "tag-length" so you could run this as:
#
# ./run.zsh
# ./run.zsh --tag-length=10
#
EXTRA_ARGS="$@"

export LOG_LEVEL=info

PYTHON_SCRIPT="./query_artifactory.py"

# Docker and Helm menu options
# Options are loaded from auto-generated files
# Run ./generate-options.zsh to regenerate the lists
DOCKER_OPTIONS_FILE="${0:a:h}/.docker-options"
HELM_OPTIONS_FILE="${0:a:h}/.helm-options"

if [[ ! -f "$DOCKER_OPTIONS_FILE" ]] || [[ ! -f "$HELM_OPTIONS_FILE" ]]; then
  echo "⚠️  Options files not found. Generating..."
  "${0:a:h}/generate-options.zsh"
fi

# Read Docker options from file (skip comment lines)
DOCKER_OPTIONS=()
while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue
  DOCKER_OPTIONS+=("$line")
done < "$DOCKER_OPTIONS_FILE"

# Read Helm options from file (skip comment lines)
HELM_OPTIONS=()
while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue
  HELM_OPTIONS+=("$line")
done < "$HELM_OPTIONS_FILE"

PYPI_OPTIONS=(
  "sre-libs"
)

# Sort the arrays
DOCKER_OPTIONS=("${(@o)DOCKER_OPTIONS}")
PYPI_OPTIONS=("${(@o)PYPI_OPTIONS}")

# Prompt for environment (dev/prod)
echo "Select environment (default: dev):"
select ENVIRONMENT in dev prod; do
  [[ -z "$ENVIRONMENT" ]] && ENVIRONMENT=dev
  break
done

# Prompt for tag length
echo "Select tag length (default: 7):"
select TAG_LENGTH_OPTION in "7 (example: 81fa1fd)" "10 (example: 7ca9926-ms)" "Enter custom length"; do
  if [[ "$TAG_LENGTH_OPTION" == "7 (example: 81fa1fd)" ]]; then
    TAG_LENGTH=7
    break
  elif [[ "$TAG_LENGTH_OPTION" == "10 (example: 7ca9926-ms)" ]]; then
    TAG_LENGTH=10
    break
  elif [[ "$TAG_LENGTH_OPTION" == "Enter custom length" ]]; then
    echo -n "Enter tag length: "
    read TAG_LENGTH
    # Validate that it's a number
    if [[ ! "$TAG_LENGTH" =~ ^[0-9]+$ ]]; then
      echo "Invalid input. Using default length of 7."
      TAG_LENGTH=7
    fi
    break
  fi
  echo "Invalid selection. Please choose a valid option."
done

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

echo "\n🚀 Running: $PYTHON_SCRIPT $ITEM_NAME $ARTIFACT_TYPE $ENVIRONMENT --tag-length=$TAG_LENGTH $EXTRA_ARGS\n"
poetry run $PYTHON_SCRIPT "$ITEM_NAME" "$ARTIFACT_TYPE" "$ENVIRONMENT" --tag-length=$TAG_LENGTH $EXTRA_ARGS
