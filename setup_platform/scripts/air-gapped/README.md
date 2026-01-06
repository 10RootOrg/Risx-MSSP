# RISX-MSSP Air-Gapped Deployment Guide

This directory contains scripts and documentation for deploying the RISX-MSSP platform in air-gapped (offline/disconnected) environments.

## Overview

Air-gapped deployment is a three-step process:

1. **Online System**: Download all required Docker images, binaries, and artifacts
2. **Transfer**: Move the bundle to the air-gapped system using approved media
3. **Air-Gapped System**: Load images, install binaries, and deploy the platform

## Prerequisites

### Online System Requirements
- Internet connection
- Docker installed and running
- Minimum 50GB free disk space
- Linux system (Ubuntu 22.04 or similar)
- Required tools: `curl`, `jq`, `tar`, `sha256sum`

### Air-Gapped System Requirements
- No internet connection required
- Minimum 50GB free disk space for initial bundle
- Additional 100GB+ for platform deployment and data
- Linux system (Ubuntu 22.04 or similar, same architecture as online system)
- Sufficient permissions to install system packages and run Docker

## Step-by-Step Instructions

### Step 1: Download Bundle (Online System)

On a system with internet access:

```bash
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped

# Make the script executable
chmod +x 1-download-for-airgap.sh

# Run the download script
./1-download-for-airgap.sh
```

This will create an `airgap-bundle` directory containing:
- Docker images as `.tar` files
- Velociraptor binaries (Linux, Mac, Windows)
- External artifacts (YARA rules, Velociraptor artifacts)
- System binaries (jq, docker-compose)
- Debian packages for offline installation

**Expected Time**: 1-4 hours depending on internet speed
**Expected Size**: 30-50GB

### Step 2: Create and Transfer Archive

```bash
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped

# Create compressed archive
tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/

# Verify the archive
tar -tzf risx-mssp-airgap-bundle.tar.gz | head -20

# Generate checksum for verification
sha256sum risx-mssp-airgap-bundle.tar.gz > risx-mssp-airgap-bundle.tar.gz.sha256
```

Transfer the following files to the air-gapped system using approved media:
- `risx-mssp-airgap-bundle.tar.gz`
- `risx-mssp-airgap-bundle.tar.gz.sha256`
- The entire `Risx-MSSP` repository (can be transferred as a separate archive)

### Step 3: Load Bundle (Air-Gapped System)

On the air-gapped system:

```bash
# Verify the transferred archive
sha256sum -c risx-mssp-airgap-bundle.tar.gz.sha256

# Extract the bundle
tar -xzf risx-mssp-airgap-bundle.tar.gz
cd airgap-bundle

# Make scripts executable
chmod +x *.sh

# Load the air-gapped bundle (requires sudo)
sudo ./2-load-airgap-bundle.sh
```

This script will:
- Verify checksums of all files
- Install system dependencies from included packages
- Install Docker (if not already installed)
- Create Docker network
- Load all Docker images
- Copy artifacts to system location
- Create air-gapped configuration file

**Expected Time**: 30-60 minutes
**Requires**: sudo/root privileges

### Step 4: Patch Deployment Scripts

```bash
# Navigate to the air-gapped scripts directory
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped

# Make the patch script executable
chmod +x 3-patch-scripts-for-airgap.sh

# Run the patch script
sudo ./3-patch-scripts-for-airgap.sh /path/to/Risx-MSSP
```

This script modifies the deployment scripts to:
- Use local artifacts instead of downloading from internet
- Use pre-downloaded Velociraptor binaries
- Use local YARA rules for Strelka
- Skip online connectivity checks
- Use locally loaded Docker images

### Step 5: Verify Air-Gapped Setup

```bash
# Run the verification script
./verify-airgap-setup.sh
```

This checks:
- Air-gapped configuration is loaded
- Docker is installed and running
- Required binaries are available
- Docker images are loaded
- Artifacts are in place
- Docker network exists

### Step 6: Deploy RISX-MSSP Platform

```bash
# Navigate to the setup scripts directory
cd /path/to/Risx-MSSP/setup_platform/scripts

# Review and customize the default environment
# Edit ../resources/default.env if needed

# Run the end-to-end deployment
sudo ./endtoend.sh
```

