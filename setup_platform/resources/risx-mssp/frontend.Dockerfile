# syntax=docker/dockerfile:1
FROM node:20-alpine AS build

RUN mkdir /code

WORKDIR /code

RUN apk update && apk add wget unzip
RUN wget -O risx-mssp.zip "https://www.dropbox.com/scl/fi/0am9btdcqg4d9h2dwjlu1/mssp-11-07-24.zip?rlkey=d81z21j662lcj8xn7x72cc4fo&dl=1"
RUN unzip -q risx-mssp.zip "risx-mssp-front/*"

WORKDIR /code/risx-mssp-front

RUN rm -rf node_modules

RUN npm install && npm install http-server serve

RUN npm run build

FROM node:20-alpine AS target

WORKDIR /app

COPY --from=build /code/risx-mssp-front/ /app

USER node

EXPOSE 3003

ENTRYPOINT ["npm", "run", "start"]
