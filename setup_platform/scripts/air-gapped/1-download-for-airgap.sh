#!/bin/bash
################################################################################
# Air-Gapped Deployment - Download Script (Run on Online System)
################################################################################
# This script downloads all necessary Docker images, binaries, and files
# required for air-gapped deployment of the Risx-MSSP platform.
#
# Usage: ./1-download-for-airgap.sh
#
# Output: Creates an 'airgap-bundle' directory with all required files
################################################################################

set -eo pipefail

# Source the main library for helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/main.sh"

# Load environment variables
ENV_FILE="${SCRIPT_DIR}/../../resources/default.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    print_red "Error: Cannot find default.env file at $ENV_FILE"
    exit 1
fi

# Create output directory
BUNDLE_DIR="${SCRIPT_DIR}/airgap-bundle"
IMAGES_DIR="${BUNDLE_DIR}/docker-images"
BINARIES_DIR="${BUNDLE_DIR}/binaries"
ARTIFACTS_DIR="${BUNDLE_DIR}/artifacts"
SCRIPTS_DIR="${BUNDLE_DIR}/scripts"

mkdir -p "${IMAGES_DIR}" "${BINARIES_DIR}" "${ARTIFACTS_DIR}" "${SCRIPTS_DIR}"

print_with_border "Starting Air-Gapped Bundle Download"
echo "Bundle directory: ${BUNDLE_DIR}"
echo ""

################################################################################
# Function to pull and save Docker image
################################################################################
pull_and_save_image() {
    local image_full="$1"
    local image_name=$(echo "$image_full" | tr '/:' '_')
    local output_file="${IMAGES_DIR}/${image_name}.tar"

    if [ -f "$output_file" ]; then
        print_yellow "Image already saved: $image_full"
        return 0
    fi

    print_green "Pulling image: $image_full"
    if docker pull "$image_full"; then
        print_green "Saving image: $image_full"
        docker save -o "$output_file" "$image_full"
        print_green_v2 "$image_full" "Downloaded and saved"
    else
        print_red "Failed to pull image: $image_full"
        return 1
    fi
}

################################################################################
# Function to download file with retry
################################################################################
download_file() {
    local url="$1"
    local output="$2"
    local retries=3
    local count=0

    if [ -f "$output" ]; then
        print_yellow "File already exists: $output"
        return 0
    fi

    print_green "Downloading: $url"
    while [ $count -lt $retries ]; do
        if curl -fsSL "$url" -o "$output"; then
            print_green_v2 "$(basename $output)" "Downloaded"
            return 0
        fi
        count=$((count + 1))
        print_yellow "Retry $count/$retries..."
        sleep 2
    done

    print_red "Failed to download: $url"
    return 1
}

################################################################################
# 1. Download Base Docker Images
################################################################################
print_with_border "Downloading Docker Images"

# CyberChef (DISABLED by default - uncomment if needed)
# pull_and_save_image "ghcr.io/gchq/cyberchef:${CYBERCHEF_IMAGE_TAG:-10.19}"

# Elastic Stack
# Note: ELK is built from Dockerfile, but we'll save the base images
pull_and_save_image "docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION:-8.15.3}"
pull_and_save_image "docker.elastic.co/logstash/logstash:${ELASTIC_VERSION:-8.15.3}"
pull_and_save_image "docker.elastic.co/kibana/kibana:${ELASTIC_VERSION:-8.15.3}"

# IRIS
pull_and_save_image "rabbitmq:${IRIS_RABBITMQ_VERSION:-3-management-alpine}"
pull_and_save_image "ghcr.io/dfir-iris/iriswebapp_db:${IRIS_VERSION:-v2.4.20}"
pull_and_save_image "ghcr.io/dfir-iris/iriswebapp_app:${IRIS_VERSION:-v2.4.20}"
pull_and_save_image "ghcr.io/dfir-iris/iriswebapp_nginx:${IRIS_VERSION:-v2.4.20}"

# Nginx
pull_and_save_image "nginx:${NGINX_VERSION:-1.19.3-alpine}"

