ARG RECONFTW_IMAGE_TAG=latest
FROM six2dez/reconftw:${RECONFTW_IMAGE_TAG}

ARG RECONFTW_TTYD_VERSION=1.7.7
ENV TTYD_DOWNLOAD_URL="https://github.com/tsl0922/ttyd/releases/download/${RECONFTW_TTYD_VERSION}/ttyd.x86_64"

RUN set -eux; \
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
