#!/usr/bin/env zsh

echo "Starting devcontainer entrypoint script..."

# Install Oh-My-Zsh
echo "Installing Oh-My-Zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

plugins=(git gcloud kubectl kubectx kube-ps1)
source /root/.oh-my-zsh/oh-my-zsh.sh

echo "Enabling safe.directory setting for Git"
git config --global --add safe.directory '*'

# The Kubernetes plugin seems to expect Helm to be in this location
# when apt installs it in /usr/sbin
echo "Creating a symlink for Helm"
mkdir -p /root/.local/state/vs-kubernetes/tools/helm/linux-arm64
ln -s /usr/sbin/helm /root/.local/state/vs-kubernetes/tools/helm/linux-arm64/helm
helm repo update

# Make yamllint stop complaining about long lines
echo "Creating a config for yamllint"
mkdir -p /root/.config/yamllint
cat <<EOF > /root/.config/yamllint/config
extends: default
rules:
  line-length: disable
EOF

# Helm and other environment variables
echo "Creating environment variables in /etc/environment"
cat <<EOF >> /etc/environment
HELM_CONFIG_HOME=/root/.config/helm
HELM_DATA_HOME=/root/.local/share/helm
DOCKER_CONFIG=/root/.docker
YAMLLINT_CONFIG_FILE=/root/.config/yamllint/config
EOF

# Copy the self-signed Netskope certificates from the host
# and install them in the Ubuntu SSL cert store
cert_dir="/workspace/certs"
if [ -d "${cert_dir}" ]; then
  echo "Copying Netskope certificates"
  find "${cert_dir}" \
    -type f \
    -exec sh -c 'base_name=$(basename "$1") && echo "$base_name" && cp "$1" "/usr/local/share/ca-certificates/${base_name}.crt"' _ {} \;
  update-ca-certificates --verbose
  if
fi

#
# Remote server settings
#
# VS Code's "editor.defaultFormatter" is "ms-python.autopep8"
# PyLance is A LOT better, but can be slow to index files when your workspace
# is large -- python.analysis.include is meant to limit the scope of PyLance's
# searching.
#
# More info:  https://github.com/microsoft/pylance-release/wiki/Opening-Large-Workspaces-in-VS-Code
#
# python.x.y.z -- This is used for settings that apply globally to the Python
# extension.
#
# [python] -- This is a "language-specific configuration block", settings within
# this block apply only to files of the specified language (in this case,
# Python). This allows you to customize editor behavior specifically for Python
# files
#
echo "Creating remote machine settings.json for VS Code"
cat <<EOF > /root/.vscode-server/data/Machine/settings.json
{
  "[python]": {
    "editor.defaultFormatter": "ms-python.vscode-pylance"
  },
  "http.experimental.systemCertificatesV2": true,
  "python.analysis.autoFormatStrings": true,
  "python.analysis.autoImportCompletions": true,
  "python.analysis.diagnosticMode": "openFilesOnly",
  "python.analysis.generateWithTypeAnnotation": true,
  "python.analysis.include": [
    "**/database/apps",
    "**/sre/apps",
    "**/sre/cloud-functions",
    "**/sre/observability"
  ],
  "python.defaultInterpreterPath": "/usr/local/bin/python",
  "python.languageServer": "Pylance",
  "vs-kubernetes.disable-crd-fetching": true,
  "vs-kubernetes.helm-path": "/usr/sbin/helm",
  "vs-kubernetes.kubectl-path": "/usr/bin/kubectl"
}
EOF

# this is dumb and we should not have to do this but Docker is suddenly
# complaining about file ownership of things in /root/.ssh
echo "Copying user ssh keys to /root/.ssh"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cp -R /mnt/.ssh  /root
chown -R root:root /root/.ssh
sed -i '/UseKeychain yes/d' /root/.ssh/config

echo "Party time!  🍔  🍩  🌮"
sleep infinity
