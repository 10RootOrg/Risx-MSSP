#!/usr/bin/env python3
"""
SBOM Update Script for Risx-MSSP Platform

This script automatically generates and updates the Software Bill of Materials (SBOM)
by scanning child repositories, configuration files, and installation scripts.

Usage:
    python update_sbom.py [--output-dir DIR]
"""

import json
import os
import re
import subprocess
import tempfile
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import argparse

# Child repositories to scan
CHILD_REPOS = [
    {
        "name": "risx-mssp-python",
        "url": "https://github.com/10RootOrg/risx-mssp-python",
        "type": "python"
    },
    {
        "name": "risx-mssp-back",
        "url": "https://github.com/10RootOrg/risx-mssp-back",
        "type": "nodejs"
    },
    {
        "name": "risx-mssp-front",
        "url": "https://github.com/10RootOrg/risx-mssp-front",
        "type": "nodejs"
    }
]

# External repositories cloned during installation
EXTERNAL_REPOS = [
    {
        "name": "docker-elk",
        "source": "deviantony/docker-elk",
        "version": "commit 629aea49",
        "purpose": "ELK stack docker configuration"
    },
    {
        "name": "iris-web",
        "source": "dfir-iris/iris-web",
        "version": "v2.4.10",
        "purpose": "DFIR-IRIS incident response platform"
    }
]

# External data sources
EXTERNAL_DATA_SOURCES = [
    {
        "name": "YARA Forge Rules",
        "url": "yara-forge/yara-forge-rules",
        "version": "20240922",
        "purpose": "YARA rules for Strelka file analysis"
    },
    {
        "name": "Velociraptor Artifacts",
        "url": "10RootOrg/Velociraptor-Artifacts",
        "version": "main",
        "purpose": "Custom Velociraptor artifact definitions"
    },
    {
        "name": "DFIQ",
        "url": "google/dfiq",
        "version": "main",
        "purpose": "Digital Forensics Investigation Questions"
    },
    {
        "name": "AllthingsTimesketch Tags",
        "url": "blueteam0ps/AllthingsTimesketch",
        "version": "latest",
        "purpose": "Timesketch tag configurations"
    },
    {
        "name": "YARA Rules (Bartblaze)",
        "url": "bartblaze/YARA-rules",
        "version": "main",
        "purpose": "Additional YARA rules for Strelka"
    }
]

# Python package descriptions
PYTHON_PACKAGE_PURPOSES = {
    "altair": "Data visualization",
    "attrs": "Classes without boilerplate",
    "beautifulsoup4": "HTML/XML parsing",
    "cachetools": "Caching utilities",
    "certifi": "SSL certificates",
    "cffi": "C Foreign Function Interface",
    "charset-normalizer": "Character encoding detection",
    "click": "CLI creation toolkit",
    "click-plugins": "Click plugins extension",
    "colorama": "Cross-platform colored terminal",
    "cryptography": "Cryptographic recipes",
    "elastic-transport": "Elasticsearch transport",
    "elasticsearch": "Elasticsearch client",
    "filelock": "File locking",
    "google-auth": "Google authentication",
    "google-auth-oauthlib": "Google OAuth library",
    "grpcio": "gRPC framework",
    "grpcio-tools": "gRPC tools",
    "idna": "Internationalized domain names",
    "Jinja2": "Template engine",
    "jsonschema": "JSON schema validation",
    "jsonschema-specifications": "JSON schema specs",
    "MarkupSafe": "Safe string markup",
    "mysql-connector-python": "MySQL database connector",
    "narwhals": "DataFrame library adapter",
    "networkx": "Graph/network analysis",
    "numpy": "Numerical computing",
    "oauthlib": "OAuth library",
    "packaging": "Python packaging utilities",
    "pandas": "Data analysis library",
    "protobuf": "Protocol buffers",
    "psutil": "Process utilities",
    "pyasn1": "ASN.1 library",
    "pyasn1_modules": "ASN.1 modules",
    "pycparser": "C parser",
    "python-dateutil": "Date utilities",
    "pytz": "Timezone definitions",
    "pyvelociraptor": "Velociraptor API client",
    "PyYAML": "YAML parser",
    "referencing": "JSON reference resolution",
    "requests": "HTTP library",
    "requests-file": "File transport for requests",
    "requests-oauthlib": "OAuth for requests",
    "rpds-py": "Persistent data structures",
    "rsa": "RSA implementation",
    "shodan": "Shodan API client",
    "six": "Python 2/3 compatibility",
    "soupsieve": "CSS selectors for BS4",
    "timesketch-api-client": "Timesketch API client",
    "timesketch-import-client": "Timesketch import client",
    "tldextract": "TLD extraction",
    "typing_extensions": "Typing backports",
    "tzdata": "Timezone data",
    "urllib3": "HTTP client",
    "xlrd": "Excel file reading",
    "XlsxWriter": "Excel file writing",
    "leakcheck": "Leak checking API",
    "json_repair": "JSON repair utility",
    "openai": "OpenAI API client"
}