# Nightingale (DISABLED by default - uncomment if needed)
# pull_and_save_image "ghcr.io/rajanagori/nightingale:${NIGHTINGALE_IMAGE_TAG:-v1.0.0}"

# Prowler (DISABLED by default - uncomment if needed)
# pull_and_save_image "prowlercloud/prowler-api:${PROWLER_API_VERSION:-stable}"
# pull_and_save_image "prowlercloud/prowler-ui:${PROWLER_UI_VERSION:-latest}"
# pull_and_save_image "postgres:${PROWLER_POSTGRES_VERSION:-16.3-alpine3.20}"
# pull_and_save_image "valkey/valkey:${PROWLER_VALKEY_VERSION:-7-alpine3.19}"

# Strelka (DISABLED by default - uncomment if needed)
# pull_and_save_image "target/strelka-frontend:${STRELKA_VERSION:-0.24.07.09}"
# pull_and_save_image "target/strelka-backend:${STRELKA_VERSION:-0.24.07.09}"
# pull_and_save_image "target/strelka-manager:${STRELKA_VERSION:-0.24.07.09}"
# pull_and_save_image "target/strelka-ui:${STRELKA_UI_VERSION:-v2.13}"
# pull_and_save_image "redis:${STRELKA_REDIS_VERSION:-7.4.0-alpine3.20}"
# pull_and_save_image "jaegertracing/all-in-one:${STRELKA_JAEGER_VERSION:-1.42}"
# pull_and_save_image "docker.io/bitnami/postgresql:11"

# Timesketch
pull_and_save_image "postgres:${TIMESKETCH_POSTGRES_VERSION:-13.0-alpine}"
pull_and_save_image "us-docker.pkg.dev/osdfir-registry/timesketch/timesketch:${TIMESKETCH_VERSION:-20250708}"
pull_and_save_image "opensearchproject/opensearch:${TIMESKETCH_OPENSEARCH_VERSION:-2.15.0}"
pull_and_save_image "redis:${TIMESKETCH_REDIS_VERSION:-6.0.8-alpine}"

# MISP (DISABLED by default - uncomment if needed)
# pull_and_save_image "ixdotai/smtp:latest"
# pull_and_save_image "valkey/valkey:7.2"
# pull_and_save_image "mariadb:10.11"
# pull_and_save_image "ghcr.io/misp/misp-docker/misp-core:latest"
# pull_and_save_image "ghcr.io/misp/misp-docker/misp-modules:latest"

# Portainer
pull_and_save_image "portainer/agent:${PORTAINER_AGENT_VERSION:-2.21.0}"
pull_and_save_image "portainer/portainer-ce:${PORTAINER_VERSION:-2.21.0}"

# Base images for custom builds
pull_and_save_image "python:3.10-bookworm"  # risx-mssp backend
pull_and_save_image "node:20-alpine"        # risx-mssp frontend
pull_and_save_image "ubuntu:22.04"          # velociraptor
pull_and_save_image "mysql:latest"          # risx-mssp mysql

################################################################################
# 2. Download Velociraptor Binaries
################################################################################
print_with_border "Downloading Velociraptor Binaries"

VELOCIRAPTOR_VERSION=${VELOCIRAPTOR_VERSION:-v0.74}
VELOX_DIR="${BINARIES_DIR}/velociraptor"
mkdir -p "$VELOX_DIR"/{linux,mac,windows}

# Download release info from GitHub
VELOX_RELEASE_JSON="${VELOX_DIR}/velociraptor_release.json"
download_file "https://api.github.com/repos/velocidex/velociraptor/releases/tags/${VELOCIRAPTOR_VERSION}" "$VELOX_RELEASE_JSON"

