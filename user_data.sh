#!/bin/bash
set -euo pipefail

apt-get update && apt-get install jq curl -y -qq
GITHUB_TOKEN=""
RUNNER_VERSION=$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -er '.tag_name | ltrimstr("v")')
#RUNNER_ORG="ant-media/helm"
RUNNER_ORG=""
RUNNER_TOKEN=$(curl -fsSL -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/$RUNNER_ORG/actions/runners/registration-token | jq -er '.token | select(type == "string" and length > 0)')

# Create dedicated user
useradd -m -d /home/runner -s /bin/bash runner
sudo usermod -aG sudo runner
echo "runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Download and install runner script
cd /home/runner
mkdir -p actions-runner
cd actions-runner
curl -fSL -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
./bin/installdependencies.sh
chown -R runner:runner /home/runner/actions-runner

# Configure runner
su - runner -c "
/home/runner/actions-runner/config.sh --url https://github.com/$RUNNER_ORG --token $RUNNER_TOKEN --unattended
"

# Setup systemd scripts
cd /home/runner/actions-runner/
./svc.sh install runner
./svc.sh start

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update 

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
