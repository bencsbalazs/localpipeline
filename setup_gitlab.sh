#!/usr/bin/env bash
set -eo pipefail

export PATH=$HOME/.local/bin:$PATH

echo "=== Setting up GitLab in a separate Kubernetes cluster ==="

# Create Kind config for port mapping
cat <<EOF > kind-gitlab-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30022
    hostPort: 30022
    protocol: TCP
EOF

if kind get clusters | grep -q "gitlab-cluster"; then
    echo "GitLab cluster already exists."
else
    echo "Creating new Kind cluster 'gitlab-cluster'..."
    kind create cluster --name gitlab-cluster --config kind-gitlab-config.yaml
fi

echo "Applying GitLab deployment manifest..."
kubectl --context kind-gitlab-cluster apply -f k8s/gitlab.yml

echo "Waiting for GitLab to start (this will take several minutes)..."
kubectl --context kind-gitlab-cluster rollout status deployment/gitlab-deployment --timeout=600s

echo "GitLab is deployed!"
echo "You can access it at: http://localhost:30080"
echo "To get the root password, run:"
echo "kubectl --context kind-gitlab-cluster exec -it \$(kubectl --context kind-gitlab-cluster get pods -l app=gitlab -o jsonpath='{.items[0].metadata.name}') -- grep 'Password:' /etc/gitlab/initial_root_password"
