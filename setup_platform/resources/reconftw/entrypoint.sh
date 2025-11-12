#!/usr/bin/env bash
set -euo pipefail

PORT="${RECONFTW_PORT:-80}"

echo "Starting reconftw ttyd endpoint on port ${PORT}" >&2
exec /usr/local/bin/ttyd --writable --port "${PORT}" --interface 0.0.0.0 /bin/bash
