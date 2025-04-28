#!/usr/bin/env bash
set -euo pipefail

# Constants
NAMESPACE="aspire-dashboard"

echo "Deploying Aspire Dashboard..."

echo "Applying Aspire Dashboard resources with kustomize..."
kubectl apply -k "aspire-dashboard"

echo "Waiting for Aspire Dashboard deployment to be ready..."
kubectl wait --for=condition=ready --timeout=120s pod -l app=aspire-dashboard -n ${NAMESPACE}

# Get the NodePort for Aspire Dashboard
ASPIRE_NODE_PORT=$(kubectl get svc aspire-dashboard-ui -n ${NAMESPACE} -o=jsonpath='{.spec.ports[0].nodePort}')

# Get node IP specifically from the Aspire dashboard pod
ASPIRE_NODE_IP=$(kubectl get pod -l app=aspire-dashboard -n ${NAMESPACE} -o jsonpath='{.items[0].status.hostIP}')

echo
echo "Aspire Dashboard deployment completed successfully!"
echo "----------------------------------------"
echo "Aspire Dashboard is accessible at: http://${ASPIRE_NODE_IP}:${ASPIRE_NODE_PORT}"
echo
echo "You can check the dashboard status with: kubectl get pods -l app=aspire-dashboard -n ${NAMESPACE}"
