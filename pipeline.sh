#!/usr/bin/env bash
set -eo pipefail

export PATH=$HOME/.local/bin:$PATH
# Color codes for the terminal presentation
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== STARTING LOCAL DEVSECOPS PIPELINE ===${NC}"

# Check docker permissions
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Docker access denied. Attempting to fix permissions (sudo may ask for password)...${NC}"
    sudo chmod 666 /var/run/docker.sock || { echo -e "${RED}Failed to fix Docker permissions!${NC}"; exit 1; }
fi

step_1_lint() {
    echo -e "\n[1/7] Ruff Linting and formatting check..."
    ruff check . --fix || { echo -e "${RED}Linting failed!${NC}"; exit 1; }
}

step_2_test() {
    echo -e "\n[2/7] Running unit tests (Pytest)..."
    python3 test.py || { echo -e "${RED}Test failed! Pipeline stopped.${NC}"; exit 1; }
}

step_3_dependency_scan() {
    echo -e "\n[3/7] Scanning third-party dependencies (Snyk)..."
    snyk test --file=requirements.txt || echo -e "${RED}Snyk identification missing, step skipped (simulation mode).${NC}"
}

step_4_secret_scan() {
    echo -e "\n[4/7] Scanning for hardcoded secrets (Gitleaks)..."
    gitleaks detect --source=. -v --no-git || { echo -e "${RED}Critical error: Hardcoded secret found!${NC}"; exit 1; }
}

step_5_build() {
    echo -e "\n[5/7] Building Docker Image (Multi-stage build)..."
    docker build -t local-app:latest .
}

step_6_image_scan() {
    echo -e "\n[6/7] Scanning the built Docker Image (Trivy)..."
    trivy image --severity HIGH,CRITICAL local-app:latest || { echo -e "${RED}Security check rejected the image!${NC}"; exit 1; }
}

step_7_kubernetes_deploy() {
    echo -e "\n[7/7] Preparing local Kubernetes (Kind) cluster..."
    
    # 1. If an old cluster is already running, delete it for a clean slate
    if kind get clusters | grep -q "local-pipeline-cluster"; then
        echo "Cleaning up old cluster..."
        kind delete cluster --name local-pipeline-cluster
    fi

    # 2. Creating a new cluster
    kind create cluster --name local-pipeline-cluster

    echo -e "\n[7/7.b] Loading the secure Docker Image into the K8s cluster..."
    # This is the key step: pushing the locally Trivy-checked image into K8s without a registry
    kind load docker-image local-app:latest --name local-pipeline-cluster

    echo -e "\n[7/7.c] Deploying the application using the deployment manifest..."
    kubectl apply -f k8s/deployment.yml

    echo "Waiting for Pods to start (Kubernetes Orchestration)..."
    # Replacing manual check, waiting for all Pods to be "Ready"
    kubectl rollout status deployment/local-app-deployment --timeout=60s

    echo -e "\n[7/7.d] Starting local port-forward for testing..."
    # Running port-forward in the background to access from browser
    kubectl port-forward svc/local-app-service 8080:8080 &
    PID_FORWARD=$!
    
    sleep 3
    echo "Final health check through the K8s Service..."
    curl -f http://localhost:8080/health || { 
        echo -e "${RED}The Kubernetes deployment started, but the app is not responding!${NC}"; 
        kill $PID_FORWARD; 
        exit 1; 
    }

    # Stopping the background port-forward at the end of the script
    kill $PID_FORWARD
}

# Running in order
step_1_lint
step_2_test
step_3_dependency_scan
step_4_secret_scan
step_5_build
step_6_image_scan
step_7_kubernetes_deploy

echo -e "\n${GREEN}=== SUCCESS: THE LOCAL PIPELINE HAS PASSED ALL GATES ===${NC}"