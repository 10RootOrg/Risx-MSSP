FROM mysql:9

RUN --mount=type=secret,id=SHORESH_PASSWD \
    --mount=type=bind,source=/permissions.sql,target=/permissions.sql \
    export SHORESH_PASSWORD=$(cat /run/secrets/SHORESH_PASSWD | head -n 1); \
    cat /permissions.sql | \
      while read line; do eval echo "${line}"; \
    done > /docker-entrypoint-initdb.d/00-permissions.sql
