# syntax=docker/dockerfile:1
FROM mysql:9

COPY permissions.sql .

RUN --mount=type=secret,id=SHORESH_PASSWD export SHORESH_PASSWORD=$(cat /run/secrets/SHORESH_PASSWD | head -n 1); \
    echo "SHORESH_PASSWORD is: $SHORESH_PASSWORD"

RUN --mount=type=secret,id=SHORESH_PASSWD export SHORESH_PASSWORD=$(cat /run/secrets/SHORESH_PASSWD | head -n 1); \
    echo "SHORESH_PASSWORD is: $SHORESH_PASSWORD"; \
    cat permissions.sql | \
      while read line; do eval echo "${line}"; \
    done > /docker-entrypoint-initdb.d/00-permissions.sql; \
    echo "Contents of 00-permissions.sql:"; \
    cat /docker-entrypoint-initdb.d/00-permissions.sql
