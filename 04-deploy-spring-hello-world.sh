#!/usr/bin/env bash
set -euo pipefail

# Constants
NAMESPACE="spring-hello-world"

echo "Deploying Spring Hello World application..."

# Create namespace if it doesn't exist, or delete and recreate it
if kubectl get namespace "${NAMESPACE}" > /dev/null 2>&1; then
  echo "Deleting existing namespace ${NAMESPACE}..."
  kubectl delete namespace "${NAMESPACE}" --wait=true
fi

echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace "${NAMESPACE}"

echo "Applying Kubernetes resources with kustomize..."
kubectl apply -k "spring-hello-world"

echo "Waiting for Spring Hello World deployment to be ready..."
kubectl wait --for=condition=ready --timeout=120s pod -l app=spring-hello-world -n ${NAMESPACE}

# Get the NodePort for Spring Hello World
SPRING_NODE_PORT=$(kubectl get svc spring-hello-world-service -n ${NAMESPACE} -o=jsonpath='{.spec.ports[0].nodePort}')

# Get the node IP from the Spring Hello World pod
NODE_IP=$(kubectl get pod -l app=spring-hello-world -n ${NAMESPACE} -o jsonpath='{.items[0].status.hostIP}')

echo
echo "Deployment completed successfully!"
echo "----------------------------------------"
echo "Spring Hello World application is accessible at: http://${NODE_IP}:${SPRING_NODE_PORT}"
echo
echo "You can check the deployment status with: kubectl get pods -l app=spring-hello-world -n ${NAMESPACE}"
echo
echo "Note: To deploy the Aspire Dashboard for telemetry visualization, run: ./04a-deploy-aspire-dashboard.sh"
