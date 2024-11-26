# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
ARG GIT_RISX_BACKEND_URL
ARG GIT_RISX_BACKEND_BRANCH

RUN apk add --no-cache git \
    mkdir -p /code
# Clone the repository
WORKDIR /code
RUN mkdir -p /code \
    git clone --branch ${GIT_RISX_BACKEND_BRANCH} ${GIT_RISX_BACKEND_URL} risx-mssp-back

# TODO: Python scripts: `response_folder` contents
WORKDIR /code/risx-mssp-back
RUN rm -rf node_modules
RUN npm install

FROM node:20-alpine AS target

WORKDIR /app

COPY --from=build /code/risx-mssp-back/ /app
COPY --from=build /code/risx-mssp-python-script/ /app/python-scripts
COPY backend_entrypoint.sh entrypoint.sh
RUN chmod a+x entrypoint.sh

USER node

EXPOSE 5555

ENV FORCE_INIT=0
ENV INIT_CHECK_DIR=/init_check

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
