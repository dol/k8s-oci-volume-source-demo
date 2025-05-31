#!/usr/bin/env bash
set -euo pipefail

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard

helm upgrade --wait --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  --set kong.proxy.type=NodePort \
  --set kong.proxy.tls.nodePort=31000 \
  --create-namespace \
  -n kubernetes-dashboard

# Apply the admin user service account and role binding from the separate YAML file
kubectl apply -f kubernetes-dashboard/dashboard-admin-user.yaml

# Wait for the dashboard to be ready
echo "Waiting for Kubernetes Dashboard to be ready..."
kubectl -n kubernetes-dashboard wait --for=condition=ready pod -l app=kubernetes-dashboard-kong --timeout=120s

# Get the admin token
TOKEN=$(kubectl -n kube-system describe secret admin-user-token | grep '^token:' | awk '{print $2}')
echo
echo "Admin user token:"
echo "-----------------"
echo "${TOKEN}"
echo "-----------------"

# Get the NodePort from the kubernetes-dashboard-kong-proxy service
NODE_PORT=$(kubectl get svc -n kubernetes-dashboard kubernetes-dashboard-kong-proxy -o jsonpath='{.spec.ports[0].nodePort}')

# Get the node IP directly from the pod in a single command
NODE_IP=$(kubectl get pod -n kubernetes-dashboard -l app=kubernetes-dashboard-kong -o jsonpath='{.items[0].status.hostIP}')

echo
echo "Kubernetes Dashboard is available at: https://${NODE_IP}:${NODE_PORT}"
echo "Use the token above to sign in."
