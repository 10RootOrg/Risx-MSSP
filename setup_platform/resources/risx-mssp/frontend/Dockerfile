# syntax=docker/dockerfile:1
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json for initial installation
# The actual source code will be mounted via volume
COPY Code/package*.json ./

# Install dependencies in development mode to include dev dependencies
RUN npm install

# Set development environment
ENV NODE_ENV=development
ENV NGINX_PORT=3003

# Expose development port
EXPOSE 3003

# Start in development mode with hot reloading
CMD ["npm", "start"]