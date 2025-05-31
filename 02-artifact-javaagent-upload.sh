#!/usr/bin/env bash
set -euo pipefail

# Create a temporary directory for the OCI image
TMP_DIR="$(mktemp -d)"

# Constants
GITHUB_REPO="open-telemetry/opentelemetry-java-instrumentation"
AGENT_VERSION="v2.16.0"
AGENT_URL="https://github.com/${GITHUB_REPO}/releases/download/${AGENT_VERSION}/opentelemetry-javaagent.jar"
AGENT_JAR_FILE="opentelemetry-javaagent.jar"
AGENT_DIR="${TMP_DIR}/opentelemetry-javaagent"
AGENT_FILE="${AGENT_DIR}/${AGENT_JAR_FILE}"
AGENT_FILE_DOWNLOAD_HEADERS="${AGENT_DIR}/${AGENT_JAR_FILE}.curl.headers"
REGISTRY="localhost:5001"
ARTIFACT_NAME="opentelemetry-javaagent"

echo "Step 1: Downloading OpenTelemetry Java Agent..."
# Create agent directory if it doesn't exist
mkdir -p "${AGENT_DIR}"

curl -L \
  --dump-header "${AGENT_FILE_DOWNLOAD_HEADERS}" \
  --output "${AGENT_FILE}" \
  "${AGENT_URL}"

# Extract the Last-Modified date from headers
AGENT_PUBLISH_DATE="$(grep -i '^last-modified:' "${AGENT_FILE_DOWNLOAD_HEADERS}" | sed -E 's/^Last-Modified:[[:space:]]*//I')"

# Convert the HTTP date format to format accepted by touch
# HTTP date format: Wed, 12 Apr 2023 15:33:42 GMT
# touch format needs: "YYYYMMDDhhmm.ss"
if TOUCH_DATE=$(date -d "${AGENT_PUBLISH_DATE}" "+%Y%m%d%H%M.%S" 2>/dev/null) && [ -n "$TOUCH_DATE" ]; then
  # Set the file's modification time to match the server's Last-Modified time
  touch -t "${TOUCH_DATE}" "${AGENT_FILE}"
  echo "Set file timestamp to match server's Last-Modified: ${AGENT_PUBLISH_DATE}"
else
  echo "Warning: Could not convert date format for touch command"
fi

echo "Step 2: Creating OCI image from Dockerfile..."

TAR_LAYER_PATH="${TMP_DIR}/layer.tar"
# Create a tar layer from the agent directory and make it reproducible
# https://www.gnu.org/software/tar/manual/html_section/Reproducibility.html
tar c -f "${TAR_LAYER_PATH}" \
  -C "${AGENT_DIR}" \
  --sort=name \
  --format=posix \
  --pax-option=exthdr.name=%d/PaxHeaders/%f \
  --pax-option=delete=atime,delete=ctime \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --mode=0444 \
  --clamp-mtime --mtime=0 \
  "${AGENT_JAR_FILE}"

# Calculate layer diff
TAR_LAYER_DIFF="$(sha256sum "${TAR_LAYER_PATH}" | head -c 64)"

# Compress layer and make it reproducible
# https://www.gnu.org/software/tar/manual/html_section/Reproducibility.html
gzip --best --no-name "${TAR_LAYER_PATH}"

# Create config
CONFIG_PATH="${TMP_DIR}/config.json"
printf '{"architecture":"amd64","os":"linux","rootfs":{"type":"layers","diff_ids":["sha256:%s"]}}' "${TAR_LAYER_DIFF}" > "${CONFIG_PATH}"

# Create layout
LAYOUT_REF="${TMP_DIR}/layout:latest"


IMAGE_CREATED_DATE=$(date -d "${AGENT_PUBLISH_DATE}" --rfc-3339=seconds 2>/dev/null | sed 's/ /T/' || date --rfc-3339=seconds | sed 's/ /T/')

(cd "${TMP_DIR}"; oras push --disable-path-validation \
  --config "${CONFIG_PATH}:application/vnd.oci.image.config.v1+json" \
  --oci-layout "${LAYOUT_REF}" \
  --annotation "org.opencontainers.image.created=${IMAGE_CREATED_DATE}" \
  "layer.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip")

# Push image
echo "Step 3: Uploading OCI image to registry..."
oras cp --from-oci-layout "${LAYOUT_REF}" "${REGISTRY}/${ARTIFACT_NAME}:${AGENT_VERSION}"

echo "Successfully uploaded ${AGENT_FILE} to ${REGISTRY}/${ARTIFACT_NAME}:${AGENT_VERSION}"

# Clean up the temporary directory
rm -rf "${TMP_DIR}"

echo "Done!"
