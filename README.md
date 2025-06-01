# OCI Volume Source Demo for Kubernetes

This project demonstrates the new OCI Volume Source capabilities in Kubernetes, which allows mounting container images directly as read-only volumes in Kubernetes Pods.

## Overview

The OCI Volume Source feature (introduced in Kubernetes 1.31 as alpha, graduated to beta in Kubernetes 1.33) simplifies how applications can access static data resources such as instrumentation agents, ML models, or other data patterns to be shared across your Kubernetes clusters.

This demo specifically showcases using the OCI Volume Source feature to deliver the OpenTelemetry Java agent to a Spring Boot application without embedding it in the application container image.

## Key Components

- **Kind Cluster**: Uses Kind 0.29+ with Kubernetes 1.33 and containerd v2.1.1 that natively supports Image Volumes
- **Local Registry**: A local container registry for storing and retrieving our OCI artifacts
- **OpenTelemetry Java Agent**: Packaged into a single OCI layer and pushed to the registry
- **Spring Boot Demo Applications**: Example applications that mount the OpenTelemetry agent from the OCI image
- **Aspire Dashboard**: Deployed alongside the demo applications for visualizing OpenTelemetry metrics, traces, and logs

## Implementation Details

### Setup Requirements

- Kind 0.29+ is required (includes containerd v2.1.1 with native Image Volume support)
- Feature flags for `ImageVolume` are enabled in the Kubernetes cluster

### Workflow

1. The Kind cluster is started with the required features enabled
2. The OpenTelemetry Java agent is packaged as an OCI artifact and pushed to the local registry
3. The Aspire Dashboard is deployed first to act as the OpenTelemetry collector endpoint
4. Spring Boot applications are deployed with references to the OpenTelemetry agent OCI image
5. The agent is automatically mounted into the containers at runtime
6. Telemetry data is automatically sent to the pre-deployed Aspire dashboard for visualization

## Shell Scripts Guide

This project includes several shell scripts that automate the setup and demonstration of the OCI Volume Source feature. The scripts should be executed in the following order to ensure proper dependency setup:

### Quick Start

To run the complete demo in one command:

```bash
./01-kind-with-registry.sh && \
./01a-kubernetes-dashboard.sh && \
./02-artifact-javaagent-upload.sh && \
./03-deploy-aspire-dashboard.sh && \
./04-deploy-spring-hello-world.sh
```

### Step-by-Step Execution

#### `01-kind-with-registry.sh`

Creates a Kind cluster with a local container registry, using Kubernetes 1.33 with Image Volume support enabled.

```bash
./01-kind-with-registry.sh
```

#### `01a-kubernetes-dashboard.sh` (Optional)

Deploys the Kubernetes Dashboard for better cluster visibility.

```bash
./01a-kubernetes-dashboard.sh
```

#### `02-artifact-javaagent-upload.sh`

Packages the OpenTelemetry Java agent as an OCI artifact and pushes it to the local registry, creating a reproducible OCI image with precise metadata.

```bash
./02-artifact-javaagent-upload.sh
```

#### `03-deploy-aspire-dashboard.sh`

Deploys the Aspire Dashboard for visualizing telemetry data. **This must be deployed before the Spring applications** as it acts as the OpenTelemetry collector endpoint.

```bash
./03-deploy-aspire-dashboard.sh
```

#### `04-deploy-spring-hello-world.sh`

Deploys a simple Spring Boot application with OCI Volume Source-based instrumentation. The application will automatically send telemetry data to the Aspire Dashboard deployed in the previous step.

```bash
./04-deploy-spring-hello-world.sh
```

### Cleanup Script

#### `05-cleanup.sh`

Removes all created resources when you're done with the demo.

```bash
./05-cleanup.sh
```

## Benefits

- Simplified agent distribution without modifying application images
- Consistent instrumentation across all applications
- Easy updates to instrumentation without rebuilding application containers
- Demonstration of a powerful new Kubernetes feature

## References

For more details on OCI Volume Source, see these articles:

- [Kubernetes v1.33: Image Volumes graduate to beta!](https://kubernetes.io/blog/2025/04/29/kubernetes-v1-33-image-volume-beta/) - Official Kubernetes blog post
- [Using OCI Volume Source in Kubernetes Pods](https://sestegra.medium.com/using-oci-volume-source-in-kubernetes-pods-06d62fb72086) - Medium article
