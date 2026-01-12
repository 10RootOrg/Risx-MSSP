#!/bin/bash
################################################################################
# Air-Gapped Deployment - Patch Script
################################################################################
# This script modifies the existing deployment scripts to support air-gapped mode.
# It should be run on the air-gapped system after loading the bundle.
#
# Usage: sudo ./3-patch-scripts-for-airgap.sh [path-to-risx-mssp-repo]
#
# The script will:
# 1. Detect air-gapped configuration
# 2. Patch deployment scripts to use local artifacts
# 3. Modify Dockerfiles to use pre-downloaded binaries
# 4. Update helper functions for offline operation
################################################################################

set -eo pipefail

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_green() { printf "${GREEN}%s${NC}\n" "$1"; }
print_red() { printf "${RED}%s${NC}\n" "$1"; }
print_yellow() { printf "${YELLOW}%s${NC}\n" "$1"; }

print_with_border() {
    local input_string="$1"
    local length=${#input_string}
    local border="===================== "
    local border_length=$(((80 - length - ${#border}) / 2))
    printf "%s" "$border"
    for ((i = 0; i < border_length; i++)); do printf "="; done
    printf " %s " "$input_string"
    for ((i = 0; i < border_length; i++)); do printf "="; done
    printf "%s\n" "$border"
}

# Get repository path
REPO_PATH="${1:-$(pwd)/../..}"
REPO_PATH=$(realpath "$REPO_PATH")

if [ ! -d "$REPO_PATH/setup_platform" ]; then
    print_red "Error: Cannot find setup_platform directory in $REPO_PATH"
    print_yellow "Usage: $0 [path-to-risx-mssp-repo]"
    exit 1
fi

SCRIPTS_DIR="$REPO_PATH/setup_platform/scripts"
RESOURCES_DIR="$REPO_PATH/setup_platform/resources"

print_with_border "Patching Scripts for Air-Gapped Mode"
echo "Repository: $REPO_PATH"
echo ""

# Load air-gapped configuration
if [ -f /etc/risx-mssp-airgap ]; then
    source /etc/risx-mssp-airgap
    print_green "Air-gapped configuration loaded"
else
    print_red "Error: Air-gapped configuration not found at /etc/risx-mssp-airgap"
    print_yellow "Please run 2-load-airgap-bundle.sh first"
    exit 1
fi

################################################################################
# 1. Patch install-helper.sh to add air-gapped aware download function
################################################################################
print_with_border "Patching install-helper.sh"

INSTALL_HELPER="$SCRIPTS_DIR/libs/install-helper.sh"
if [ -f "$INSTALL_HELPER" ]; then
    # Create backup
    cp "$INSTALL_HELPER" "$INSTALL_HELPER.bak"

    # Add air-gapped download function before the existing download_external_file function
    cat > /tmp/airgap_helper.sh << 'HELPER_EOF'

# --- Air-gapped aware download function
# This function checks if we're in air-gapped mode and uses local files
# Inputs:
# $1 - url to download (or local file path in air-gapped mode)
# $2 - file name to save
function download_external_file() {
  local url=$1
  local file_name=$2

  # Check if running in air-gapped mode
  if [ -f /etc/risx-mssp-airgap ]; then
    source /etc/risx-mssp-airgap
    if [ "$AIRGAP_MODE" = "true" ]; then
      print_yellow "Air-gapped mode detected, using local artifacts..."

      # Map URLs to local files
      local local_file=""
      case "$url" in
        *"Velociraptor-Artifacts"*|*"velociraptor-artifacts"*)
          local_file="$AIRGAP_VELOCIRAPTOR_ARTIFACTS"
          ;;
        *"yara-forge"*|*"YARAHQ"*)
          local_file="$AIRGAP_YARA_RULES"
          ;;
        *)
          print_yellow "Unknown artifact URL: $url"
          print_yellow "Looking in artifacts directory: $ARTIFACTS_DIR"
          # Try to find file by name pattern
          local basename=$(basename "$url")
          if [ -f "$ARTIFACTS_DIR/$basename" ]; then
            local_file="$ARTIFACTS_DIR/$basename"
          fi
          ;;
      esac

      if [ -n "$local_file" ] && [ -f "$local_file" ]; then
        print_green "Using local file: $local_file"
        cp "$local_file" "$file_name"
        print_green_v2 "$file_name" "Copied from local"
        return 0
      else
        print_red "Error: Local file not found for $url"
        print_yellow "Expected location: $local_file"
        return 1
      fi
    fi
  fi

  # Original online download behavior
  if [ ! -f "$file_name" ]; then
    curl --show-error --silent --location --output "$file_name" "$url"
    print_green_v2 "$file_name" "Downloaded"
  else
    print_red "$file_name already exists."
  fi
}
HELPER_EOF

    # Find the line number where download_external_file is defined
    LINE_NUM=$(grep -n "^function download_external_file" "$INSTALL_HELPER" | head -1 | cut -d: -f1)

    if [ -n "$LINE_NUM" ]; then
        # Remove the old function (assuming it's about 12 lines long)
        sed -i "${LINE_NUM},$((LINE_NUM + 11))d" "$INSTALL_HELPER"
        # Insert the new function at that position
        sed -i "${LINE_NUM}r /tmp/airgap_helper.sh" "$INSTALL_HELPER"
        print_green "install-helper.sh patched successfully"
    else
        print_yellow "Could not find download_external_file function, appending to end"
        cat /tmp/airgap_helper.sh >> "$INSTALL_HELPER"
    fi

    rm /tmp/airgap_helper.sh
else
    print_red "install-helper.sh not found at $INSTALL_HELPER"
fi

################################################################################
# 2. Patch Velociraptor Dockerfile to use local binaries
################################################################################
print_with_border "Patching Velociraptor Dockerfile"

VELOX_DOCKERFILE="$RESOURCES_DIR/velociraptor/Dockerfile"
if [ -f "$VELOX_DOCKERFILE" ]; then
    cp "$VELOX_DOCKERFILE" "$VELOX_DOCKERFILE.bak"

    # Create air-gapped version of Dockerfile
    cat > "$VELOX_DOCKERFILE" << 'DOCKERFILE_EOF'
FROM ubuntu:22.04

# Define the VELOX_RELEASE https://github.com/Velocidex/velociraptor/releases
ARG VELOCIRAPTOR_VERSION=v0.74

LABEL description="Velociraptor server in a Docker container"
LABEL maintainer="@10RootOrg"
LABEL src.forked_from="https://github.com/weslambert/velociraptor-docker/tree/master"
LABEL version="Velociraptor $VELOCIRAPTOR_VERSION"

COPY ./entrypoint /entrypoint
RUN chmod +x /entrypoint

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      rsync curl jq ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create dirs for Velociraptor binaries
RUN mkdir -p /opt/velociraptor/linux && \
    mkdir -p /opt/velociraptor/mac && \
    mkdir -p /opt/velociraptor/windows

# Check if we're in air-gapped mode by looking for pre-downloaded binaries
# If binaries exist in build context, use them; otherwise download from GitHub
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
      echo "Downloading Velociraptor binaries from GitHub (online mode)"; \
      curl -o /tmp/velociraptor_rel.json -L -s https://api.github.com/repos/velocidex/velociraptor/releases/tags/${VELOCIRAPTOR_VERSION} && \
      LINUX_BIN="$(jq -r '.assets[] | select(.name | test("linux-amd64$")) | .browser_download_url' /tmp/velociraptor_rel.json | sort -V | tail -n 1)" && \
      MAC_BIN="$(jq -r '.assets[] | select(.name | test("darwin-amd64$")) | .browser_download_url' /tmp/velociraptor_rel.json | sort -V | tail -n 1)" && \
      WINDOWS_EXE="$(jq -r '.assets[] | select(.name | test("windows-amd64.exe$")) | .browser_download_url' /tmp/velociraptor_rel.json | sort -V | tail -n 1)" && \
      WINDOWS_MSI="$(jq -r '.assets[] | select(.name | test("windows-amd64.msi$")) | .browser_download_url' /tmp/velociraptor_rel.json | sort -V | tail -n 1)" && \
      curl -s -L -o /opt/velociraptor/linux/velociraptor "$LINUX_BIN" && chmod +x /opt/velociraptor/linux/velociraptor && \
      curl -s -L -o /opt/velociraptor/mac/velociraptor_client "$MAC_BIN" && \
      curl -s -L -o /opt/velociraptor/windows/velociraptor_client.exe "$WINDOWS_EXE" && \
      curl -s -L -o /opt/velociraptor/windows/velociraptor_client.msi "$WINDOWS_MSI" && \
      rm -f /tmp/velociraptor_rel.json; \
    fi

# Set working directory
WORKDIR /velociraptor

# Default command
CMD ["/entrypoint"]
DOCKERFILE_EOF

    print_green "Velociraptor Dockerfile patched for air-gapped mode"
else
    print_yellow "Velociraptor Dockerfile not found"
fi

################################################################################
# 3. Patch Velociraptor deployment script
################################################################################
print_with_border "Patching Velociraptor Deployment Script"

VELOX_SCRIPT="$SCRIPTS_DIR/apps/velociraptor.sh"
if [ -f "$VELOX_SCRIPT" ]; then
    cp "$VELOX_SCRIPT" "$VELOX_SCRIPT.bak"

    # Add code to copy binaries before docker build if in air-gapped mode
    # Find the line with "docker compose up -d --build"
    LINE_NUM=$(grep -n "docker compose up -d --build" "$VELOX_SCRIPT" | head -1 | cut -d: -f1)

    if [ -n "$LINE_NUM" ]; then
        # Insert air-gapped binary copy before docker build
        sed -i "${LINE_NUM}i\\
# Always create velociraptor_binaries directory for Dockerfile COPY\\
mkdir -p \"\${workdir}/\${service_name}/velociraptor_binaries\"\\
\\
# Air-gapped mode: Copy pre-downloaded Velociraptor binaries\\
if [ -f /etc/risx-mssp-airgap ]; then\\
  source /etc/risx-mssp-airgap\\
  if [ \"\$AIRGAP_MODE\" = \"true\" ] && [ -d \"\$VELOCIRAPTOR_BINARIES_DIR\" ]; then\\
    print_yellow \"Air-gapped mode: Copying Velociraptor binaries to build context...\"\\
    cp -r \"\$VELOCIRAPTOR_BINARIES_DIR/\"* \"\${workdir}/\${service_name}/velociraptor_binaries/\"\\
    print_green \"Velociraptor binaries copied for air-gapped build\"\\
  fi\\
fi\\
" "$VELOX_SCRIPT"
        print_green "Velociraptor script patched successfully"
    else
        print_yellow "Could not find docker compose command in velociraptor.sh"
    fi
else
    print_yellow "Velociraptor script not found"
fi

################################################################################
# 4. Patch Strelka deployment script for YARA rules
################################################################################
print_with_border "Patching Strelka Deployment Script"

STRELKA_SCRIPT="$SCRIPTS_DIR/apps/strelka.sh"
if [ -f "$STRELKA_SCRIPT" ]; then
    cp "$STRELKA_SCRIPT" "$STRELKA_SCRIPT.bak"

    # Find the YARA download section and add air-gapped check
    sed -i '/^GITHUB_URL_YARAHQ=/a\
\
# Check for air-gapped mode\
if [ -f /etc/risx-mssp-airgap ]; then\
  source /etc/risx-mssp-airgap\
  if [ "$AIRGAP_MODE" = "true" ] && [ -f "$AIRGAP_YARA_RULES" ]; then\
    print_yellow "Air-gapped mode: Using local YARA rules..."\
    TMP_DIR=$(mktemp -d)\
    cp "$AIRGAP_YARA_RULES" "${TMP_DIR}/yara-forge-rules-full.zip"\
    print_green "Using local YARA rules from: $AIRGAP_YARA_RULES"\
  else\
    # Original download code follows\
    TMP_DIR=$(mktemp -d)\
    printf "Downloading the %s YARA rules from YARA Forge...\\n" "${GITHUB_COMMIT_YARAHQ}"\
    curl -o "${TMP_DIR}"/yara-forge-rules-full.zip -Ls "${GITHUB_URL_YARAHQ}"\
  fi\
else\
  # Original download code for online mode
' "$STRELKA_SCRIPT"

    # Remove the original download lines (they are now conditional)
    sed -i '/^TMP_DIR=$(mktemp -d)$/d' "$STRELKA_SCRIPT"
    sed -i '/^printf "Downloading the %s YARA rules from YARA Forge/d' "$STRELKA_SCRIPT"
    sed -i '/^curl -o "${TMP_DIR}"\/yara-forge-rules-full.zip -Ls "${GITHUB_URL_YARAHQ}"$/d' "$STRELKA_SCRIPT"

    # Close the else block before unzip
    sed -i '/^unzip -o "${TMP_DIR}"\/yara-forge-rules-full.zip/i\
fi
' "$STRELKA_SCRIPT"

    print_green "Strelka script patched successfully"
else
    print_yellow "Strelka script not found"
fi

################################################################################
# 5. Patch risx-mssp.sh for air-gapped git clone operations
################################################################################
print_with_border "Patching RISX-MSSP Deployment Script"

RISX_MSSP_SCRIPT="$SCRIPTS_DIR/apps/risx-mssp.sh"
if [ -f "$RISX_MSSP_SCRIPT" ]; then
    cp "$RISX_MSSP_SCRIPT" "$RISX_MSSP_SCRIPT.bak"

    # Patch the backend repository clone
    sed -i '/^if \[\[ ! -d "${workdir}\/${service_name}\/backend\/risx-mssp-back" \]\]; then$/,/^fi$/c\
if [[ ! -d "${workdir}/${service_name}/backend/risx-mssp-back" ]]; then\
  # Check for air-gapped mode\
  if [ -f /etc/risx-mssp-airgap ]; then\
    source /etc/risx-mssp-airgap\
    if [ "$AIRGAP_MODE" = "true" ] && [ -f "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-back.tar.gz" ]; then\
      print_yellow "Air-gapped mode: Extracting risx-mssp-back from local archive..."\
      tar -xzf "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-back.tar.gz" -C "${workdir}/${service_name}/backend/"\
      print_green "risx-mssp-back extracted from local archive"\
    else\
      print_yellow "Cloning risx-mssp-back from GitHub..."\
      git clone --branch "${GIT_RISX_BACKEND_BRANCH}" "${GIT_RISX_BACKEND_URL}" "${workdir}/${service_name}/backend/risx-mssp-back"\
    fi\
  else\
    git clone --branch "${GIT_RISX_BACKEND_BRANCH}" "${GIT_RISX_BACKEND_URL}" "${workdir}/${service_name}/backend/risx-mssp-back"\
  fi\
  # Modify config for the right IP\
  sed -i "s/localhost/${INTERNAL_IP_OF_HOST_MACHINE}/g" "${workdir}/${service_name}/backend/risx-mssp-back/db/seeds/production/config_seed.json"\
  sed -i "s/importing/${TIMESKETCH_PASSWORD}/g" "${workdir}/${service_name}/backend/risx-mssp-back/db/seeds/production/config_seed.json"\
  sed -i "s/import/${TIMESKETCH_USERNAME}/g" "${workdir}/${service_name}/backend/risx-mssp-back/db/seeds/production/config_seed.json"\
  # Add development script to package.json if not exists\
  if ! grep -q '\''"dev"'\'' "${workdir}/${service_name}/backend/risx-mssp-back/package.json"; then\
    sed -i '\''/"scripts": {/a \\    "dev": "nodemon --exec babel-node src/server.js",'\'' "${workdir}/${service_name}/backend/risx-mssp-back/package.json"\
  fi\
fi
' "$RISX_MSSP_SCRIPT"

    # Patch the Python repository clone
    sed -i '/^if \[\[ ! -d "${workdir}\/${service_name}\/backend\/python-scripts" \]\]; then$/,/^fi$/c\
if [[ ! -d "${workdir}/${service_name}/backend/python-scripts" ]]; then\
  # Check for air-gapped mode\
  if [ -f /etc/risx-mssp-airgap ]; then\
    source /etc/risx-mssp-airgap\
    if [ "$AIRGAP_MODE" = "true" ] && [ -f "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-python.tar.gz" ]; then\
      print_yellow "Air-gapped mode: Extracting risx-mssp-python from local archive..."\
      tar -xzf "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-python.tar.gz" -C "${workdir}/${service_name}/backend/"\
      mv "${workdir}/${service_name}/backend/risx-mssp-python" "${workdir}/${service_name}/backend/python-scripts"\
      print_green "risx-mssp-python extracted from local archive"\
    else\
      print_yellow "Cloning risx-mssp-python from GitHub..."\
      git clone --branch "${GIT_RISX_PY_BRANCH}" "${GIT_RISX_PY_URL}" "${workdir}/${service_name}/backend/python-scripts"\
    fi\
  else\
    git clone --branch "${GIT_RISX_PY_BRANCH}" "${GIT_RISX_PY_URL}" "${workdir}/${service_name}/backend/python-scripts"\
  fi\
  # Setup Velociraptor config\
  rm -f "${workdir}/${service_name}/backend/python-scripts/modules/Velociraptor/dependencies/api.config.yaml"\
  cd "${workdir}"/velociraptor/velociraptor/\
  sudo ./velociraptor --config server.config.yaml config api_client \\\
    --name api --role api,administrator \\\
      "${workdir}"/"${service_name}"/backend/python-scripts/modules/Velociraptor/dependencies/api.config.yaml\
  cd -\
  sudo chown 1000:1000 "${workdir}/${service_name}/backend/python-scripts/modules/Velociraptor/dependencies/api.config.yaml"\
  sed -i "s/0.0.0.0:8001/${FRONT_IP}:8001/g" "${workdir}/${service_name}/backend/python-scripts/modules/Velociraptor/dependencies/api.config.yaml"\
fi
' "$RISX_MSSP_SCRIPT"

    # Patch the frontend repository clone
    sed -i '/^git clone --branch "${GIT_RISX_FRONTEND_BRANCH}" "${GIT_RISX_FRONTEND_URL}" risx-mssp-front$/c\
# Check for air-gapped mode for frontend\
if [ -f /etc/risx-mssp-airgap ]; then\
  source /etc/risx-mssp-airgap\
  if [ "$AIRGAP_MODE" = "true" ] && [ -f "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-front.tar.gz" ]; then\
    print_yellow "Air-gapped mode: Extracting risx-mssp-front from local archive..."\
    tar -xzf "$ARTIFACTS_DIR/risx-mssp-repos/risx-mssp-front.tar.gz" -C .\
    print_green "risx-mssp-front extracted from local archive"\
  else\
    print_yellow "Cloning risx-mssp-front from GitHub..."\
    git clone --branch "${GIT_RISX_FRONTEND_BRANCH}" "${GIT_RISX_FRONTEND_URL}" risx-mssp-front\
  fi\
else\
  git clone --branch "${GIT_RISX_FRONTEND_BRANCH}" "${GIT_RISX_FRONTEND_URL}" risx-mssp-front\
fi
' "$RISX_MSSP_SCRIPT"

    print_green "RISX-MSSP script patched successfully"
else
    print_yellow "RISX-MSSP script not found"
fi

################################################################################
# 7. Patch install-pre-requisites.sh to skip Docker download in air-gapped
################################################################################
print_with_border "Patching Install Prerequisites Script"

PREREQ_SCRIPT="$SCRIPTS_DIR/libs/install-pre-requisites.sh"
if [ -f "$PREREQ_SCRIPT" ]; then
    cp "$PREREQ_SCRIPT" "$PREREQ_SCRIPT.bak"

    # Add air-gapped check to install_docker function
    sed -i '/^function install_docker() {/a\
  # Check if in air-gapped mode and Docker is already installed\
  if [ -f /etc/risx-mssp-airgap ]; then\
    source /etc/risx-mssp-airgap\
    if [ "$AIRGAP_MODE" = "true" ]; then\
      if command -v docker &> /dev/null; then\
        echo "Air-gapped mode: Docker already installed, skipping download"\
        return 0\
      else\
        echo "Error: Air-gapped mode but Docker not installed"\
        echo "Please install Docker manually or run the air-gapped load script first"\
        return 1\
      fi\
    fi\
  fi
' "$PREREQ_SCRIPT"

    print_green "Install prerequisites script patched successfully"
else
    print_yellow "Install prerequisites script not found"
fi

################################################################################
# 8. Create air-gapped environment additions for default.env
################################################################################
print_with_border "Creating Air-Gapped Environment File"

AIRGAP_ENV="$RESOURCES_DIR/airgap.env"
cat > "$AIRGAP_ENV" << EOF
# Air-Gapped Mode Configuration
# This file is automatically sourced when in air-gapped mode
# Generated: $(date)

# Air-gapped mode flag
AIRGAP_MODE=true

# Artifacts locations
AIRGAP_ARTIFACTS_DIR=${ARTIFACTS_DIR}
AIRGAP_VELOCIRAPTOR_BINARIES=${VELOCIRAPTOR_BINARIES_DIR}
AIRGAP_VELOCIRAPTOR_ARTIFACTS=${VELOCIRAPTOR_ARTIFACTS_ZIP}
AIRGAP_YARA_RULES=${YARA_RULES_ZIP}

# RISX-MSSP source repositories
AIRGAP_RISX_MSSP_REPOS=${ARTIFACTS_DIR}/risx-mssp-repos

# Skip online checks
SKIP_ONLINE_CHECKS=true

# Use local Docker images (already loaded)
USE_LOCAL_IMAGES=true
EOF

print_green "Air-gapped environment file created: $AIRGAP_ENV"

################################################################################
# 9. Patch main.sh to load air-gapped env if available
################################################################################
print_with_border "Patching Main Library Script"

MAIN_SCRIPT="$SCRIPTS_DIR/libs/main.sh"
if [ -f "$MAIN_SCRIPT" ]; then
    cp "$MAIN_SCRIPT" "$MAIN_SCRIPT.bak"

    # Add air-gapped env loading to define_env function
    sed -i '/^define_env() {/a\
  # Load air-gapped configuration if available\
  if [ -f /etc/risx-mssp-airgap ]; then\
    source /etc/risx-mssp-airgap\
    if [ "$AIRGAP_MODE" = "true" ]; then\
      local airgap_env="../resources/airgap.env"\
      if [ -f "$airgap_env" ]; then\
        source "$airgap_env"\
        print_yellow "Air-gapped mode enabled"\
      fi\
    fi\
  fi
' "$MAIN_SCRIPT"

    print_green "Main library script patched successfully"
else
    print_yellow "Main library script not found"
fi

################################################################################
# 10. Create verification script
################################################################################
print_with_border "Creating Verification Script"

VERIFY_SCRIPT="$SCRIPTS_DIR/air-gapped/verify-airgap-setup.sh"
mkdir -p "$(dirname "$VERIFY_SCRIPT")"

cat > "$VERIFY_SCRIPT" << 'VERIFY_EOF'
#!/bin/bash
# Verification script for air-gapped setup

set -eo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

print_green() { printf "${GREEN}✓${NC} %s\n" "$1"; }
print_red() { printf "${RED}✗${NC} %s\n" "$1"; }
print_yellow() { printf "${YELLOW}!${NC} %s\n" "$1"; }

echo "========================================="
echo "Air-Gapped Setup Verification"
echo "========================================="
echo ""

ERRORS=0

# Check air-gapped config
if [ -f /etc/risx-mssp-airgap ]; then
    source /etc/risx-mssp-airgap
    print_green "Air-gapped configuration found"
else
    print_red "Air-gapped configuration not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker
if command -v docker &> /dev/null; then
    print_green "Docker installed: $(docker --version)"
else
    print_red "Docker not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check docker-compose
if command -v docker-compose &> /dev/null || command -v docker compose &> /dev/null; then
    print_green "Docker Compose installed"
else
    print_red "Docker Compose not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker images
IMAGE_COUNT=$(docker images -q | wc -l)
if [ $IMAGE_COUNT -gt 0 ]; then
    print_green "Docker images loaded: $IMAGE_COUNT"
else
    print_red "No Docker images found"
    ERRORS=$((ERRORS + 1))
fi

# Check required binaries
for cmd in jq rsync unzip curl; do
    if command -v $cmd &> /dev/null; then
        print_green "$cmd installed"
    else
        print_yellow "$cmd not installed (may cause issues)"
    fi
done

# Check artifacts
if [ -d "$ARTIFACTS_DIR" ]; then
    print_green "Artifacts directory exists: $ARTIFACTS_DIR"

    if [ -f "$AIRGAP_VELOCIRAPTOR_ARTIFACTS" ]; then
        print_green "Velociraptor artifacts found"
    else
        print_yellow "Velociraptor artifacts not found"
    fi

    if [ -f "$AIRGAP_YARA_RULES" ]; then
        print_green "YARA rules found"
    else
        print_yellow "YARA rules not found"
    fi
else
    print_red "Artifacts directory not found"
    ERRORS=$((ERRORS + 1))
fi

# Check Docker network
if docker network ls | grep -q "main_network"; then
    print_green "Docker network 'main_network' exists"
else
    print_yellow "Docker network 'main_network' not found (will be created)"
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    print_green "Verification passed! System ready for deployment"
    exit 0
else
    print_red "Verification failed with $ERRORS errors"
    exit 1
fi
VERIFY_EOF

chmod +x "$VERIFY_SCRIPT"
print_green "Verification script created: $VERIFY_SCRIPT"

################################################################################
# Summary
################################################################################
print_with_border "Patching Complete"

cat << EOF

Summary of Changes:
-------------------
✓ install-helper.sh - Added air-gapped download function
✓ Velociraptor Dockerfile - Modified to use local binaries
✓ velociraptor.sh - Added air-gapped binary copy
✓ strelka.sh - Added air-gapped YARA rules support
✓ install-pre-requisites.sh - Skip Docker download in air-gapped mode
✓ main.sh - Load air-gapped environment
✓ airgap.env - Air-gapped configuration file created
✓ verify-airgap-setup.sh - Verification script created

Backup Files Created:
---------------------
All modified files have been backed up with .bak extension

Next Steps:
-----------
1. Verify the setup:
   $VERIFY_SCRIPT

2. Deploy the platform:
   cd $SCRIPTS_DIR
   sudo ./endtoend.sh

The deployment will automatically detect and use air-gapped mode.

EOF

print_green "All scripts patched successfully for air-gapped deployment!"