# Parse download URLs
if [ -f "$VELOX_RELEASE_JSON" ]; then
    LINUX_BIN=$(jq -r '.assets[] | select(.name | test("linux-amd64$")) | .browser_download_url' "$VELOX_RELEASE_JSON" | sort -V | tail -n 1)
    MAC_BIN=$(jq -r '.assets[] | select(.name | test("darwin-amd64$")) | .browser_download_url' "$VELOX_RELEASE_JSON" | sort -V | tail -n 1)
    WINDOWS_EXE=$(jq -r '.assets[] | select(.name | test("windows-amd64.exe$")) | .browser_download_url' "$VELOX_RELEASE_JSON" | sort -V | tail -n 1)
    WINDOWS_MSI=$(jq -r '.assets[] | select(.name | test("windows-amd64.msi$")) | .browser_download_url' "$VELOX_RELEASE_JSON" | sort -V | tail -n 1)

    download_file "$LINUX_BIN" "${VELOX_DIR}/linux/velociraptor"
    download_file "$MAC_BIN" "${VELOX_DIR}/mac/velociraptor_client"
    download_file "$WINDOWS_EXE" "${VELOX_DIR}/windows/velociraptor_client.exe"
    download_file "$WINDOWS_MSI" "${VELOX_DIR}/windows/velociraptor_client.msi"

    chmod +x "${VELOX_DIR}/linux/velociraptor" || true
fi

################################################################################
# 3. Download External Artifacts
################################################################################
print_with_border "Downloading External Artifacts"

# Velociraptor Artifacts
VELOCIRAPTOR_ARTIFACTS_URL="${VELOCIRAPTOR_ARTIFACTS_URL:-https://github.com/10RootOrg/Velociraptor-Artifacts/archive/refs/heads/main.zip}"
download_file "$VELOCIRAPTOR_ARTIFACTS_URL" "${ARTIFACTS_DIR}/velociraptor-artifacts.zip"

# YARA Rules for Strelka
GITHUB_COMMIT_YARAHQ=${GITHUB_COMMIT_YARAHQ:-"20240922"}
YARA_URL="https://github.com/YARAHQ/yara-forge/releases/download/${GITHUB_COMMIT_YARAHQ}/yara-forge-rules-full.zip"
download_file "$YARA_URL" "${ARTIFACTS_DIR}/yara-forge-rules-full.zip"

################################################################################
# 4. Download RISX-MSSP Source Repositories
################################################################################
print_with_border "Downloading RISX-MSSP Source Repositories"

# These repositories are cloned by risx-mssp.sh during deployment
# We need to download them for air-gapped systems

REPOS_DIR="${ARTIFACTS_DIR}/risx-mssp-repos"
mkdir -p "$REPOS_DIR"

# Download risx-mssp-back
print_green "Cloning risx-mssp-back repository..."
if [ ! -d "${REPOS_DIR}/risx-mssp-back" ]; then
    git clone --branch "${GIT_RISX_BACKEND_BRANCH:-main}" \
        "https://github.com/10RootOrg/risx-mssp-back" \
        "${REPOS_DIR}/risx-mssp-back" || print_red "Failed to clone risx-mssp-back"
fi

# Download risx-mssp-front
print_green "Cloning risx-mssp-front repository..."
if [ ! -d "${REPOS_DIR}/risx-mssp-front" ]; then
    git clone --branch "${GIT_RISX_FRONTEND_BRANCH:-main}" \
        "https://github.com/10RootOrg/risx-mssp-front" \
        "${REPOS_DIR}/risx-mssp-front" || print_red "Failed to clone risx-mssp-front"
fi

# Download risx-mssp-python
print_green "Cloning risx-mssp-python repository..."
if [ ! -d "${REPOS_DIR}/risx-mssp-python" ]; then
    git clone --branch "${GIT_RISX_PY_BRANCH:-main}" \
        "https://github.com/10RootOrg/risx-mssp-python.git" \
        "${REPOS_DIR}/risx-mssp-python" || print_red "Failed to clone risx-mssp-python"
fi

# Create archives of the repositories (without .git to save space)
print_green "Creating repository archives..."
cd "${REPOS_DIR}"
for repo in risx-mssp-back risx-mssp-front risx-mssp-python; do
    if [ -d "$repo" ]; then
        print_green "Archiving $repo..."
        tar -czf "${repo}.tar.gz" --exclude='.git' "$repo"
        print_green_v2 "$repo.tar.gz" "Created"
    fi
