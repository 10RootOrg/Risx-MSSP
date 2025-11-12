ARG TARGETPLATFORM=linux/amd64
ARG TARGETARCH=amd64
ARG RECONFTW_IMAGE_TAG=latest
FROM --platform=${TARGETPLATFORM} six2dez/reconftw:${RECONFTW_IMAGE_TAG}

ARG RECONFTW_TTYD_VERSION=1.7.7

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64|x86_64) ttyd_arch="x86_64" ;; \
        arm64|aarch64) ttyd_arch="aarch64" ;; \
        arm|armv7|armhf) ttyd_arch="armv7l" ;; \
        *) echo "Unsupported architecture for ttyd: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    TTYD_DOWNLOAD_URL="https://github.com/tsl0922/ttyd/releases/download/${RECONFTW_TTYD_VERSION}/ttyd.${ttyd_arch}"; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    curl -L "$TTYD_DOWNLOAD_URL" -o /usr/local/bin/ttyd; \
    chmod +x /usr/local/bin/ttyd; \
    apt-get purge -y --auto-remove curl; \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
