#!/usr/bin/env bash
set -euo pipefail

echo "Starting cleanup process..."

# Variables
KIND_REPO="kind"
K8S_TAR="kubernetes-server-linux-amd64.tar.gz"
AGENT_DIR="opentelemetry-javaagent"
SPRING_REDIS_WS_REPO="spring-redis-websocket/git-source"
REGISTRY_NAME="kind-registry"
ARTIFACT_NAME="opentelemetry-javaagent"

# Step 1: Delete any running kind clusters
echo "Deleting kind clusters..."
if command -v kind &> /dev/null; then
  if kind get clusters | grep -q .; then
    kind delete clusters --all
    echo "All kind clusters deleted"
  else
    echo "No kind clusters found"
  fi
else
  echo "kind command not found, skipping cluster deletion"
fi

# Step 2: Remove downloaded files
echo "Removing downloaded files..."

if [ -f "${K8S_TAR}" ]; then
  echo "Removing ${K8S_TAR}..."
  rm -f "${K8S_TAR}"
fi

# Step 3: Clean up opentelemetry-javaagent directory
echo "Cleaning up OpenTelemetry Java Agent directory..."
if [ -d "${AGENT_DIR}" ]; then
  echo "Removing JAR and TAR files from ${AGENT_DIR}..."
  rm -f "${AGENT_DIR}"/*.jar
  rm -f "${AGENT_DIR}"/*.tar
  echo "Preserved Dockerfile in ${AGENT_DIR}"
fi

# Step 4: Remove cloned repositories
echo "Removing cloned repositories..."

if [ -d "${KIND_REPO}" ]; then
  echo "Removing ${KIND_REPO} directory..."
  rm -rf "${KIND_REPO}"
fi

if [ -d "${SPRING_REDIS_WS_REPO}" ]; then
  echo "Removing ${SPRING_REDIS_WS_REPO} directory..."
  rm -rf "${SPRING_REDIS_WS_REPO}"
fi

# Step 5: Remove kind registry container
echo "Removing kind registry container..."
if docker container inspect "${REGISTRY_NAME}" &> /dev/null; then
  echo "Stopping and removing ${REGISTRY_NAME} container..."
  docker container stop "${REGISTRY_NAME}" && docker container rm "${REGISTRY_NAME}"
else
  echo "Registry container ${REGISTRY_NAME} not found"
fi

# Step 6: Clean up related Docker images
echo "Cleaning up related Docker images..."

# Custom kind images
if docker images "kindest/node:latest" | grep -q "kindest/node"; then
  echo "Removing kindest/node image..."
  docker rmi kindest/node:latest || true
fi

# Registry image
if docker images "registry:3" | grep -q "registry"; then
  echo "Removing registry:3 image..."
  docker rmi registry:3 || true
fi

# OCI base image
if docker images "gcr.io/k8s-staging-kind/base:oci-source-demo" | grep -q "gcr.io/k8s-staging-kind/base"; then
  echo "Removing gcr.io/k8s-staging-kind/base:oci-source-demo image..."
  docker rmi gcr.io/k8s-staging-kind/base:oci-source-demo || true
fi

# OpenTelemetry agent OCI image
if docker images "${ARTIFACT_NAME}.oci:v1" | grep -q "${ARTIFACT_NAME}.oci"; then
  echo "Removing ${ARTIFACT_NAME}.oci:v1 image..."
  docker rmi "${ARTIFACT_NAME}.oci:v1" || true
fi

# OpenTelemetry agent image in local registry
if docker images "localhost:5001/opentelemetry-javaagent:v2.15.0" | grep -q "opentelemetry-javaagent"; then
  echo "Removing opentelemetry-javaagent image..."
  docker rmi localhost:5001/opentelemetry-javaagent:v2.15.0 || true
fi

# Spring Redis WebSocket images if they exist
for image in "rawsanj/spring-redis-websocket:3.4.4-jvm" "rawsanj/spring-redis-websocket:3.4.4-native" "redis:6.2-alpine"; do
  if docker images | grep -q "${image}"; then
    echo "Removing ${image} image..."
    docker rmi "${image}" || true
  fi
done

echo "Cleanup completed successfully!"
echo "All downloaded assets, cloned repositories, kind clusters, and related Docker images have been removed."
