# Air-Gapped Deployment - Customization Guide

This guide explains how to customize which components are downloaded and their versions.

## Disabling Specific Components

You can disable components you don't want in two places:

### Option 1: Modify default.env (Recommended)

Edit `setup_platform/resources/default.env`:

```bash
# Find the APPS_TO_INSTALL array (around line 27)
APPS_TO_INSTALL=(
portainer
velociraptor
timesketch
elk
iris-web
cyberchef
nightingale
prowler
strelka
misp
risx-mssp
)
```

**To disable a component**, simply comment it out or remove it:

```bash
# Example: Disable prowler and nightingale
APPS_TO_INSTALL=(
portainer
velociraptor
timesketch
elk
iris-web
cyberchef
# nightingale        # DISABLED - don't need this
# prowler            # DISABLED - don't need this
strelka
misp
risx-mssp
)
```

### Option 2: Modify Download Script

Edit `setup_platform/scripts/air-gapped/1-download-for-airgap.sh`:

Find the section downloading images (starts around line 150) and comment out the ones you don't want:

```bash
# Nightingale - COMMENTED OUT
# pull_and_save_image "ghcr.io/rajanagori/nightingale:${NIGHTINGALE_IMAGE_TAG:-v1.0.0}"

# Prowler - COMMENTED OUT
# pull_and_save_image "prowlercloud/prowler-api:${PROWLER_API_VERSION:-stable}"
# pull_and_save_image "prowlercloud/prowler-ui:${PROWLER_UI_VERSION:-latest}"
# pull_and_save_image "postgres:${PROWLER_POSTGRES_VERSION:-16.3-alpine3.20}"
# pull_and_save_image "valkey/valkey:${PROWLER_VALKEY_VERSION:-7-alpine3.19}"
```

### Recommended Approach

**Do both**:
1. Remove from `APPS_TO_INSTALL` in `default.env`
2. Comment out image downloads in `1-download-for-airgap.sh`

This ensures:
- Images aren't downloaded (saves time and space)
- Components aren't deployed (clean installation)

## Changing Component Versions

All component versions are defined in `setup_platform/resources/default.env`.

### Version Configuration Section

Find the "Containers versions" section (around line 106):

```bash
# Containers versions

# VELOCIRAPTOR
VELOCIRAPTOR_VERSION=v0.74

#ELASTIC
ELASTIC_VERSION=8.15.3

#IRIS
IRIS_VERSION=v2.4.20
IRIS_RABBITMQ_VERSION=3-management-alpine

#TIMESKETCH
TIMESKETCH_VERSION=20250708
TIMESKETCH_OPENSEARCH_VERSION=2.15.0
TIMESKETCH_POSTGRES_VERSION=13.0-alpine
TIMESKETCH_REDIS_VERSION=6.0.8-alpine
TIMESKETCH_NGINX_VERSION=1.19.3-alpine

#NGINX
NGINX_VERSION=1.19.3-alpine

#PORTAINER
PORTAINER_AGENT_VERSION=2.21.0
PORTAINER_VERSION=2.21.0

#NIGHTINGALE
NIGHTINGALE_IMAGE_TAG=v1.0.0

#STERLKA
STRELKA_VERSION=0.24.07.09
STRELKA_UI_VERSION=v2.13
STRELKA_REDIS_VERSION=7.4.0-alpine3.20
STRELKA_JAEGER_VERSION=1.42

#PROWLER
PROWLER_UI_VERSION=latest
PROWLER_API_VERSION=stable
PROWLER_POSTGRES_VERSION=16.3-alpine3.20
PROWLER_VALKEY_VERSION=7-alpine3.19

#CYBERCHEF
CYBERCHEF_IMAGE_TAG=10.19
```

### How to Change Versions

**Example 1: Update Velociraptor to newer version**

```bash
# Change from:
VELOCIRAPTOR_VERSION=v0.74

# To:
VELOCIRAPTOR_VERSION=v0.75
```

**Example 2: Update ELK Stack**

```bash
# Change from:
ELASTIC_VERSION=8.15.3

# To:
ELASTIC_VERSION=8.16.0
```

**Example 3: Update IRIS**

```bash
# Change from:
IRIS_VERSION=v2.4.20

# To:
IRIS_VERSION=v2.4.21
```

**Example 4: Use specific Prowler version instead of "stable"**

