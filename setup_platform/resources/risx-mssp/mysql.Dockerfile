# syntax=docker/dockerfile:1
FROM mysql:latest

COPY permissions.sql .

RUN --mount=type=secret,id=shoresh-passwd export SHORESH_PASSWORD=$(cat /run/secrets/shoresh-passwd | head -n 1); \
    cat permissions.sql | \
      while read line; do eval echo "${line}"; \
    done > /docker-entrypoint-initdb.d/00-permissions.sql
