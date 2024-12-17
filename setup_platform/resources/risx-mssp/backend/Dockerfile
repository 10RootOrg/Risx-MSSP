# syntax=docker/dockerfile:1
FROM python:3.10-bookworm as final
ENV NODE_VERSION=20

RUN curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && apt-get clean

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Set working directory
WORKDIR /risx-mssp-back

# Backend
# Copy package.json and package-lock.json
COPY /risx-mssp-back/package*.json ./
# Install dependencies
RUN npm ci
# Copy the rest of the application code
COPY /risx-mssp-back/ .

# PYTHON SCRIPTS
COPY /python-scripts /python-scripts
RUN pip install -r /python-scripts/requirements.txt

# Final steps
COPY /entrypoint.sh /entrypoint.sh
# Ensure entrypoint script is executable
RUN chmod +x /entrypoint.sh

# Use a non-root user
USER node
# Expose the application port
EXPOSE 5555

# Set environment variables
ENV FORCE_INIT=0
ENV INIT_CHECK_DIR=/init_check

# Define the entrypoint
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