```bash
# Change from:
PROWLER_API_VERSION=stable

# To:
PROWLER_API_VERSION=4.3.5
```

### Important Notes

1. **Version Format**: Different projects use different version formats:
   - Velociraptor: `v0.74` (with 'v' prefix)
   - Elastic: `8.15.3` (semantic versioning)
   - IRIS: `v2.4.20` (with 'v' prefix)
   - Prowler: `stable` or version number

2. **Check Available Versions**: Before changing, verify the version exists:
   - Docker Hub: `docker search <image>`
   - GitHub Container Registry: Check releases page
   - Project documentation

3. **Compatibility**: Ensure version compatibility between related components:
   - Elastic, Logstash, Kibana should use same version
   - Base images and application versions

## Complete Customization Examples

### Example 1: Minimal Security Stack

Only deploy core security tools, skip analysis tools:

**Edit `default.env`:**
```bash
APPS_TO_INSTALL=(
portainer          # Keep for management
velociraptor       # Core EDR
iris-web          # Case management
elk               # Logging
risx-mssp         # Main platform
)
```

**Edit `1-download-for-airgap.sh`:**
Comment out these sections:
- Nightingale images
- Prowler images
- Strelka images
- Timesketch images
- MISP images
- CyberChef image

**Expected savings**: ~15-20GB download size

### Example 2: Use Latest Versions

**Edit `default.env`:**
```bash
# Use latest stable versions
VELOCIRAPTOR_VERSION=v0.74
ELASTIC_VERSION=8.16.1        # Updated
IRIS_VERSION=v2.4.21          # Updated
PORTAINER_VERSION=2.21.2      # Updated
STRELKA_VERSION=0.24.11.15    # Updated
```

### Example 3: Development/Testing Setup

Smaller, faster deployment for testing:

**Edit `default.env`:**
```bash
APPS_TO_INSTALL=(
portainer
elk
risx-mssp
)

# Use smaller/faster versions
NGINX_VERSION=1.27-alpine     # Latest alpine (smaller)
```

## Step-by-Step Workflow

### Before Downloading (Online System)

1. **Review current versions**:
   ```bash
   cat setup_platform/resources/default.env | grep -A 50 "Containers versions"
   ```

2. **Edit default.env**:
   ```bash
   nano setup_platform/resources/default.env
   # Modify APPS_TO_INSTALL and version numbers
   ```

3. **Edit download script**:
   ```bash
   nano setup_platform/scripts/air-gapped/1-download-for-airgap.sh
   # Comment out unwanted pull_and_save_image lines
   ```

4. **Verify changes**:
   ```bash
   # Check which apps will be installed
   grep -A 15 "APPS_TO_INSTALL=" setup_platform/resources/default.env

   # Check versions
   grep "_VERSION=" setup_platform/resources/default.env | grep -v "^#"
   ```

5. **Run download**:
   ```bash
   cd setup_platform/scripts/air-gapped
   ./1-download-for-airgap.sh
   ```

### After Transfer (Air-Gapped System)

The same `default.env` should be used on the air-gapped system. Either:

**Option A**: Transfer the modified `default.env` with the repository

**Option B**: Make the same changes on the air-gapped system before deployment:
```bash
# On air-gapped system
nano /path/to/Risx-MSSP/setup_platform/resources/default.env
# Make same modifications as online system
```

## Finding Available Versions

### For Docker Images

**Check Docker Hub:**
```bash
# Example: Check available nginx versions
curl -s https://registry.hub.docker.com/v2/repositories/library/nginx/tags/ | jq -r '.results[].name' | head -20
```

**Check GitHub Container Registry:**
```bash
# Example: Check IRIS versions
curl -s https://api.github.com/repos/dfir-iris/iris-web/releases | jq -r '.[].tag_name' | head -10
```

**Check GitHub Releases:**
- Velociraptor: https://github.com/Velocidex/velociraptor/releases
- Strelka: https://github.com/target/strelka/releases
- MISP: https://github.com/MISP/misp-docker/releases

### For System Components

**Velociraptor Artifacts:**
- Default: https://github.com/10RootOrg/Velociraptor-Artifacts
- Change `VELOCIRAPTOR_ARTIFACTS_URL` in default.env

**YARA Rules:**
- Default: YARA Forge release 20240922
- Change `GITHUB_COMMIT_YARAHQ` in `strelka.sh` or default.env