done
cd - > /dev/null

################################################################################
# 5. Download System Binaries and Tools
################################################################################
print_with_border "Downloading System Binaries"

# Docker installation script
download_file "https://get.docker.com" "${BINARIES_DIR}/get-docker.sh"
chmod +x "${BINARIES_DIR}/get-docker.sh" || true

# Docker Compose
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-"2.29.7"}
ARCH=$(uname -m)
OS=$(uname -s)
COMPOSE_URL="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-${OS}-${ARCH}"
download_file "$COMPOSE_URL" "${BINARIES_DIR}/docker-compose"
chmod +x "${BINARIES_DIR}/docker-compose" || true

# Download jq binary (for systems that don't have it)
JQ_VERSION="1.7.1"
download_file "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" "${BINARIES_DIR}/jq"
chmod +x "${BINARIES_DIR}/jq" || true

################################################################################
# 6. Download APT packages for offline installation
################################################################################
print_with_border "Downloading APT Packages"

# Create a directory for debian packages
DEB_DIR="${BINARIES_DIR}/deb-packages"
mkdir -p "$DEB_DIR"

# Download packages and their dependencies
print_yellow "Downloading packages with apt-get..."
print_yellow "Note: This requires sudo and creates a local APT cache"

# Create a temporary directory for apt cache
APT_CACHE_DIR="${DEB_DIR}/apt-cache"
mkdir -p "$APT_CACHE_DIR/archives/partial"

# Download packages without installing
for pkg in curl rsync unzip jq git p7zip-full sudo ca-certificates gnupg; do
    print_green "Downloading package: $pkg"
    apt-get download "$pkg" 2>/dev/null || {
        print_yellow "Could not download $pkg via apt-get download, trying apt-cache"
        # Alternative: use apt-cache to find dependencies
        apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts \
            --no-breaks --no-replaces --no-enhances "$pkg" 2>/dev/null | \
            grep "^\w" | sort -u | xargs apt-get download 2>/dev/null || true
    }
done 2>/dev/null || print_yellow "Some packages could not be downloaded. They may need to be obtained manually."

# Move all downloaded .deb files to the deb directory
mv *.deb "$DEB_DIR/" 2>/dev/null || true

################################################################################
# 7. Create manifest and instructions
################################################################################
print_with_border "Creating Manifest and Instructions"

# Create manifest file
MANIFEST="${BUNDLE_DIR}/MANIFEST.txt"
cat > "$MANIFEST" << 'EOF'
================================================================================
RISX-MSSP Air-Gapped Deployment Bundle
================================================================================

This bundle contains all required files for air-gapped deployment.

Directory Structure:
--------------------
airgap-bundle/
├── docker-images/      # All Docker images as .tar files
├── binaries/           # System binaries and tools
│   ├── velociraptor/   # Velociraptor binaries for all platforms
│   ├── deb-packages/   # Debian packages for offline installation
│   ├── docker-compose  # Docker Compose binary
│   ├── jq              # JSON processor
│   └── get-docker.sh   # Docker installation script
├── artifacts/          # External artifacts and rules
│   ├── velociraptor-artifacts.zip
│   └── yara-forge-rules-full.zip
└── scripts/            # Modified deployment scripts

Files Included:
---------------
EOF