The deployment will automatically detect air-gapped mode and use local resources.

## Scripts Reference

### 1-download-for-airgap.sh (Online System)

Downloads all required components for air-gapped deployment.

**Components Downloaded**:
- **Docker Images**: All images referenced in docker-compose files
  - CyberChef, ELK Stack, IRIS, Nginx, Nightingale, Prowler
  - Strelka, Timesketch, MISP, Portainer, Velociraptor
  - Base images for custom builds (Python, Node, Ubuntu, MySQL)

- **Velociraptor Binaries**:
  - Linux (AMD64)
  - macOS (AMD64)
  - Windows (AMD64 .exe and .msi)

- **External Artifacts**:
  - Velociraptor custom artifacts
  - YARA rules for Strelka

- **System Binaries**:
  - Docker installation script
  - Docker Compose binary
  - jq binary
  - Debian packages (curl, rsync, unzip, git, etc.)

**Output**: Creates `airgap-bundle/` directory with all files

### 2-load-airgap-bundle.sh (Air-Gapped System)

Loads the bundle on the air-gapped system.

**Actions**:
1. Verifies file checksums
2. Installs Debian packages
3. Installs binaries (jq, docker-compose)
4. Installs/verifies Docker
5. Creates Docker network
6. Loads all Docker images
7. Copies artifacts to `/opt/risx-mssp-artifacts`
8. Creates air-gapped configuration at `/etc/risx-mssp-airgap`
9. Creates helper script at `/usr/local/bin/risx-mssp-airgap-deploy`

**Requirements**: Must be run with sudo

### 3-patch-scripts-for-airgap.sh (Air-Gapped System)

Modifies deployment scripts for air-gapped operation.

**Files Modified**:
- `scripts/libs/install-helper.sh` - Air-gapped download function
- `resources/velociraptor/Dockerfile` - Use local binaries
- `scripts/apps/velociraptor.sh` - Copy binaries before build
- `scripts/apps/strelka.sh` - Use local YARA rules
- `scripts/libs/install-pre-requisites.sh` - Skip Docker download
- `scripts/libs/main.sh` - Load air-gapped environment
- `resources/airgap.env` - Created with air-gapped config

**Backup**: All modified files are backed up with `.bak` extension

### verify-airgap-setup.sh (Air-Gapped System)

Verifies the air-gapped setup is complete and correct.

**Checks**:
- ✓ Air-gapped configuration exists
- ✓ Docker installed and running
- ✓ Docker Compose available
- ✓ Docker images loaded
- ✓ Required binaries present
- ✓ Artifacts directory exists
- ✓ Velociraptor artifacts present
- ✓ YARA rules present
- ✓ Docker network created

**Exit Codes**:
- 0: Success, ready to deploy
- 1: Errors found, review output

## Architecture-Specific Notes

### Supported Architectures
- x86_64 / AMD64 (primary support)
- ARM64 (limited support, some images may not be available)

### Important Considerations
1. **Same Architecture**: The online and air-gapped systems should have the same architecture
2. **Docker Images**: Some images are multi-arch, others are architecture-specific
3. **Binaries**: System binaries (jq, docker-compose) are architecture-specific

If you need to support ARM64:
- Modify `1-download-for-airgap.sh` to download ARM64 binaries
- Ensure all Docker images have ARM64 variants
- Test thoroughly as some components may not support ARM64

## Customization

### Adding Additional Docker Images

Edit `1-download-for-airgap.sh` and add to the image download section:

```bash
pull_and_save_image "your-registry/your-image:tag"
```

### Adding Additional Artifacts

Edit `1-download-for-airgap.sh` and add to the artifacts section:

```bash
download_file "https://example.com/artifact.zip" "${ARTIFACTS_DIR}/artifact.zip"
```

Then update `3-patch-scripts-for-airgap.sh` to use the local artifact.

### Excluding Components

If you don't need certain components (e.g., Prowler), you can:
1. Comment out the image downloads in `1-download-for-airgap.sh`
2. Remove the component from `APPS_TO_INSTALL` in `default.env`

## Troubleshooting

### Issue: "Checksum verification failed"

