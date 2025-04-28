#!/usr/bin/env bash
set -euo pipefail

# Working directory
WORKDIR=$(pwd)
KIND_REPO="kind"
K8S_TAR="kubernetes-server-linux-amd64.tar.gz"
K8S_VERSION="v1.33.0"
CONTAINERD_VERSION="v2.1.0"
TAG="oci-source-demo"

echo "Building custom kind base image with containerd ${CONTAINERD_VERSION} and Kubernetes ${K8S_VERSION}..."

# Step 1: Verify if kind repo is already cloned, if not clone it
if [ ! -d "${KIND_REPO}" ]; then
  echo "Cloning kind repository..."
  git clone https://github.com/kubernetes-sigs/kind.git
  cd "${KIND_REPO}"
  git checkout v0.27.0
else
  echo "Kind repository already exists, checking out v0.27.0..."
  cd "${KIND_REPO}"
  git fetch --all --tags
  git checkout v0.27.0
fi

# Step 2: Build the base image with custom containerd version
echo "Building custom base image with containerd ${CONTAINERD_VERSION}..."
cd images/base
make quick EXTRA_BUILD_OPT="--build-arg CONTAINERD_VERSION=${CONTAINERD_VERSION}" TAG=${TAG}

# Return to the working directory
cd "${WORKDIR}"

# Step 3: Check if kubernetes tarball exists, if not download it
if [ ! -f "${K8S_TAR}" ]; then
  echo "Downloading Kubernetes server tarball..."
  curl -L "https://dl.k8s.io/${K8S_VERSION}/${K8S_TAR}" -o "${K8S_TAR}"
else
  echo "Kubernetes server tarball already exists"
fi

# Step 4: Build the node image using the custom base image
echo "Building node image using custom base image..."
kind build node-image ./${K8S_TAR} --type file --base-image gcr.io/k8s-staging-kind/base:${TAG}

echo "Custom kind node image build completed successfully!"
echo "You can now create a cluster using this image with:"
echo "kind create cluster --image kindest/node:latest"
