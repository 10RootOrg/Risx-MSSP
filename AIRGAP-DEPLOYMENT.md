# Air-Gapped Deployment for RISX-MSSP

This document provides an overview of the air-gapped deployment solution for the RISX-MSSP platform.

## What is Air-Gapped Deployment?

Air-gapped deployment allows you to install and run the RISX-MSSP platform on systems that have no internet connectivity. This is essential for:

- High-security environments
- Classified networks
- Isolated production systems
- Compliance requirements (e.g., PCI-DSS, HIPAA, government regulations)

## Solution Overview

The air-gapped deployment solution consists of three main scripts:

1. **Download Script** (`1-download-for-airgap.sh`) - Run on online system
   - Downloads all Docker images
   - Downloads Velociraptor binaries for all platforms
   - Downloads external artifacts (YARA rules, Velociraptor artifacts)
   - Downloads system dependencies
   - Creates a complete offline bundle

2. **Load Script** (`2-load-airgap-bundle.sh`) - Run on air-gapped system
   - Installs system dependencies
   - Loads Docker images
   - Installs binaries
   - Configures system for air-gapped operation

3. **Patch Script** (`3-patch-scripts-for-airgap.sh`) - Run on air-gapped system
   - Modifies deployment scripts to use local resources
   - Updates Dockerfiles to use pre-downloaded binaries
   - Configures services for offline operation

## What Gets Downloaded?

### Docker Images (30+ images, ~40GB)

All container images required by the platform:

- **Security Tools**: MISP, Velociraptor, Strelka, Prowler, IRIS
- **Analysis Tools**: CyberChef, Nightingale
- **Infrastructure**: ELK Stack (Elasticsearch, Logstash, Kibana), Timesketch
- **Management**: Portainer, Nginx
- **Databases**: PostgreSQL, MySQL, MariaDB, Redis, OpenSearch
- **Base Images**: Python, Node.js, Ubuntu (for custom builds)

### Binaries and Tools

- **Velociraptor**: Linux, macOS, Windows binaries (.exe, .msi)
- **System Tools**: jq, docker-compose, rsync, curl, unzip
- **Debian Packages**: All required system packages with dependencies

### External Artifacts

- **Velociraptor Artifacts**: Custom artifact definitions from 10RootOrg
- **YARA Rules**: Full YARA rule set from YARA Forge for Strelka
- **Configuration Files**: Pre-configured for air-gapped operation

## Quick Start

### For Online System (Internet Connected)

```bash
cd setup_platform/scripts/air-gapped
./1-download-for-airgap.sh
tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/
```

### Transfer to Air-Gapped System

Use approved media to transfer:
- `risx-mssp-airgap-bundle.tar.gz` (~30GB compressed)
- The RISX-MSSP repository

### For Air-Gapped System (No Internet)

```bash
# Extract and load bundle
tar -xzf risx-mssp-airgap-bundle.tar.gz && cd airgap-bundle
sudo ./2-load-airgap-bundle.sh

# Patch deployment scripts
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped
sudo ./3-patch-scripts-for-airgap.sh

# Deploy platform
cd ../
sudo ./endtoend.sh
```

## How It Works

### Automatic Detection

The patched scripts automatically detect air-gapped mode by checking for:
1. Air-gapped configuration file: `/etc/risx-mssp-airgap`
2. Local artifacts directory: `/opt/risx-mssp-artifacts`
3. Pre-loaded Docker images

### Modified Behavior

When air-gapped mode is detected, scripts:
- Use local Docker images instead of pulling from registries
- Copy binaries from local storage instead of downloading
- Use local artifacts instead of fetching from GitHub
- Skip online connectivity checks

### No Code Duplication

The solution patches existing scripts rather than duplicating them:
- Original scripts remain unchanged (backed up as .bak)
- Patches add conditional logic to check for air-gapped mode
- Same scripts work both online and offline

## Components Modified

### Scripts Patched

1. **install-helper.sh**: Download function uses local files in air-gapped mode
2. **velociraptor.sh**: Copies pre-downloaded binaries before Docker build
3. **strelka.sh**: Uses local YARA rules instead of downloading
4. **install-pre-requisites.sh**: Skips Docker download if already installed
5. **main.sh**: Loads air-gapped environment configuration

### Dockerfiles Modified

1. **Velociraptor Dockerfile**: Checks for local binaries before downloading
   - If local binaries exist in build context, uses them
   - Otherwise, downloads from GitHub (online mode)

### Configuration Files Created

1. **/etc/risx-mssp-airgap**: System-wide air-gapped configuration
2. **airgap.env**: Environment variables for air-gapped deployment
3. **SHA256SUMS.txt**: Checksums for integrity verification

## Security Features

### Integrity Verification

- All downloaded files are checksummed
- Bundle includes SHA256SUMS.txt for verification
- Transfer integrity can be verified on air-gapped system

### No Internet Access Required

- All external dependencies pre-downloaded
- No DNS lookups needed
- No external API calls
- Complete offline operation

### Audit Trail

- VERSION.txt includes download date and component versions
- MANIFEST.txt lists all included files
- All downloads logged during bundle creation