**Cause**: File corruption during transfer
**Solution**: Re-transfer the archive and verify again

### Issue: "Docker is not running"

**Cause**: Docker service not started
**Solution**:
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Issue: "Failed to load image"

**Cause**: Corrupted image tar file
**Solution**: Check the specific image in the online system and regenerate

### Issue: "Cannot find local artifact"

**Cause**: Artifact not properly copied or path incorrect
**Solution**: Check `/opt/risx-mssp-artifacts/` directory and verify files exist

### Issue: "Some Debian packages fail to install"

**Cause**: Package dependency conflicts or architecture mismatch
**Solution**: Install packages manually or ensure they're pre-installed on air-gapped system

### Issue: Deployment tries to download from internet

**Cause**: Air-gapped patches not applied or configuration not loaded
**Solution**:
1. Verify `/etc/risx-mssp-airgap` exists
2. Run `./verify-airgap-setup.sh`
3. Re-run patch script: `./3-patch-scripts-for-airgap.sh`

## File Locations

After installation, important files are located at:

- **Air-gapped config**: `/etc/risx-mssp-airgap`
- **Artifacts**: `/opt/risx-mssp-artifacts/`
- **Velociraptor binaries**: `/opt/risx-mssp-artifacts/velociraptor/`
- **Docker images**: Loaded into Docker (view with `docker images`)
- **Deployment backups**: `setup_platform/scripts/**/*.bak`

## Security Considerations

1. **Checksum Verification**: Always verify checksums after transfer
2. **Media Sanitization**: Use approved transfer media and follow security procedures
3. **Access Control**: Limit access to the bundle and artifacts
4. **Audit Trail**: Keep records of what was transferred and when
5. **Docker Security**: Images are transferred as-is; scan for vulnerabilities if required

## Performance Notes

### Download Phase (Online System)
- **Time**: 1-4 hours (depends on internet speed)
- **Bandwidth**: ~30-50GB download
- **Disk I/O**: Heavy during image save operations

### Load Phase (Air-Gapped System)
- **Time**: 30-60 minutes
- **Disk I/O**: Heavy during image load operations
- **CPU**: Moderate during image decompression

### Deployment Phase
- **Time**: 30-60 minutes (same as normal deployment)
- **Resources**: Same as normal deployment

## Maintenance and Updates

### Updating the Air-Gapped Bundle

When new versions are released:

1. Run `1-download-for-airgap.sh` again on online system
2. Transfer updated bundle to air-gapped system
3. Run `2-load-airgap-bundle.sh` again (will update images)
4. Redeploy platform with new versions

### Incremental Updates

For small updates (single component):
1. Download only the changed images on online system
2. Save with `docker save -o image.tar image:tag`
3. Transfer and load with `docker load -i image.tar`
4. Restart affected services

## Disk Space Requirements

### Online System
- Download phase: ~50GB
- Archive creation: ~30GB (compressed)
- **Total**: ~80GB

### Air-Gapped System
- Bundle extraction: ~50GB
- Docker images (loaded): ~40GB
- Platform deployment: ~60GB (varies with data)
- **Total**: ~150GB minimum recommended

## Support and Issues

### Before Requesting Support

1. Run `./verify-airgap-setup.sh` and include output
2. Check `/var/log/docker` for Docker-related issues
3. Review deployment logs in `setup_platform/scripts/`
4. Include component versions from `airgap-bundle/VERSION.txt`

### Common Log Locations

- Docker logs: `journalctl -u docker`
- Container logs: `docker logs <container-name>`
- Deployment logs: Check script output
- System logs: `/var/log/syslog`

## Additional Resources

- **Main Documentation**: [Repository README](../../../README.md)
- **Component Documentation**: Individual component docs in `resources/*/`
- **Docker Documentation**: https://docs.docker.com (for reference)

## License and Attribution

This air-gapped deployment solution is part of the RISX-MSSP project.

Components included:
- Velociraptor: Apache 2.0 License
- ELK Stack: Elastic License / Apache 2.0
- IRIS: LGPL 3.0
- And others - see individual component licenses

---

**Last Updated**: 2026-01-06
**Version**: 1.0
**Tested On**: Ubuntu 22.04 LTS (AMD64)
