# RISX-MSSP Air-Gapped Deployment - Quick Start Guide

## TL;DR - Three Commands

### On Online System:
```bash
./1-download-for-airgap.sh
tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/
# Transfer risx-mssp-airgap-bundle.tar.gz to air-gapped system
```

### On Air-Gapped System:
```bash
tar -xzf risx-mssp-airgap-bundle.tar.gz && cd airgap-bundle
sudo ./2-load-airgap-bundle.sh
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped && sudo ./3-patch-scripts-for-airgap.sh
cd /path/to/Risx-MSSP/setup_platform/scripts && sudo ./endtoend.sh
```

---

## Complete Workflow

### Phase 1: Preparation (Online System with Internet)

```bash
# 1. Navigate to air-gapped scripts directory
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped

# 2. Download all required files
chmod +x 1-download-for-airgap.sh
./1-download-for-airgap.sh

# 3. Review what was downloaded
cat airgap-bundle/MANIFEST.txt
cat airgap-bundle/VERSION.txt

# 4. Create compressed archive for transfer
tar -czf risx-mssp-airgap-bundle.tar.gz airgap-bundle/

# 5. Create checksum for verification
sha256sum risx-mssp-airgap-bundle.tar.gz > risx-mssp-airgap-bundle.tar.gz.sha256

# 6. Check archive size
du -sh risx-mssp-airgap-bundle.tar.gz
```

**Expected Output**: Archive of ~25-35GB

### Phase 2: Transfer

```bash
# Copy these files to air-gapped system using approved media:
# - risx-mssp-airgap-bundle.tar.gz
# - risx-mssp-airgap-bundle.tar.gz.sha256
# - Risx-MSSP repository (as separate archive)
```

### Phase 3: Installation (Air-Gapped System)

```bash
# 1. Verify transfer integrity
sha256sum -c risx-mssp-airgap-bundle.tar.gz.sha256

# 2. Extract the bundle
tar -xzf risx-mssp-airgap-bundle.tar.gz
cd airgap-bundle

# 3. Load the bundle (installs Docker, loads images, etc.)
chmod +x 2-load-airgap-bundle.sh
sudo ./2-load-airgap-bundle.sh

# 4. Verify installation
./verify-airgap-setup.sh

# 5. Patch deployment scripts for air-gapped mode
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped
chmod +x 3-patch-scripts-for-airgap.sh
sudo ./3-patch-scripts-for-airgap.sh /path/to/Risx-MSSP

# 6. Verify patches applied
./verify-airgap-setup.sh

# 7. Deploy RISX-MSSP platform
cd /path/to/Risx-MSSP/setup_platform/scripts
sudo ./endtoend.sh
```

---

## Verification Checklist

### After Download (Online System)
- [ ] `airgap-bundle/` directory created
- [ ] `MANIFEST.txt` shows all expected files
- [ ] Docker images saved (check `airgap-bundle/docker-images/`)
- [ ] Binaries downloaded (check `airgap-bundle/binaries/`)
- [ ] Artifacts downloaded (check `airgap-bundle/artifacts/`)
- [ ] Archive created successfully
- [ ] Checksum file generated

### After Transfer (Air-Gapped System)
- [ ] Archive transferred completely
- [ ] Checksum verification passed
- [ ] Archive extracted successfully

### After Load (Air-Gapped System)
- [ ] Docker installed and running: `docker --version`
- [ ] Docker images loaded: `docker images | wc -l` (should show 30+ images)
- [ ] Docker network created: `docker network ls | grep main_network`
- [ ] Artifacts in place: `ls /opt/risx-mssp-artifacts/`
- [ ] Air-gapped config exists: `cat /etc/risx-mssp-airgap`
- [ ] Binaries installed: `which jq docker-compose`

### After Patching
- [ ] Backup files created (*.bak)
- [ ] Verification script passes: `./verify-airgap-setup.sh`
- [ ] Air-gapped env file created: `cat ../resources/airgap.env`

### After Deployment
- [ ] All services running: `docker ps`
- [ ] No error messages in deployment output
- [ ] Services accessible via web browser

---

## Common Commands

### Check Air-Gapped Status
```bash
# View configuration
cat /etc/risx-mssp-airgap

# Verify setup
cd /path/to/Risx-MSSP/setup_platform/scripts/air-gapped
./verify-airgap-setup.sh
```

### View Loaded Images
```bash
# List all images
docker images

# Count images
docker images -q | wc -l

# Show images with sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### View Running Containers
```bash
# List all running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View specific container logs
docker logs <container-name>
```

### Check Artifacts
```bash
# List artifacts
ls -lh /opt/risx-mssp-artifacts/

# Check Velociraptor binaries
ls -lh /opt/risx-mssp-artifacts/velociraptor/

# View artifact sizes
du -sh /opt/risx-mssp-artifacts/*
```

### Troubleshooting
```bash
# Check Docker status
systemctl status docker

# Check Docker info
docker info

# Verify network
docker network ls
docker network inspect main_network

# Check disk space
df -h

# View recent Docker logs
journalctl -u docker -n 50
```

---

## Time Estimates

| Phase | Time | Notes |
|-------|------|-------|
| Download (Online) | 1-4 hours | Depends on internet speed |
| Archive Creation | 10-30 min | Depends on disk I/O |
| Transfer | Varies | Depends on media and procedure |
| Load (Air-Gapped) | 30-60 min | Depends on disk I/O |
| Patching | 2-5 min | Quick modification of scripts |
| Deployment | 30-60 min | Same as normal deployment |
| **Total** | **3-7 hours** | Excluding transfer time |

---

## Disk Space Requirements

| Location | Space Needed | Purpose |
|----------|--------------|---------|
| Online System | 80GB | Download and archive creation |
| Transfer Media | 35GB | Compressed archive |
| Air-Gapped System | 150GB | Bundle + deployment |

**Recommendation**: Have at least 200GB free on air-gapped system

---

## Support

### If Something Goes Wrong

1. **Check verification script**: `./verify-airgap-setup.sh`
2. **Review logs**: `journalctl -u docker -n 100`
3. **Check disk space**: `df -h`
4. **Verify checksums**: Ensure transfer was successful
5. **Consult README.md**: Detailed troubleshooting section

### Getting Help

When requesting support, include:
- Output of `./verify-airgap-setup.sh`
- Content of `/etc/risx-mssp-airgap`
- `airgap-bundle/VERSION.txt`
- Relevant error messages
- System info: `uname -a`, `docker --version`

---

## Quick Reference

### File Locations
```
/etc/risx-mssp-airgap               # Air-gapped configuration
/opt/risx-mssp-artifacts/           # Downloaded artifacts
/usr/local/bin/jq                   # jq binary
/usr/local/bin/docker-compose       # Docker Compose
```

### Important Scripts
```
1-download-for-airgap.sh           # Online: Download everything
2-load-airgap-bundle.sh            # Air-gapped: Load bundle
3-patch-scripts-for-airgap.sh      # Air-gapped: Patch scripts
verify-airgap-setup.sh             # Air-gapped: Verify setup
```

### Key Docker Commands
```bash
docker images                       # List loaded images
docker ps                          # List running containers
docker network ls                  # List networks
docker logs <container>            # View container logs
docker restart <container>         # Restart container
```

---

**For detailed information, see [README.md](README.md)**

**Last Updated**: 2026-01-06
