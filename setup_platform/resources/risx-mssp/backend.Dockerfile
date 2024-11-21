# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
ARG SRC_URL_BACKEND
RUN mkdir -p /code

WORKDIR /code

RUN apk update && apk add wget unzip
RUN wget -O risx-mssp.zip --quiet "${SRC_URL_BACKEND}"
RUN unzip -q risx-mssp.zip "risx-mssp-back/*"
RUN unzip -q risx-mssp.zip "risx-mssp-python-script/*"

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
