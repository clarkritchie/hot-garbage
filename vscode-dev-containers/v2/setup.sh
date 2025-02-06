#!/usr/bin/env bash

# convert this to 2 spaces:
# cat setup.sh | sed 's/^\(\s*\)\t/\1  /g' > out; mv out setup.sh; chmod +x setup.sh

# this may not be reliable way to determine if the user is running this from within
# VS Code terminal -- it should be run from the host
if [ ! -z "${REMOTE_CONTAINERS_IPC}" ]; then
  echo "Run this from your host, not within VS Code"
  exit 1
fi

VSCODE_ROOT=${1:-}
if [ -z "${VSCODE_ROOT}" ]; then
  read -p "Please enter the full path to your the root of your VS Code project: " VSCODE_ROOT
fi

# removes a trailing slash, if it exists
VSCODE_ROOT="${VSCODE_ROOT%/}"

if [ ! -d "$VSCODE_ROOT" ]; then
  echo "${VSCODE_ROOT} does not exist."
  exit 1
fi

DEVCONTAINER_DIR=${VSCODE_ROOT}/.devcontainer
mkdir -p ${DEVCONTAINER_DIR}

DEV_CONTAINER_CONFIG="${DEVCONTAINER_DIR}/devcontainer.json"
DEV_CONTAINER_COMPOSE_CONFIG="${DEVCONTAINER_DIR}/devcontainer.yaml"
DOCKERFILE="${DEVCONTAINER_DIR}/Dockerfile.devcontainer"

cat <<EOF

⭐ ⭐ ⭐ --- Dev Container Setup --- ⭐ ⭐ ⭐

The following paths will be used:

VS Code root:     ${VSCODE_ROOT}
Config:           ${DEV_CONTAINER_CONFIG}
Docker Compose:   ${DEV_CONTAINER_COMPOSE_CONFIG}
Dockerfile:       ${DOCKERFILE}

EOF

# Prompt the user for confirmation
read -p "🌈 Copy your aliases in ~/.zshrc  (y/n) " ALIASES
if [ "${ALIASES}" == "y" ]; then
  cat ~/.zshrc | grep alias > ${DEVCONTAINER_DIR}/aliases.zsh
fi

# Copy any Datadog env vars
echo "🌈 Copying any Datadog env vars from .zshrc"
printf "\n" >> ${DEVCONTAINER_DIR}/aliases.zsh  # ensure this begins on a newline
cat ~/.zshrc | grep DD_ >> ${DEVCONTAINER_DIR}/aliases.zsh
cat ~/.zshrc | grep DATADOG_ >> ${DEVCONTAINER_DIR}/aliases.zsh

# Prompt the user for confirmation
printf '\n'
read -p "Does this all look correct?  Existing files will be overwritten! (y/n) " USER_CONFIRM

# Check the user's confirmation
if [ "${USER_CONFIRM}" != "y" ]; then
  echo "⛔ Please run the script again and enter the complete path to your project's root."
  exit 1
fi

mkdir -p ${VSCODE_ROOT}

# This is a workaround for the Cisco certificate issue on Nitesh's laptop
# cisco.pem was exported from the Keychain Access app and exists
# in this directory -- his has to be imported first for anything in the Dockerfile
# to work, but for everyone else, the file can just be empty, as it is N/A
FILE="${DEVCONTAINER_DIR}/cisco.pem"
echo "🌈 Checking for $FILE"
if [ ! -f "${FILE}" ]; then
  echo "cisco.pem file does not exist"
  touch "$FILE"
else
  echo "cisco.pem file found"
fi