# Node.js package descriptions
NPM_PACKAGE_PURPOSES = {
    "ajv": "JSON schema validator",
    "axios": "HTTP client",
    "bcrypt": "Password hashing",
    "body-parser": "Request body parsing",
    "cors": "Cross-origin resource sharing",
    "csv-parser": "CSV parsing",
    "csv-writer": "CSV writing",
    "dotenv": "Environment variables",
    "express": "Web framework",
    "knex": "SQL query builder",
    "multer": "File upload handling",
    "mysql": "MySQL client",
    "mysql2": "MySQL client (improved)",
    "pg": "PostgreSQL client",
    "uuid": "UUID generation",
    "xml2js": "XML to JS conversion",
    "@types/pg": "PostgreSQL TypeScript types",
    "@codemirror/lang-json": "JSON language support",
    "@lezer/highlight": "Syntax highlighting",
    "@testing-library/jest-dom": "DOM testing utilities",
    "@testing-library/react": "React testing utilities",
    "@testing-library/user-event": "User event simulation",
    "@uiw/codemirror-theme-vscode": "VSCode theme for CodeMirror",
    "@uiw/codemirror-themes": "CodeMirror themes",
    "@uiw/react-codemirror": "React CodeMirror component",
    "@uiw/react-json-view": "JSON viewer component",
    "chart.js": "Charting library",
    "lottie-web": "Lottie animations",
    "path": "Path utilities",
    "react": "React framework",
    "react-chartjs-2": "React Chart.js wrapper",
    "react-dom": "React DOM",
    "react-json-view-preview": "JSON preview component",
    "react-scripts": "Create React App scripts",
    "react-svg": "SVG component",
    "web-vitals": "Web performance metrics",
    "@babel/plugin-proposal-private-property-in-object": "Babel plugin",
    "cross-env": "Cross-platform env vars",
    "react-router-dom": "React routing"
}


