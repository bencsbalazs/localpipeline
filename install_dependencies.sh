#!/usr/bin/env bash
set -eo pipefail

echo "=== Installing Pipeline Tools ==="

# 1. System dependencies (Docker, curl, etc.) on Ubuntu/Debian basics
echo "Please ensure Docker is installed."

BIN_DIR="$HOME/.local/bin"
mkdir -p $BIN_DIR

# 2. Installing Kind (Kubernetes in Docker)
if ! command -v kind &> /dev/null; then
    echo "Kind installing..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
    chmod +x ./kind
    ./kind version
    mv ./kind $BIN_DIR/kind
fi

# 4. Installing Kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Kubectl installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    ./kubectl version
    mv kubectl $BIN_DIR/kubectl
fi

# 5. Installing Snyk CLI
if ! command -v snyk &> /dev/null; then
    echo "Snyk installing..."
    curl -compressed https://static.snyk.io/cli/latest/snyk-linux -o snyk
    chmod +x snyk
    mv snyk $BIN_DIR/snyk
fi

# 6. Installing Trivy
if ! command -v trivy &> /dev/null; then
    echo "Trivy installing..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b $BIN_DIR v0.50.0
fi

# 7. Installing Gitleaks
if ! command -v gitleaks &> /dev/null; then
    echo "Gitleaks installing..."
    curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh -s -- -b $BIN_DIR
fi

echo "=== Installation Complete! ==="
# echo "If Docker was just installed, it may be necessary to add the current user to the docker group:"
echo "sudo usermod -aG docker \$USER && newgrp docker"
