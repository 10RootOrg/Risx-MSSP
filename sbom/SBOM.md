# Software Bill of Materials (SBOM)

## Risx-MSSP Platform

**Generated:** 2025-11-26
**Format:** CycloneDX 1.5
**License:** GPL-3.0-or-later

---

## Overview

The Risx-MSSP platform is a comprehensive Managed Security Service Provider (MSSP) solution that integrates multiple security tools for incident response, threat intelligence, and security operations.

### Component Summary

| Category | Count |
|----------|-------|
| Python Dependencies | 59 |
| Node.js Backend Dependencies | 17 |
| Node.js Frontend Dependencies | 24 |
| Container Images | 35 |
| External Repositories | 2 |
| External Data Sources | 5 |
| **Total Components** | **142** |

---

## Child Repositories

### 1. risx-mssp-python
- **URL:** https://github.com/10RootOrg/risx-mssp-python
- **Type:** Python Scripts and Modules
- **Dependencies:** 59 packages

### 2. risx-mssp-back
- **URL:** https://github.com/10RootOrg/risx-mssp-back
- **Type:** Node.js/Express Backend API
- **Version:** 1.0.0
- **Dependencies:** 17 packages

### 3. risx-mssp-front
- **URL:** https://github.com/10RootOrg/risx-mssp-front
- **Type:** React Frontend Application
- **Version:** 0.1.0
- **Dependencies:** 24 packages

---

## Python Dependencies (risx-mssp-python)

| Package | Version | Purpose |
|---------|---------|---------|
| altair | 5.4.1 | Data visualization |
| attrs | 24.2.0 | Classes without boilerplate |
| beautifulsoup4 | 4.12.3 | HTML/XML parsing |
| cachetools | 5.5.0 | Caching utilities |
| certifi | 2024.8.30 | SSL certificates |
| cffi | 1.17.1 | C Foreign Function Interface |
| charset-normalizer | 3.3.2 | Character encoding detection |
| click | 8.1.7 | CLI creation toolkit |
| click-plugins | 1.1.1 | Click plugins extension |
| colorama | 0.4.6 | Cross-platform colored terminal |
| cryptography | 43.0.1 | Cryptographic recipes |
| elastic-transport | 8.15.0 | Elasticsearch transport |
| elasticsearch | 8.15.1 | Elasticsearch client |
| filelock | 3.16.1 | File locking |
| google-auth | 2.35.0 | Google authentication |
| google-auth-oauthlib | 1.2.1 | Google OAuth library |
| grpcio | 1.66.1 | gRPC framework |
| grpcio-tools | 1.66.1 | gRPC tools |
| idna | 3.10 | Internationalized domain names |
| Jinja2 | 3.1.4 | Template engine |
| jsonschema | 4.23.0 | JSON schema validation |
| jsonschema-specifications | 2023.12.1 | JSON schema specs |
| MarkupSafe | 2.1.5 | Safe string markup |
| mysql-connector-python | 9.0.0 | MySQL database connector |
| narwhals | 1.8.2 | DataFrame library adapter |
| networkx | 3.3 | Graph/network analysis |
| numpy | 2.1.1 | Numerical computing |
| oauthlib | 3.2.2 | OAuth library |
| packaging | 24.1 | Python packaging utilities |
| pandas | 2.2.3 | Data analysis library |
| protobuf | 5.28.2 | Protocol buffers |
| psutil | 6.0.0 | Process utilities |
| pyasn1 | 0.6.1 | ASN.1 library |
| pyasn1_modules | 0.4.1 | ASN.1 modules |
| pycparser | 2.22 | C parser |
| python-dateutil | 2.9.0.post0 | Date utilities |
| pytz | 2024.2 | Timezone definitions |
| pyvelociraptor | 0.1.8 | Velociraptor API client |
| PyYAML | 6.0.2 | YAML parser |
| referencing | 0.35.1 | JSON reference resolution |
| requests | 2.32.3 | HTTP library |
| requests-file | 2.1.0 | File transport for requests |
| requests-oauthlib | 2.0.0 | OAuth for requests |
| rpds-py | 0.20.0 | Persistent data structures |
| rsa | 4.9 | RSA implementation |
| shodan | 1.31.0 | Shodan API client |
| six | 1.16.0 | Python 2/3 compatibility |
| soupsieve | 2.6 | CSS selectors for BS4 |
| timesketch-api-client | 20240828 | Timesketch API client |
| timesketch-import-client | 20230721 | Timesketch import client |
| tldextract | 5.1.2 | TLD extraction |
| typing_extensions | 4.12.2 | Typing backports |
| tzdata | 2024.1 | Timezone data |
| urllib3 | 2.2.3 | HTTP client |
| xlrd | 2.0.1 | Excel file reading |
| XlsxWriter | 3.2.0 | Excel file writing |
| leakcheck | 2.0.0 | Leak checking API |
| json_repair | 0.40.0 | JSON repair utility |
| openai | latest | OpenAI API client |

