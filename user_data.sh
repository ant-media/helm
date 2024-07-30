#!/bin/bash

apt-get update && apt-get install jq curl -y -qq
GITHUB_TOKEN=""
echo $GITHUB_TOKEN > /tmp/token.txt
RUNNER_VERSION="2.317.0"
#RUNNER_ORG="ant-media/helm"
RUNNER_ORG=""
RUNNER_TOKEN=$(curl -s -L -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/$RUNNER_ORG/actions/runners/registration-token | jq -r .token)

# Create dedicated user
useradd -m -d /home/runner -s /bin/bash runner
sudo usermod -aG sudo runner
echo "runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Download and install runner script
cd /home/runner
mkdir -p actions-runner
cd actions-runner
curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

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
