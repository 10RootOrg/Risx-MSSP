#!/bin/bash
################################################################################
# Air-Gapped Deployment - Load Script (Run on Air-Gapped System)
################################################################################
# This script loads all Docker images, installs binaries, and prepares
# the air-gapped system for RISX-MSSP deployment.
#
# Usage: sudo ./2-load-airgap-bundle.sh
#
# Prerequisites: This script must be run from within the airgap-bundle directory
################################################################################

set -eo pipefail

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_green() {
    printf "${GREEN}%s${NC}\n" "$1"
}

print_red() {
    printf "${RED}%s${NC}\n" "$1"
}

print_yellow() {
    printf "${YELLOW}%s${NC}\n" "$1"
}

print_with_border() {
    local input_string="$1"
    local length=${#input_string}
    local border="===================== "
    local border_length=$(((80 - length - ${#border}) / 2))
    printf "%s" "$border"
    for ((i = 0; i < border_length; i++)); do
        printf "="
    done
    printf " %s " "$input_string"
    for ((i = 0; i < border_length; i++)); do
        printf "="
    done
    printf "%s\n" "$border"
}

# Determine bundle directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="$(dirname "$SCRIPT_DIR")"

# Check if we're in the right directory
if [ ! -d "${BUNDLE_DIR}/docker-images" ] || [ ! -d "${BUNDLE_DIR}/binaries" ]; then
    print_red "Error: Cannot find docker-images or binaries directory"
    print_red "Please run this script from within the airgap-bundle directory"
    print_red "Current directory: $(pwd)"
    print_red "Expected structure: airgap-bundle/{docker-images,binaries,artifacts}"
    exit 1
fi

IMAGES_DIR="${BUNDLE_DIR}/docker-images"
BINARIES_DIR="${BUNDLE_DIR}/binaries"
ARTIFACTS_DIR="${BUNDLE_DIR}/artifacts"

print_with_border "Starting Air-Gapped Bundle Installation"
echo "Bundle directory: ${BUNDLE_DIR}"
echo ""

################################################################################
# 1. Verify Checksums
################################################################################
print_with_border "Verifying Checksums"

if [ -f "${BUNDLE_DIR}/SHA256SUMS.txt" ]; then
    cd "${BUNDLE_DIR}"
    if sha256sum -c SHA256SUMS.txt 2>/dev/null | grep -q "FAILED"; then
        print_red "Checksum verification failed!"
        print_yellow "Some files may be corrupted. Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_green "Checksum verification passed"
    fi
    cd - > /dev/null
else
    print_yellow "No checksum file found, skipping verification"
fi

################################################################################
# 2. Install System Dependencies
################################################################################
print_with_border "Installing System Dependencies"

# Install .deb packages if available
DEB_DIR="${BINARIES_DIR}/deb-packages"
if [ -d "$DEB_DIR" ] && [ "$(ls -A $DEB_DIR/*.deb 2>/dev/null)" ]; then
    print_green "Installing Debian packages from bundle..."
    dpkg -i "${DEB_DIR}"/*.deb 2>/dev/null || {
        print_yellow "Some packages failed to install, attempting to fix dependencies..."
        apt-get install -f -y --no-download 2>/dev/null || print_yellow "Could not auto-fix dependencies"
    }
else
    print_yellow "No Debian packages found in bundle"
fi

# Install binaries
print_green "Installing binaries..."

# Install jq
if [ -f "${BINARIES_DIR}/jq" ]; then
    install -m 755 "${BINARIES_DIR}/jq" /usr/local/bin/jq
    print_green "jq installed to /usr/local/bin/jq"
fi

# Install docker-compose
if [ -f "${BINARIES_DIR}/docker-compose" ]; then
    install -m 755 "${BINARIES_DIR}/docker-compose" /usr/local/bin/docker-compose
    mkdir -p /usr/local/lib/docker/cli-plugins
    ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
    print_green "docker-compose installed to /usr/local/bin/docker-compose"
fi

################################################################################
# 3. Install Docker
################################################################################
print_with_border "Installing Docker"

if command -v docker &> /dev/null; then
    print_yellow "Docker is already installed: $(docker --version)"
    print_yellow "Skip Docker installation? (Y/n)"
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        INSTALL_DOCKER=true
    else
        INSTALL_DOCKER=false
    fi
else
    INSTALL_DOCKER=true
fi

if [ "$INSTALL_DOCKER" = true ]; then
    if [ -f "${BINARIES_DIR}/get-docker.sh" ]; then
        print_green "Installing Docker from bundle..."
        print_yellow "Note: This installation script expects to download packages"
        print_yellow "For true air-gapped install, Docker should be pre-installed or packages included"
        sh "${BINARIES_DIR}/get-docker.sh" || print_red "Docker installation failed"
    else
        print_red "Docker installation script not found in bundle"
        print_yellow "Please install Docker manually before continuing"
        exit 1
    fi
fi

# Start Docker service
systemctl start docker || service docker start || print_yellow "Could not start Docker service"
systemctl enable docker || true

# Verify Docker is running
if ! docker info > /dev/null 2>&1; then
    print_red "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_green "Docker is running: $(docker --version)"

################################################################################
# 4. Create Docker Network
################################################################################
print_with_border "Creating Docker Network"

NETWORK_NAME="main_network"
if docker network ls | grep -q "$NETWORK_NAME"; then
    print_yellow "Docker network '$NETWORK_NAME' already exists"
else
    docker network create "$NETWORK_NAME"
    print_green "Docker network '$NETWORK_NAME' created"
fi

################################################################################
# 5. Load Docker Images
################################################################################
print_with_border "Loading Docker Images"

IMAGE_COUNT=0
FAILED_COUNT=0

if [ -d "$IMAGES_DIR" ]; then
    for image_tar in "${IMAGES_DIR}"/*.tar; do
        if [ -f "$image_tar" ]; then
            print_green "Loading: $(basename $image_tar)"
            if docker load -i "$image_tar"; then
                IMAGE_COUNT=$((IMAGE_COUNT + 1))
            else
                print_red "Failed to load: $image_tar"
                FAILED_COUNT=$((FAILED_COUNT + 1))
            fi
        fi
    done
else
    print_red "Docker images directory not found: $IMAGES_DIR"
    exit 1
fi

print_green "Loaded $IMAGE_COUNT images successfully"
if [ $FAILED_COUNT -gt 0 ]; then
    print_yellow "Failed to load $FAILED_COUNT images"
fi

################################################################################
# 6. Extract and Prepare Artifacts
################################################################################
print_with_border "Preparing Artifacts"

# Create artifacts directory in setup_platform
SETUP_ARTIFACTS_DIR="/opt/risx-mssp-artifacts"
mkdir -p "$SETUP_ARTIFACTS_DIR"

# Copy Velociraptor binaries
if [ -d "${BINARIES_DIR}/velociraptor" ]; then
    print_green "Copying Velociraptor binaries..."
    cp -r "${BINARIES_DIR}/velociraptor" "$SETUP_ARTIFACTS_DIR/"
    print_green "Velociraptor binaries copied to $SETUP_ARTIFACTS_DIR/velociraptor"
fi

# Copy artifact zips
if [ -d "$ARTIFACTS_DIR" ]; then
    print_green "Copying artifacts..."
    cp -r "$ARTIFACTS_DIR"/* "$SETUP_ARTIFACTS_DIR/"
    print_green "Artifacts copied to $SETUP_ARTIFACTS_DIR"
fi

# Set permissions
chmod -R 755 "$SETUP_ARTIFACTS_DIR"

################################################################################
# 7. Create Air-Gapped Configuration
################################################################################
print_with_border "Creating Air-Gapped Configuration"

# Create air-gapped mode flag file
AIRGAP_FLAG="/etc/risx-mssp-airgap"
cat > "$AIRGAP_FLAG" << EOF
# RISX-MSSP Air-Gapped Mode Configuration
# This file indicates the system is running in air-gapped mode
# Created: $(date)

AIRGAP_MODE=true
ARTIFACTS_DIR=$SETUP_ARTIFACTS_DIR
VELOCIRAPTOR_BINARIES_DIR=$SETUP_ARTIFACTS_DIR/velociraptor
VELOCIRAPTOR_ARTIFACTS_ZIP=$SETUP_ARTIFACTS_DIR/velociraptor-artifacts.zip
YARA_RULES_ZIP=$SETUP_ARTIFACTS_DIR/yara-forge-rules-full.zip
EOF

print_green "Air-gapped configuration created at $AIRGAP_FLAG"

################################################################################
# 8. Display loaded images
################################################################################
print_with_border "Verifying Loaded Images"

print_yellow "Loaded Docker images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -20

################################################################################
# 9. Create deployment helper script
################################################################################
print_with_border "Creating Deployment Helper"

HELPER_SCRIPT="/usr/local/bin/risx-mssp-airgap-deploy"
cat > "$HELPER_SCRIPT" << 'EOF'
#!/bin/bash
# RISX-MSSP Air-Gapped Deployment Helper

set -eo pipefail

# Load air-gapped configuration
if [ -f /etc/risx-mssp-airgap ]; then
    source /etc/risx-mssp-airgap
else
    echo "Error: Air-gapped configuration not found"
    exit 1
fi

# Set environment variables for air-gapped mode
export AIRGAP_MODE=true
export AIRGAP_ARTIFACTS_DIR="$ARTIFACTS_DIR"
export AIRGAP_VELOCIRAPTOR_BINARIES="$VELOCIRAPTOR_BINARIES_DIR"
export AIRGAP_VELOCIRAPTOR_ARTIFACTS="$VELOCIRAPTOR_ARTIFACTS_ZIP"
export AIRGAP_YARA_RULES="$YARA_RULES_ZIP"

echo "Air-gapped mode enabled"
echo "Artifacts directory: $ARTIFACTS_DIR"
echo ""
echo "To deploy RISX-MSSP platform, run:"
echo "  cd /path/to/Risx-MSSP/setup_platform/scripts"
echo "  sudo ./endtoend.sh"
echo ""
echo "The deployment scripts will automatically detect air-gapped mode"
echo "and use local artifacts instead of downloading from the internet."
EOF

chmod +x "$HELPER_SCRIPT"
print_green "Helper script created at $HELPER_SCRIPT"

################################################################################
# 10. Summary
################################################################################
print_with_border "Installation Complete"

cat << EOF

Summary:
--------
Docker Images Loaded: $IMAGE_COUNT
Docker Network: $NETWORK_NAME (created)
Artifacts Location: $SETUP_ARTIFACTS_DIR
Air-Gapped Config: $AIRGAP_FLAG

Installed Binaries:
-------------------
- jq: $(which jq 2>/dev/null || echo "not found")
- docker: $(which docker 2>/dev/null || echo "not found")
- docker-compose: $(which docker-compose 2>/dev/null || echo "not found")
- rsync: $(which rsync 2>/dev/null || echo "not found")

Next Steps:
-----------
1. Copy or clone the RISX-MSSP repository to this system
2. Navigate to setup_platform/scripts directory
3. Run the deployment:
   cd /path/to/Risx-MSSP/setup_platform/scripts
   sudo ./endtoend.sh

The deployment will automatically detect air-gapped mode and use local resources.

Helper Commands:
----------------
- Check air-gapped config: cat /etc/risx-mssp-airgap
- List loaded images: docker images
- View artifacts: ls -la $SETUP_ARTIFACTS_DIR

EOF

print_green "Air-gapped bundle loaded successfully!"
print_yellow "System is ready for RISX-MSSP deployment in air-gapped mode."