---

## Node.js Backend Dependencies (risx-mssp-back)

### Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| ajv | ^8.12.0 | JSON schema validator |
| axios | ^1.7.2 | HTTP client |
| bcrypt | ^5.1.1 | Password hashing |
| body-parser | ^1.20.2 | Request body parsing |
| cors | ^2.8.5 | Cross-origin resource sharing |
| csv-parser | ^3.0.0 | CSV parsing |
| csv-writer | ^1.6.0 | CSV writing |
| dotenv | ^16.4.5 | Environment variables |
| express | ^4.19.1 | Web framework |
| knex | ^3.1.0 | SQL query builder |
| multer | ^1.4.5-lts.1 | File upload handling |
| mysql | ^2.18.1 | MySQL client |
| mysql2 | ^3.10.1 | MySQL client (improved) |
| pg | ^8.11.3 | PostgreSQL client |
| uuid | ^9.0.1 | UUID generation |
| xml2js | ^0.6.2 | XML to JS conversion |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| @types/pg | ^8.11.4 | PostgreSQL TypeScript types |

---

## Node.js Frontend Dependencies (risx-mssp-front)

### Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| @codemirror/lang-json | ^6.0.1 | JSON language support |
| @lezer/highlight | ^1.2.0 | Syntax highlighting |
| @testing-library/jest-dom | ^5.17.0 | DOM testing utilities |
| @testing-library/react | ^13.4.0 | React testing utilities |
| @testing-library/user-event | ^13.5.0 | User event simulation |
| @uiw/codemirror-theme-vscode | ^4.23.0 | VSCode theme for CodeMirror |
| @uiw/codemirror-themes | ^4.23.0 | CodeMirror themes |
| @uiw/react-codemirror | ^4.23.0 | React CodeMirror component |
| @uiw/react-json-view | ^2.0.0-alpha.24 | JSON viewer component |
| axios | ^1.6.8 | HTTP client |
| chart.js | ^4.4.2 | Charting library |
| lottie-web | ^5.12.2 | Lottie animations |
| path | ^0.12.7 | Path utilities |
| react | ^18.2.0 | React framework |
| react-chartjs-2 | ^5.2.0 | React Chart.js wrapper |
| react-dom | ^18.2.0 | React DOM |
| react-json-view-preview | ^1.0.3 | JSON preview component |
| react-scripts | ^5.0.1 | Create React App scripts |
| react-svg | ^16.1.34 | SVG component |
| web-vitals | ^2.1.4 | Web performance metrics |

### Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| @babel/plugin-proposal-private-property-in-object | ^7.21.11 | Babel plugin |
| cross-env | ^7.0.3 | Cross-platform env vars |
| react-router-dom | ^6.22.3 | React routing |

---

## Container Images (Infrastructure)

### Core Platform

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| nginx | nginx | 1.19.3-alpine | Reverse proxy |
| risx-mssp-backend | custom build | - | Backend API container |
| risx-mssp-frontend | custom build | - | Frontend UI container |
| mysql | custom build | - | Database server |

### ELK Stack

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| elasticsearch | docker.elastic.co/elasticsearch/elasticsearch | 8.15.3 | Search engine |
| logstash | docker.elastic.co/logstash/logstash | 8.15.3 | Data processing |
| kibana | docker.elastic.co/kibana/kibana | 8.15.3 | Visualization |

### Timesketch

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| timesketch-web | us-docker.pkg.dev/osdfir-registry/timesketch/timesketch | 20250708 | Timeline analysis |
| timesketch-worker | us-docker.pkg.dev/osdfir-registry/timesketch/timesketch | 20250708 | Background workers |
| postgres | postgres | 15.6-alpine | Database |
| opensearch | opensearchproject/opensearch | 2.17.0 | Search backend |
| redis | redis | 7.2-alpine | Caching |

