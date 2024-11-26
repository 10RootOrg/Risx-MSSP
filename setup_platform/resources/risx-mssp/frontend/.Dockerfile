# syntax=docker/dockerfile:1
FROM node:20-alpine AS build

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
# TODO: uncomment it when the package.json is ready for production
#RUN npm install --production
RUN npm ci

# Copy the rest of the src application code
COPY src app

RUN npm run build
#RUN rm -rf build/mssp_config.json
#COPY mssp_config.json build/mssp_config.json

FROM nginx:mainline-alpine AS target

WORKDIR /

COPY --from=build /app/build/ /usr/share/nginx/html

RUN mkdir -p /etc/nginx/templates
COPY nginx_default.conf.template /etc/nginx/templates/default.conf.template

ENV NGINX_PORT=3003

EXPOSE 3003