class SBOMGenerator:
    def __init__(self, project_root: Path, output_dir: Path):
        self.project_root = project_root
        self.output_dir = output_dir
        self.temp_dir = None
        self.components = []
        self.env_vars = {}

    def run(self):
        """Main entry point to generate SBOM."""
        print("Starting SBOM generation...")

        # Create temp directory for cloning repos
        self.temp_dir = Path(tempfile.mkdtemp(prefix="sbom-"))

        try:
            # Load environment variables from default.env
            self._load_env_vars()

            # Clone and scan child repositories
            self._scan_child_repos()

            # Scan container images
            self._scan_containers()

            # Add external repositories
            self._add_external_repos()

            # Add external data sources
            self._add_external_data_sources()

            # Generate outputs
            self._generate_sbom_json()
            self._generate_sbom_md()

            print(f"\nSBOM generation complete!")
            print(f"  - {self.output_dir / 'sbom.json'}")
            print(f"  - {self.output_dir / 'SBOM.md'}")
            print(f"  - Total components: {len(self.components)}")

        finally:
            # Cleanup temp directory
            if self.temp_dir and self.temp_dir.exists():
                shutil.rmtree(self.temp_dir)

    def _load_env_vars(self):
        """Load environment variables from default.env."""
        env_file = self.project_root / "setup_platform" / "resources" / "default.env"
        if env_file.exists():
            print(f"Loading environment variables from {env_file}")
            with open(env_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        self.env_vars[key.strip()] = value.strip().strip('"\'')
        else:
            print(f"Warning: {env_file} not found")

    def _clone_repo(self, url: str, name: str) -> Optional[Path]:
        """Clone a git repository to temp directory."""
        target = self.temp_dir / name
        print(f"Cloning {url}...")
        try:
            result = subprocess.run(
                ["git", "clone", "--depth", "1", url, str(target)],
                capture_output=True,
                text=True,
                timeout=120
            )
            if result.returncode == 0:
                return target
            else:
                print(f"  Warning: Failed to clone {url}: {result.stderr}")
                return None
        except subprocess.TimeoutExpired:
            print(f"  Warning: Timeout cloning {url}")
            return None
        except Exception as e:
            print(f"  Warning: Error cloning {url}: {e}")
            return None

    def _scan_child_repos(self):
        """Clone and scan child repositories for dependencies."""
        for repo in CHILD_REPOS:
            repo_path = self._clone_repo(repo["url"], repo["name"])
            if repo_path:
                if repo["type"] == "python":
                    self._scan_python_deps(repo_path, repo["name"])
                elif repo["type"] == "nodejs":
                    self._scan_nodejs_deps(repo_path, repo["name"])

    def _scan_python_deps(self, repo_path: Path, repo_name: str):
        """Scan Python requirements.txt for dependencies."""
        req_file = repo_path / "requirements.txt"
        if not req_file.exists():
            print(f"  Warning: No requirements.txt found in {repo_name}")
            return

        print(f"  Scanning Python dependencies in {repo_name}...")
        with open(req_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and not line.startswith('-'):
                    # Parse package==version or package>=version etc.
                    match = re.match(r'^([a-zA-Z0-9_-]+)([<>=!]+)?(.+)?$', line)
                    if match:
                        name = match.group(1)
                        version = match.group(3) if match.group(3) else "latest"

                        self.components.append({
                            "type": "library",
                            "bom-ref": f"pkg:pypi/{name.lower()}@{version}",
                            "name": name,
                            "version": version,
                            "purl": f"pkg:pypi/{name.lower()}@{version}",
                            "scope": "required",
                            "group": repo_name,
                            "description": PYTHON_PACKAGE_PURPOSES.get(name, "Python package")
                        })

    def _scan_nodejs_deps(self, repo_path: Path, repo_name: str):
        """Scan package.json for Node.js dependencies."""
        pkg_file = repo_path / "package.json"
        if not pkg_file.exists():
            print(f"  Warning: No package.json found in {repo_name}")
            return

        print(f"  Scanning Node.js dependencies in {repo_name}...")
        with open(pkg_file, 'r') as f:
            pkg_data = json.load(f)

        # Scan both dependencies and devDependencies
        for dep_type in ["dependencies", "devDependencies"]:
            deps = pkg_data.get(dep_type, {})
            for name, version in deps.items():
                # Clean up version string
                clean_version = version.lstrip('^~>=<')

                self.components.append({
                    "type": "library",
                    "bom-ref": f"pkg:npm/{name}@{clean_version}",
                    "name": name,
                    "version": version,
                    "purl": f"pkg:npm/{name}@{clean_version}",
                    "scope": "required" if dep_type == "dependencies" else "optional",
                    "group": repo_name,
                    "description": NPM_PACKAGE_PURPOSES.get(name, "Node.js package")
                })

    def _scan_containers(self):
        """Scan for container images from docker-compose files and env vars."""
        print("Scanning container images...")

        # Container definitions with version mappings
        containers = [
            # Core Platform
            {"name": "nginx", "image": "nginx", "version_key": "NGINX_VERSION", "default": "1.19.3-alpine", "group": "Core Platform", "description": "Reverse proxy"},
            {"name": "risx-mssp-backend", "image": "custom build", "version": "-", "group": "Core Platform", "description": "Backend API container"},
            {"name": "risx-mssp-frontend", "image": "custom build", "version": "-", "group": "Core Platform", "description": "Frontend UI container"},
            {"name": "mysql", "image": "custom build", "version": "-", "group": "Core Platform", "description": "Database server"},

            # ELK Stack
            {"name": "elasticsearch", "image": "docker.elastic.co/elasticsearch/elasticsearch", "version_key": "ELASTIC_VERSION", "default": "8.15.3", "group": "ELK Stack", "description": "Search engine"},
            {"name": "logstash", "image": "docker.elastic.co/logstash/logstash", "version_key": "ELASTIC_VERSION", "default": "8.15.3", "group": "ELK Stack", "description": "Data processing"},
            {"name": "kibana", "image": "docker.elastic.co/kibana/kibana", "version_key": "ELASTIC_VERSION", "default": "8.15.3", "group": "ELK Stack", "description": "Visualization"},

            # Timesketch
            {"name": "timesketch-web", "image": "us-docker.pkg.dev/osdfir-registry/timesketch/timesketch", "version_key": "TIMESKETCH_VERSION", "default": "20250708", "group": "Timesketch", "description": "Timeline analysis"},
            {"name": "timesketch-worker", "image": "us-docker.pkg.dev/osdfir-registry/timesketch/timesketch", "version_key": "TIMESKETCH_VERSION", "default": "20250708", "group": "Timesketch", "description": "Background workers"},
            {"name": "timesketch-postgres", "image": "postgres", "version_key": "POSTGRES_VERSION", "default": "15.6-alpine", "group": "Timesketch", "description": "Database"},
            {"name": "opensearch", "image": "opensearchproject/opensearch", "version_key": "OPENSEARCH_VERSION", "default": "2.17.0", "group": "Timesketch", "description": "Search backend"},
            {"name": "timesketch-redis", "image": "redis", "version_key": "REDIS_VERSION", "default": "7.2-alpine", "group": "Timesketch", "description": "Caching"},

            # Prowler
            {"name": "prowler-api", "image": "prowlercloud/prowler-api", "version_key": "PROWLER_API_VERSION", "default": "stable", "group": "Prowler", "description": "Security assessment API"},
            {"name": "prowler-ui", "image": "prowlercloud/prowler-ui", "version_key": "PROWLER_UI_VERSION", "default": "latest", "group": "Prowler", "description": "Security assessment UI"},
            {"name": "prowler-postgres", "image": "postgres", "version": "16.3-alpine3.20", "group": "Prowler", "description": "Database"},
            {"name": "prowler-valkey", "image": "valkey/valkey", "version": "7-alpine3.19", "group": "Prowler", "description": "Cache"},
            {"name": "glow", "image": "ghcr.io/charmbracelet/glow", "version": "v2.0", "group": "Prowler", "description": "README renderer utility"},

            # MISP
            {"name": "misp-core", "image": "ghcr.io/misp/misp-docker/misp-core", "version": "latest", "group": "MISP", "description": "MISP core platform"},
            {"name": "misp-modules", "image": "ghcr.io/misp/misp-docker/misp-modules", "version": "latest", "group": "MISP", "description": "MISP enrichment modules"},
            {"name": "misp-mariadb", "image": "mariadb", "version": "10.11", "group": "MISP", "description": "Database"},
            {"name": "misp-valkey", "image": "valkey/valkey", "version": "7.2", "group": "MISP", "description": "Cache"},
            {"name": "misp-smtp", "image": "ixdotai/smtp", "version": "latest", "group": "MISP", "description": "Email relay"},

            # Strelka
            {"name": "strelka-frontend", "image": "target/strelka-frontend", "version_key": "STRELKA_VERSION", "default": "0.24.07.09", "group": "Strelka", "description": "File submission"},
            {"name": "strelka-backend", "image": "target/strelka-backend", "version_key": "STRELKA_VERSION", "default": "0.24.07.09", "group": "Strelka", "description": "File analysis"},
            {"name": "strelka-manager", "image": "target/strelka-manager", "version_key": "STRELKA_VERSION", "default": "0.24.07.09", "group": "Strelka", "description": "Coordination"},
            {"name": "strelka-ui", "image": "target/strelka-ui", "version": "v2.13", "group": "Strelka", "description": "Web interface"},
            {"name": "strelka-redis", "image": "redis", "version": "7.4.0-alpine3.20", "group": "Strelka", "description": "Coordination/Gatekeeper"},
            {"name": "jaeger", "image": "jaegertracing/all-in-one", "version": "1.42", "group": "Strelka", "description": "Distributed tracing"},
            {"name": "strelka-postgresql", "image": "bitnami/postgresql", "version": "11", "group": "Strelka", "description": "Database"},

            # DFIR-IRIS
            {"name": "iriswebapp_app", "image": "ghcr.io/dfir-iris/iriswebapp_app", "version_key": "IRIS_VERSION", "default": "v2.4.20", "group": "DFIR-IRIS", "description": "IR platform"},
            {"name": "iriswebapp_db", "image": "ghcr.io/dfir-iris/iriswebapp_db", "version_key": "IRIS_VERSION", "default": "v2.4.20", "group": "DFIR-IRIS", "description": "Database"},
            {"name": "iriswebapp_nginx", "image": "ghcr.io/dfir-iris/iriswebapp_nginx", "version_key": "IRIS_VERSION", "default": "v2.4.20", "group": "DFIR-IRIS", "description": "Web server"},
            {"name": "rabbitmq", "image": "rabbitmq", "version": "3-management-alpine", "group": "DFIR-IRIS", "description": "Message queue"},

            # Other Tools
            {"name": "cyberchef", "image": "ghcr.io/gchq/cyberchef", "version_key": "CYBERCHEF_IMAGE_TAG", "default": "10.19", "group": "Other Tools", "description": "Data manipulation"},
            {"name": "velociraptor", "image": "custom build", "version_key": "VELOCIRAPTOR_VERSION", "default": "v0.74", "group": "Other Tools", "description": "Endpoint visibility"},
            {"name": "nightingale", "image": "ghcr.io/rajanagori/nightingale", "version_key": "NIGHTINGALE_IMAGE_TAG", "default": "v1.0.0", "group": "Other Tools", "description": "Security testing"},
            {"name": "portainer", "image": "portainer/portainer-ce", "version_key": "PORTAINER_VERSION", "default": "2.21.0", "group": "Other Tools", "description": "Container management"},
            {"name": "portainer-agent", "image": "portainer/agent", "version_key": "PORTAINER_VERSION", "default": "2.21.0", "group": "Other Tools", "description": "Portainer agent"},
        ]

        for container in containers:
            # Get version from env vars or use default/specified
            if "version_key" in container:
                version = self.env_vars.get(container["version_key"], container.get("default", "latest"))
            else:
                version = container.get("version", "latest")

            self.components.append({
                "type": "container",
                "bom-ref": f"pkg:docker/{container['name']}@{version}",
                "name": container["name"],
                "version": version,
                "purl": f"pkg:docker/{container['image'].replace('/', '%2F')}@{version}",
                "group": container["group"],
                "description": container["description"],
                "properties": [
                    {"name": "image", "value": container["image"]}
                ]
            })

    def _add_external_repos(self):
        """Add external repositories that are cloned during installation."""
        print("Adding external repositories...")
        for repo in EXTERNAL_REPOS:
            self.components.append({
                "type": "library",
                "bom-ref": f"pkg:github/{repo['source']}@{repo['version']}",
                "name": repo["name"],
                "version": repo["version"],
                "purl": f"pkg:github/{repo['source']}@{repo['version']}",
                "group": "External Repositories",
                "description": repo["purpose"]
            })

    def _add_external_data_sources(self):
        """Add external data sources."""
        print("Adding external data sources...")
        for source in EXTERNAL_DATA_SOURCES:
            self.components.append({
                "type": "data",
                "bom-ref": f"pkg:generic/{source['name'].lower().replace(' ', '-')}@{source['version']}",
                "name": source["name"],
                "version": source["version"],
                "group": "External Data Sources",
                "description": source["purpose"],
                "properties": [
                    {"name": "url", "value": source["url"]}
                ]
            })

    def _generate_sbom_json(self):
        """Generate CycloneDX 1.5 format SBOM JSON."""
        print("Generating sbom.json...")

        sbom = {
            "$schema": "http://cyclonedx.org/schema/bom-1.5.schema.json",
            "bomFormat": "CycloneDX",
            "specVersion": "1.5",
            "serialNumber": f"urn:uuid:{self._generate_uuid()}",
            "version": 1,
            "metadata": {
                "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
                "tools": [
                    {
                        "vendor": "10Root",
                        "name": "risx-mssp-sbom-generator",
                        "version": "1.0.0"
                    }
                ],
                "component": {
                    "type": "application",
                    "bom-ref": "risx-mssp",
                    "name": "Risx-MSSP",
                    "version": "1.0.0",
                    "description": "Managed Security Service Provider Platform",
                    "licenses": [
                        {
                            "license": {
                                "id": "GPL-3.0-or-later"
                            }
                        }
                    ],
                    "externalReferences": [
                        {
                            "type": "website",
                            "url": "https://github.com/10RootOrg/Risx-MSSP"
                        },
                        {
                            "type": "vcs",
                            "url": "https://github.com/10RootOrg/Risx-MSSP.git"
                        }
                    ]
                }
            },
            "components": self.components
        }

        output_file = self.output_dir / "sbom.json"
        with open(output_file, 'w') as f:
            json.dump(sbom, f, indent=2)

    def _generate_sbom_md(self):
        """Generate human-readable SBOM markdown."""
        print("Generating SBOM.md...")

        # Count components by type
        python_deps = [c for c in self.components if c.get("group") == "risx-mssp-python"]
        backend_deps = [c for c in self.components if c.get("group") == "risx-mssp-back"]
        frontend_deps = [c for c in self.components if c.get("group") == "risx-mssp-front"]
        containers = [c for c in self.components if c.get("type") == "container"]
        external_repos = [c for c in self.components if c.get("group") == "External Repositories"]
        data_sources = [c for c in self.components if c.get("group") == "External Data Sources"]

        md = f"""# Software Bill of Materials (SBOM)

## Risx-MSSP Platform

**Generated:** {datetime.now().strftime("%Y-%m-%d")}
**Format:** CycloneDX 1.5
**License:** GPL-3.0-or-later

---

## Overview

The Risx-MSSP platform is a comprehensive Managed Security Service Provider (MSSP) solution that integrates multiple security tools for incident response, threat intelligence, and security operations.

### Component Summary

| Category | Count |
|----------|-------|
| Python Dependencies | {len(python_deps)} |
| Node.js Backend Dependencies | {len(backend_deps)} |
| Node.js Frontend Dependencies | {len(frontend_deps)} |
| Container Images | {len(containers)} |
| External Repositories | {len(external_repos)} |
| External Data Sources | {len(data_sources)} |
| **Total Components** | **{len(self.components)}** |

---

## Child Repositories

### 1. risx-mssp-python
- **URL:** https://github.com/10RootOrg/risx-mssp-python
- **Type:** Python Scripts and Modules
- **Dependencies:** {len(python_deps)} packages

### 2. risx-mssp-back
- **URL:** https://github.com/10RootOrg/risx-mssp-back
- **Type:** Node.js/Express Backend API
- **Dependencies:** {len(backend_deps)} packages

### 3. risx-mssp-front
- **URL:** https://github.com/10RootOrg/risx-mssp-front
- **Type:** React Frontend Application
- **Dependencies:** {len(frontend_deps)} packages

---

## Python Dependencies (risx-mssp-python)

| Package | Version | Purpose |
|---------|---------|---------|
"""
        for dep in sorted(python_deps, key=lambda x: x["name"].lower()):
            md += f"| {dep['name']} | {dep['version']} | {dep['description']} |\n"

        md += """
---

## Node.js Backend Dependencies (risx-mssp-back)

| Package | Version | Purpose |
|---------|---------|---------|
"""
        for dep in sorted(backend_deps, key=lambda x: x["name"].lower()):
            scope = "Production" if dep.get("scope") == "required" else "Dev"
            md += f"| {dep['name']} | {dep['version']} | {dep['description']} |\n"

        md += """
---

## Node.js Frontend Dependencies (risx-mssp-front)

| Package | Version | Purpose |
|---------|---------|---------|
"""
        for dep in sorted(frontend_deps, key=lambda x: x["name"].lower()):
            md += f"| {dep['name']} | {dep['version']} | {dep['description']} |\n"

        md += """
---

## Container Images (Infrastructure)

"""
        # Group containers by their group
        container_groups = {}
        for c in containers:
            group = c.get("group", "Other")
            if group not in container_groups:
                container_groups[group] = []
            container_groups[group].append(c)

        group_order = ["Core Platform", "ELK Stack", "Timesketch", "Prowler", "MISP", "Strelka", "DFIR-IRIS", "Other Tools"]
        for group in group_order:
            if group in container_groups:
                md += f"### {group}\n\n"
                md += "| Service | Image | Version | Description |\n"
                md += "|---------|-------|---------|-------------|\n"
                for c in container_groups[group]:
                    image = next((p["value"] for p in c.get("properties", []) if p["name"] == "image"), c["name"])
                    md += f"| {c['name']} | {image} | {c['version']} | {c['description']} |\n"
                md += "\n"

        md += """---

## External Repositories (Cloned During Installation)

| Repository | Source | Version/Commit | Purpose |
|------------|--------|----------------|---------|
"""
        for repo in external_repos:
            source = repo["purl"].replace("pkg:github/", "").split("@")[0]
            md += f"| {repo['name']} | {source} | {repo['version']} | {repo['description']} |\n"

        md += """
---

## External Data Sources

| Source | URL | Version | Purpose |
|--------|-----|---------|---------|
"""
        for source in data_sources:
            url = next((p["value"] for p in source.get("properties", []) if p["name"] == "url"), "")
            md += f"| {source['name']} | {url} | {source['version']} | {source['description']} |\n"

        md += """
---

## Security Considerations

### Known Security-Sensitive Dependencies

1. **cryptography** - Handles cryptographic operations
2. **bcrypt** - Password hashing
3. **requests** - HTTP client - ensure proper certificate validation
4. **openai** - External API integration - secure API key handling required

### Recommendations

1. Regularly update dependencies to patch security vulnerabilities
2. Use tools like `npm audit`, `pip-audit`, or Snyk for vulnerability scanning
3. Pin Docker image versions in production
4. Review and monitor CVE databases for known vulnerabilities

---

## Files

- **sbom.json** - Machine-readable CycloneDX 1.5 format SBOM
- **SBOM.md** - This human-readable summary
- **update_sbom.py** - Script to regenerate this SBOM

---

## References

- [CycloneDX Specification](https://cyclonedx.org/specification/overview/)
- [SPDX License List](https://spdx.org/licenses/)
- [Package URL (purl) Specification](https://github.com/package-url/purl-spec)
"""

        output_file = self.output_dir / "SBOM.md"
        with open(output_file, 'w') as f:
            f.write(md)

    def _generate_uuid(self) -> str:
        """Generate a UUID v4."""
        import random
        return '{:08x}-{:04x}-4{:03x}-{:04x}-{:012x}'.format(
            random.getrandbits(32),
            random.getrandbits(16),
            random.getrandbits(12),
            random.getrandbits(16) & 0x3fff | 0x8000,
            random.getrandbits(48)
        )


def main():
    parser = argparse.ArgumentParser(description="Generate SBOM for Risx-MSSP platform")
    parser.add_argument("--output-dir", "-o", type=str, help="Output directory for SBOM files")
    args = parser.parse_args()

    # Determine paths
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent
    output_dir = Path(args.output_dir) if args.output_dir else script_dir

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate SBOM
    generator = SBOMGenerator(project_root, output_dir)
    generator.run()


if __name__ == "__main__":
    main()