### Prowler (Cloud Security)

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| prowler-api | prowlercloud/prowler-api | stable | Security assessment API |
| prowler-ui | prowlercloud/prowler-ui | latest | Security assessment UI |
| postgres | postgres | 16.3-alpine3.20 | Database |
| valkey | valkey/valkey | 7-alpine3.19 | Cache |
| glow | ghcr.io/charmbracelet/glow | v2.0 | README renderer utility |

### MISP (Threat Intelligence)

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| misp-core | ghcr.io/misp/misp-docker/misp-core | latest | MISP core platform |
| misp-modules | ghcr.io/misp/misp-docker/misp-modules | latest | MISP enrichment modules |
| mariadb | mariadb | 10.11 | Database |
| valkey | valkey/valkey | 7.2 | Cache |
| smtp | ixdotai/smtp | latest | Email relay |

### Strelka (File Analysis)

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| strelka-frontend | target/strelka-frontend | 0.24.07.09 | File submission |
| strelka-backend | target/strelka-backend | 0.24.07.09 | File analysis |
| strelka-manager | target/strelka-manager | 0.24.07.09 | Coordination |
| strelka-ui | target/strelka-ui | v2.13 | Web interface |
| redis | redis | 7.4.0-alpine3.20 | Coordination/Gatekeeper |
| jaeger | jaegertracing/all-in-one | 1.42 | Distributed tracing |
| postgresql | bitnami/postgresql | 11 | Database |

### DFIR-IRIS (Incident Response)

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| iriswebapp_app | ghcr.io/dfir-iris/iriswebapp_app | v2.4.20 | IR platform |
| iriswebapp_db | ghcr.io/dfir-iris/iriswebapp_db | v2.4.20 | Database |
| iriswebapp_nginx | ghcr.io/dfir-iris/iriswebapp_nginx | v2.4.20 | Web server |
| rabbitmq | rabbitmq | 3-management-alpine | Message queue |

### Other Tools

| Service | Image | Version | Description |
|---------|-------|---------|-------------|
| cyberchef | ghcr.io/gchq/cyberchef | 10.19 | Data manipulation |
| velociraptor | custom build | v0.74 | Endpoint visibility |
| nightingale | ghcr.io/rajanagori/nightingale | v1.0.0 | Security testing |
| portainer | portainer/portainer-ce | 2.21.0 | Container management |
| portainer-agent | portainer/agent | 2.21.0 | Portainer agent |

---

## External Repositories (Cloned During Installation)

| Repository | Source | Version/Commit | Purpose |
|------------|--------|----------------|---------|
| docker-elk | deviantony/docker-elk | commit 629aea49 | ELK stack docker configuration |
| iris-web | dfir-iris/iris-web | v2.4.10 | DFIR-IRIS incident response platform |

---

## External Data Sources

| Source | URL | Version | Purpose |
|--------|-----|---------|---------|
| YARA Forge Rules | yara-forge/yara-forge-rules | 20240922 | YARA rules for Strelka file analysis |
| Velociraptor Artifacts | 10RootOrg/Velociraptor-Artifacts | main | Custom Velociraptor artifact definitions |
| DFIQ | google/dfiq | main | Digital Forensics Investigation Questions |
| AllthingsTimesketch Tags | blueteam0ps/AllthingsTimesketch | latest | Timesketch tag configurations |
| YARA Rules (Bartblaze) | bartblaze/YARA-rules | main | Additional YARA rules for Strelka |

---

## Security Considerations

### Known Security-Sensitive Dependencies

1. **cryptography (43.0.1)** - Handles cryptographic operations
2. **bcrypt (5.1.1)** - Password hashing
3. **requests (2.32.3)** - HTTP client - ensure proper certificate validation
4. **openai (latest)** - External API integration - secure API key handling required

### Recommendations

1. Regularly update dependencies to patch security vulnerabilities
2. Use tools like `npm audit`, `pip-audit`, or Snyk for vulnerability scanning
3. Pin Docker image versions in production
4. Review and monitor CVE databases for known vulnerabilities

---

## Files

- **sbom.json** - Machine-readable CycloneDX 1.5 format SBOM
- **SBOM.md** - This human-readable summary

---

## References

- [CycloneDX Specification](https://cyclonedx.org/specification/overview/)
- [SPDX License List](https://spdx.org/licenses/)
- [Package URL (purl) Specification](https://github.com/package-url/purl-spec)