## Advanced: Component-Specific Customization

### Completely Skip a Component

If you want to completely skip a component including all its dependencies:

**Example: Skip Prowler completely**

1. Remove from `APPS_TO_INSTALL` in `default.env`
2. In `1-download-for-airgap.sh`, comment out:
   ```bash
   # Prowler
   #pull_and_save_image "prowlercloud/prowler-api:${PROWLER_API_VERSION:-stable}"
   #pull_and_save_image "prowlercloud/prowler-ui:${PROWLER_UI_VERSION:-latest}"
   #pull_and_save_image "postgres:${PROWLER_POSTGRES_VERSION:-16.3-alpine3.20}"
   #pull_and_save_image "valkey/valkey:${PROWLER_VALKEY_VERSION:-7-alpine3.19}"
   ```

### Use Custom Docker Registry

If you have internal mirrors:

**Edit `1-download-for-airgap.sh`:**
```bash
# Example: Use internal registry for IRIS
# Change from:
pull_and_save_image "ghcr.io/dfir-iris/iriswebapp_db:${IRIS_VERSION:-v2.4.20}"

# To:
pull_and_save_image "internal-registry.company.com/dfir-iris/iriswebapp_db:${IRIS_VERSION:-v2.4.20}"
```

### Download Multiple Versions

To have flexibility on air-gapped system:

```bash
# Download both stable and specific version
pull_and_save_image "prowlercloud/prowler-api:stable"
pull_and_save_image "prowlercloud/prowler-api:4.3.5"
pull_and_save_image "prowlercloud/prowler-api:4.4.0"
```

Then on air-gapped system, choose which to use in `default.env`.

## Validation

After customizing, validate before downloading:

```bash
# Check syntax
bash -n setup_platform/resources/default.env

# Check which apps will be installed
source setup_platform/resources/default.env
echo "Apps to install: ${APPS_TO_INSTALL[@]}"

# Check versions
env | grep _VERSION | sort
```

## Troubleshooting Customization

### Issue: "Image not found"

**Cause**: Typo in version number or version doesn't exist

**Solution**:
```bash
# Verify the image exists
docker pull <image>:<version>
# If it works, the version is valid
```

### Issue: Deployment fails for disabled component

**Cause**: Component removed from download but still in APPS_TO_INSTALL

**Solution**: Ensure both are consistent (removed from both places)

### Issue: Version mismatch errors

**Cause**: Incompatible versions between related components

**Solution**:
- Keep ELK stack versions identical (Elasticsearch, Logstash, Kibana)
- Check component compatibility matrix in their documentation

## Pre-Configured Profiles

I can create several pre-configured profiles. Here's where you'd define them:

### Profile 1: Full Stack (Default)
```bash
# All components, current stable versions
# Use: default.env as-is
```

### Profile 2: Security Only
```bash
# Edit default.env
APPS_TO_INSTALL=(
portainer
velociraptor
iris-web
elk
risx-mssp
)
```

### Profile 3: Minimal
```bash
# Edit default.env
APPS_TO_INSTALL=(
portainer
elk
risx-mssp
)
```

You can create separate env files:
```bash
cp default.env default.env.full
cp default.env default.env.security
cp default.env default.env.minimal

# Edit each as needed
# Then use: source default.env.security before download
```

## Summary Checklist

- [ ] Review `default.env` APPS_TO_INSTALL array
- [ ] Remove unwanted apps from the array
- [ ] Update version numbers as needed
- [ ] Comment out unwanted images in `1-download-for-airgap.sh`
- [ ] Verify changes with bash -n
- [ ] Run download script
- [ ] Transfer same `default.env` to air-gapped system
- [ ] Verify on air-gapped system before deployment

## Quick Reference

| What to Change | File | Line/Section |
|----------------|------|--------------|
| Apps to install | `default.env` | Line ~27, APPS_TO_INSTALL |
| Component versions | `default.env` | Line ~106, Container versions |
| Skip image downloads | `1-download-for-airgap.sh` | Line ~150+, comment out pull_and_save_image |
| Artifact URLs | `default.env` | Line ~58, VELOCIRAPTOR_ARTIFACTS_URL |
| YARA version | `default.env` or `strelka.sh` | GITHUB_COMMIT_YARAHQ |

---

**Need help customizing? Check which images you need and I can help create a custom configuration!**
