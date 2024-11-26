# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
ARG PYTHON_VERSION=3

# Install python dependecies to run python scripts
RUN apk add --no-cache python${PYTHON_VERSION} py3-pip

# Set working directory
WORKDIR /app

# Backend
# Copy package.json and package-lock.json
COPY package*.json ./
# Install dependencies
RUN npm ci
# Copy the rest of the application code
COPY . .
# Ensure entrypoint script is executable
RUN chmod +x entrypoint.sh

# Use a non-root user
USER node
# Expose the application port
EXPOSE 5555

# Set environment variables
ENV FORCE_INIT=0
ENV INIT_CHECK_DIR=/init_check

# Define the entrypoint
ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
