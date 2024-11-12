#!/usr/bin/env zsh

echo "Starting dev container entrypoint script..."

cat << EOF > /test.sh
#!/usr/bin/env bash
ping -c 3 lint_array
EOF
chmod 755 /test.sh

cat << EOF >> /root/.zshrc
#
# -- BEGIN
# zsh configurationecho 'deb [trusted=yes] http://ftp.de.debian.org/debian buster main' | tee -a vi /etc/apt/sources.list
plugins=(git gcloud kubectl kubectx kube-ps1)
source /root/.oh-my-zsh/oh-my-zsh.sh
git config --global --add safe.directory '*'
# -- END

EOF

sleep infinity
