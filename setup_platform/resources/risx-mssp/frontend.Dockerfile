# syntax=docker/dockerfile:1
FROM alpine:3 AS build
ARG SRC_URL_FRONTEND
RUN mkdir -p /code

WORKDIR /code

RUN apk update && apk add wget unzip
RUN wget -O risx-mssp.zip --quiet  "${SRC_URL_FRONTEND}"
RUN unzip -q risx-mssp.zip "risx-mssp-front-build/*"

WORKDIR /code/risx-mssp-front-build

RUN rm -f mssp_config.json

FROM nginx:mainline-alpine AS target

WORKDIR /

COPY --from=build /code/risx-mssp-front-build/ /usr/share/nginx/html

RUN mkdir -p /etc/nginx/templates
COPY nginx_default.conf.template /etc/nginx/templates/default.conf.template

ENV NGINX_PORT=3003

EXPOSE 3003