## System Requirements

### Minimum Requirements

- **Online System**: 80GB free space, Docker installed
- **Air-Gapped System**: 150GB free space, x86_64/AMD64 architecture
- **Both Systems**: Linux (Ubuntu 22.04 recommended)

### Supported Architectures

- **Primary**: x86_64 / AMD64
- **Limited**: ARM64 (requires modification, some images may not be available)

## Documentation

Comprehensive documentation is provided:

- **[setup_platform/scripts/air-gapped/README.md](setup_platform/scripts/air-gapped/README.md)**: Complete guide with troubleshooting
- **[setup_platform/scripts/air-gapped/QUICK-START.md](setup_platform/scripts/air-gapped/QUICK-START.md)**: Quick reference for experienced users
- **Inline Comments**: All scripts heavily commented for clarity

## Verification

A verification script is included:

```bash
./verify-airgap-setup.sh
```

This checks:
- Air-gapped configuration loaded
- Docker installed and running
- Docker images present
- Required binaries available
- Artifacts in place
- Network configured

## Maintenance and Updates

### Updating the Bundle

When new versions of components are released:

1. Run download script again on online system
2. Transfer updated bundle to air-gapped system
3. Load updated images with load script
4. Redeploy services with updated versions

### Incremental Updates

For single component updates:
1. Download only changed image: `docker pull image:newtag`
2. Save image: `docker save -o image.tar image:newtag`
3. Transfer and load: `docker load -i image.tar`

## Tested Scenarios

### Known Working Configurations

- ✅ Ubuntu 22.04 LTS (AMD64) → Ubuntu 22.04 LTS (AMD64)
- ✅ Full RISX-MSSP platform deployment
- ✅ All services start and function correctly
- ✅ No internet connectivity required after setup

### Known Limitations

- ❌ ARM64 requires additional work (some images not available)
- ❌ Windows hosts not supported (Linux containers only)
- ⚠️ Docker must support the same image formats on both systems

## Troubleshooting

Common issues and solutions documented in README.md:

- Checksum failures
- Docker not running
- Missing artifacts
- Disk space issues
- Permission problems

## Files Created

```
setup_platform/scripts/air-gapped/
├── 1-download-for-airgap.sh      # Download script (online)
├── 2-load-airgap-bundle.sh       # Load script (air-gapped)
├── 3-patch-scripts-for-airgap.sh # Patch script (air-gapped)
├── README.md                      # Complete documentation
└── QUICK-START.md                 # Quick reference guide

Generated after download:
airgap-bundle/
├── docker-images/                 # Docker image tar files
├── binaries/                      # System binaries and tools
│   ├── velociraptor/              # Velociraptor binaries
│   ├── deb-packages/              # Debian packages
│   ├── docker-compose             # Docker Compose binary
│   ├── jq                         # jq binary
│   └── get-docker.sh              # Docker installer
├── artifacts/                     # External artifacts
│   ├── velociraptor-artifacts.zip
│   └── yara-forge-rules-full.zip
├── MANIFEST.txt                   # File listing
├── VERSION.txt                    # Component versions
├── README.md                      # Bundle documentation
└── SHA256SUMS.txt                 # Checksums

Generated after loading:
/etc/risx-mssp-airgap              # System configuration
/opt/risx-mssp-artifacts/          # Local artifacts
setup_platform/resources/airgap.env # Environment config
```

## Support

### Before Requesting Help

1. Run verification script and include output
2. Check that checksums passed during transfer
3. Verify Docker is running: `docker info`
4. Check disk space: `df -h`
5. Review script output for errors

### Information to Provide

- Output of `./verify-airgap-setup.sh`
- Content of `/etc/risx-mssp-airgap`
- Bundle version: `cat airgap-bundle/VERSION.txt`
- System info: `uname -a`
- Docker version: `docker --version`

## Future Enhancements

Potential improvements for future versions:

- [ ] ARM64 architecture support
- [ ] Automated testing of air-gapped bundles
- [ ] Delta updates (only transfer changed images)
- [ ] Multiple bundle variants (minimal, standard, full)
- [ ] Bundle signing and verification
- [ ] Automated rollback capability

## License

This air-gapped deployment solution is part of the RISX-MSSP project and follows the same license.

Third-party components included in the bundle retain their original licenses.

---

## Summary

The RISX-MSSP air-gapped deployment solution provides a complete, tested, and documented approach to deploying the platform in offline environments. It:

- ✅ Downloads all required components automatically
- ✅ Handles all dependencies (images, binaries, artifacts)
- ✅ Patches existing scripts intelligently
- ✅ Includes comprehensive verification
- ✅ Provides detailed documentation
- ✅ Supports complete offline operation
- ✅ Maintains same functionality as online deployment

**Ready to use immediately with three simple commands per system.**

---

**Created**: 2026-01-06
**Version**: 1.0
**Documentation**: [setup_platform/scripts/air-gapped/](setup_platform/scripts/air-gapped/)
**Quick Start**: [setup_platform/scripts/air-gapped/QUICK-START.md](setup_platform/scripts/air-gapped/QUICK-START.md)