# Add Docker images to manifest
echo "" >> "$MANIFEST"
echo "Docker Images:" >> "$MANIFEST"
ls -lh "${IMAGES_DIR}"/*.tar | awk '{print "  " $9 " (" $5 ")"}' >> "$MANIFEST" || echo "  (No images found)" >> "$MANIFEST"

# Add binaries to manifest
echo "" >> "$MANIFEST"
echo "Binaries:" >> "$MANIFEST"
find "${BINARIES_DIR}" -type f -not -path "*/deb-packages/*" | sed 's|'"${BINARIES_DIR}"'/|  |' >> "$MANIFEST"

# Add artifacts to manifest
echo "" >> "$MANIFEST"
echo "Artifacts:" >> "$MANIFEST"
ls -lh "${ARTIFACTS_DIR}" | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}' >> "$MANIFEST"

# Create version info file
VERSION_FILE="${BUNDLE_DIR}/VERSION.txt"
cat > "$VERSION_FILE" << EOF
Bundle Creation Date: $(date)
System: $(uname -a)
Docker Version: $(docker --version)

Component Versions:
-------------------
VELOCIRAPTOR_VERSION=${VELOCIRAPTOR_VERSION}
ELASTIC_VERSION=${ELASTIC_VERSION}
IRIS_VERSION=${IRIS_VERSION}
TIMESKETCH_VERSION=${TIMESKETCH_VERSION}
NGINX_VERSION=${NGINX_VERSION}
PORTAINER_VERSION=${PORTAINER_VERSION}
NIGHTINGALE_IMAGE_TAG=${NIGHTINGALE_IMAGE_TAG}
STRELKA_VERSION=${STRELKA_VERSION}
PROWLER_API_VERSION=${PROWLER_API_VERSION}
CYBERCHEF_IMAGE_TAG=${CYBERCHEF_IMAGE_TAG}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION}
EOF

# Create README
README="${BUNDLE_DIR}/README.md"
cat > "$README" << 'EOF'
# RISX-MSSP Air-Gapped Deployment Bundle

## Transfer Instructions

1. **Create Archive**
   ```bash
   cd airgap-bundle/..
   tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/
   ```

2. **Transfer to Air-Gapped System**
   - Copy `risx-mssp-airgap-bundle.tar.gz` to the air-gapped system using approved media
   - Verify checksum after transfer

3. **Extract on Air-Gapped System**
   ```bash
   tar -xzf risx-mssp-airgap-bundle.tar.gz
   cd airgap-bundle
   ```

4. **Run Installation Script**
   ```bash
   chmod +x 2-load-airgap-bundle.sh
   sudo ./2-load-airgap-bundle.sh
   ```

## Bundle Contents

See `MANIFEST.txt` for complete list of included files.
See `VERSION.txt` for component versions.

## Notes

- This bundle is specific to the system architecture it was created on
- Ensure the air-gapped system has the same architecture (x86_64/amd64)
- Minimum disk space required: ~50GB (varies based on images)
- The installation script must be run with sudo privileges

## Support

For issues or questions, refer to the main RISX-MSSP documentation.
EOF

################################################################################
# 8. Calculate checksums
################################################################################
print_with_border "Calculating Checksums"

CHECKSUM_FILE="${BUNDLE_DIR}/SHA256SUMS.txt"
cd "${BUNDLE_DIR}"
find . -type f -not -name "SHA256SUMS.txt" -exec sha256sum {} \; > "$CHECKSUM_FILE"
cd - > /dev/null

################################################################################
# 9. Summary
################################################################################
print_with_border "Download Complete"

BUNDLE_SIZE=$(du -sh "${BUNDLE_DIR}" | cut -f1)
IMAGE_COUNT=$(ls -1 "${IMAGES_DIR}"/*.tar 2>/dev/null | wc -l)

cat << EOF

Summary:
--------
Bundle Directory: ${BUNDLE_DIR}
Total Size: ${BUNDLE_SIZE}
Docker Images: ${IMAGE_COUNT}

Next Steps:
-----------
1. Review the manifest: cat ${BUNDLE_DIR}/MANIFEST.txt
2. Create archive: tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/
3. Transfer to air-gapped system
4. Run the load script: sudo ./2-load-airgap-bundle.sh

Files created:
--------------
- ${MANIFEST}
- ${VERSION_FILE}
- ${README}
- ${CHECKSUM_FILE}

EOF

print_green "Air-gapped bundle download completed successfully!"
print_yellow "Archive the 'airgap-bundle' directory and transfer to your air-gapped system."
