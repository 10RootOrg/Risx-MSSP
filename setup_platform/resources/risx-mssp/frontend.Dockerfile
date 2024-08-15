# syntax=docker/dockerfile:1
FROM alpine:3 AS build

RUN mkdir -p /code

WORKDIR /code

RUN apk update && apk add wget unzip
RUN wget -O risx-mssp.zip --quiet  "https://www.dropbox.com/scl/fi/wu0kgdx5t4ltik1ncb76f/mssp-12-08-24.zip?rlkey=eska5k006n0ddmejf3p1ciiyt&st=ul2jbq7l&dl=1"
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

