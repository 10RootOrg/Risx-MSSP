# syntax=docker/dockerfile:1
FROM alpine:3 AS build

RUN mkdir -p /code

WORKDIR /code

RUN apk update && apk add wget unzip
RUN wget -O risx-mssp.zip --quiet  "https://www.dropbox.com/scl/fi/0am9btdcqg4d9h2dwjlu1/mssp-11-07-24.zip?rlkey=d81z21j662lcj8xn7x72cc4fo&dl=1"
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