# list your installed extensions with:  code --list-extensions
# settings:   "editor.defaultFormatter": "charliermarsh.ruff",
echo "🌈 Creating ${DEV_CONTAINER_CONFIG}"
cat <<EOF > ${DEV_CONTAINER_CONFIG}
{
  "name": "Dexcom Database Python 3.12 Dev Container",
  "dockerComposeFile": "${DEV_CONTAINER_COMPOSE_CONFIG}",
  "service": "dev_container",
  "workspaceFolder": "/workspace",
  "shutdownAction": "stopCompose",
  "remoteUser": "root",
  "customizations": {
    "vscode": {
      "settings": {
        "http.proxyStrictSSL": false
      },
      "extensions": [
        "angus-mcritchie.quote-swapper",
        "bierner.github-markdown-preview",
        "bierner.markdown-checkbox",
        "bierner.markdown-emoji",
        "bierner.markdown-footnotes",
        "bierner.markdown-mermaid",
        "bierner.markdown-preview-github-styles",
        "bierner.markdown-yaml-preamble",
        "charliermarsh.ruff",
        "davidanson.vscode-markdownlint",
        "github.copilot",
        "github.copilot-chat",
        "github.remotehub",
        "golang.go",
        "gruntfuggly.todo-tree",
        "linhmtran168.mac-ca-vscode",
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-python.debugpy",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-vscode-remote.remote-containers"
        "ms-vscode.makefile-tools",
        "ms-vscode.remote-repositories",
        "redhat.vscode-yaml",
        "redlin.remove-tabs-on-save",
        "ukoloff.win-ca"
      ]
    }
  }
}
EOF

# these paths are, obviously, Mac OS specific
#
# vscode_root:/workspace is a test to see if that is any
# different than a normal bind mount, e.g.
# - ${VSCODE_ROOT}:/workspace-tmp
#
echo "🌈 Creating ${DEV_CONTAINER_COMPOSE_CONFIG}"
cat <<EOF > ${DEV_CONTAINER_COMPOSE_CONFIG}
services:
  dev_container:
    build:
      context: .
      dockerfile: ${DOCKERFILE}
    entrypoint: ./entrypoint.sh
    user: root:root
    volumes:
      - ${HOME}/.config/gcloud:/root/.config/gcloud
      - vscode_root:/workspace
      - ${HOME}/.ssh:/mnt/.ssh:ro
      - ${HOME}/.kube:/root/.kube
      - ${HOME}/.gitconfig:/root/.gitconfig
      - ${HOME}/Library/Preferences/helm:/root/.config/helm:ro
      - ${HOME}/Library/helm:/root/.local/share/helm:ro
      - ${HOME}/.docker:/root/.docker:ro
    networks:
      - dev_network

# this is an experiment to see if the binding to the host OS is any faster
volumes:
  vscode_root:
    driver: local
    driver_opts:
      type: none
      device: ${VSCODE_ROOT}
      o: bind

networks:
  dev_network:
    driver: bridge
    driver_opts:
      com.docker.network.enable_ipv6: "false"
EOF

echo "🌈 Copying entrypoint.sh to ${DEVCONTAINER_DIR}"
cp ./entrypoint.sh ${DEVCONTAINER_DIR}

echo "🌈 Copying Dockerfile.devcontainer to ${DEVCONTAINER_DIR}"
cp ./Dockerfile.devcontainer ${DEVCONTAINER_DIR}

# apply these settings to the user's settings.json file
USER_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
if command -v jq &> /dev/null; then
  echo "🌈 Making some minor edits to your settings.json"
  jq '."python.analysis.autoFormatStrings" = true' "${USER_SETTINGS}" > "${USER_SETTINGS}.tmp"
  jq '."editor.detectIndentation" = true' "${USER_SETTINGS}.tmp" > "${USER_SETTINGS}"
  rm -f "${USER_SETTINGS}.tmp"
else
  cat << EOF

jq is not installed (srsly, how do you even get by??? 😫)

EOF
fi

# general tips
cat << EOF

⭐ ⭐ ⭐ --- Final Tips --- ⭐ ⭐ ⭐

- It is helpful to change your VS Code's default terminal from bash to zsh
- YES, the confusion between precedence on user settings vs. remote settings
  vs. dev container settings is very real -- see the README, please help
- Your personal VS Code settings are located in:

    - ${HOME}/Library/Application Support/Code/User/settings.json

  Some recommended settings:

    - "python.analysis.autoFormatStrings": true,
    - "editor.detectIndentation": true

  Here are some nice terminal colors that you can copy-paste:

    - https://glitchbone.github.io/vscode-base16-term/#/3024

🤞🏻 🍀 🦄 --- GOOD LUCK! --- 🤞🏻 🍀 🦄

EOF
