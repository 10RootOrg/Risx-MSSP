#!/bin/bash
# Quick fix script for Velociraptor on air-gapped machine
# Run this on your air-gapped machine: chmod +x fix-velociraptor-airgap.sh && ./fix-velociraptor-airgap.sh

set -e

WORKDIR="/home/tenroot/setup_platform/workdir/velociraptor"

echo "Fixing Velociraptor Dockerfile for air-gapped deployment..."

cd "$WORKDIR"

# Backup current Dockerfile
cp Dockerfile Dockerfile.old

# Create new Dockerfile without rsync dependency
cat > Dockerfile << 'DOCKERFILE_EOF'
FROM ubuntu:22.04

# Define the VELOX_RELEASE https://github.com/Velocidex/velociraptor/releases
ARG VELOCIRAPTOR_VERSION=v0.75

LABEL description="Velociraptor server in a Docker container"
LABEL maintainer="@10RootOrg"
LABEL src.forked_from="https://github.com/weslambert/velociraptor-docker/tree/master"
LABEL version="Velociraptor $VELOCIRAPTOR_VERSION"

COPY ./entrypoint /entrypoint
RUN chmod +x /entrypoint

# Create dirs for Velociraptor binaries
RUN mkdir -p /opt/velociraptor/linux && \
    mkdir -p /opt/velociraptor/mac && \
    mkdir -p /opt/velociraptor/windows

# Check if we're in air-gapped mode by looking for pre-downloaded binaries
# If binaries exist in build context, use them; otherwise fail with clear error
COPY velociraptor_binaries /tmp/velociraptor_binaries

RUN if [ -f "/tmp/velociraptor_binaries/linux/velociraptor" ]; then \
      echo "Using pre-downloaded Velociraptor binaries (air-gapped mode)"; \
      cp /tmp/velociraptor_binaries/linux/velociraptor /opt/velociraptor/linux/velociraptor && \
      cp /tmp/velociraptor_binaries/mac/velociraptor_client /opt/velociraptor/mac/velociraptor_client && \
      cp /tmp/velociraptor_binaries/windows/velociraptor_client.exe /opt/velociraptor/windows/velociraptor_client.exe && \
      cp /tmp/velociraptor_binaries/windows/velociraptor_client.msi /opt/velociraptor/windows/velociraptor_client.msi && \
      chmod +x /opt/velociraptor/linux/velociraptor && \
      rm -rf /tmp/velociraptor_binaries; \
    else \
      echo "ERROR: Velociraptor binaries not found in air-gapped bundle!"; \
      exit 1; \
    fi

# Set working directory
WORKDIR /velociraptor

# Default command
CMD ["/entrypoint"]
DOCKERFILE_EOF

echo "Dockerfile updated successfully!"

# Fix entrypoint - replace rsync with cp and disable cert rotation
echo "Fixing entrypoint script..."
sed -i 's/rsync -a/cp -a/g' entrypoint

# Comment out certificate rotation section
sed -i '/^# Check Server Certificate Status/,/^fi$/c\
# Check Server Certificate Status, Re-generate if it'\''s expiring in 24-hours or less\
# Disabled for air-gapped deployments to avoid jq/openssl dependencies\
# On fresh installs, certificates are valid for years and don'\''t need immediate rotation\
echo "Certificate rotation check skipped (air-gapped mode)"' entrypoint

echo "Entrypoint updated successfully!"
echo ""
echo "Now rebuild and start Velociraptor:"
echo "  cd $WORKDIR"
echo "  docker compose up -d --build"
