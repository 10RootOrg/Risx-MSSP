FROM python:3.10-bookworm AS final
ENV NODE_VERSION=20

RUN apt-get update \
    && apt-get install -y curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli p7zip-full sudo \
    && npm install -g yarn nodemon \
    && apt-get clean

# Create the docker group with the same GID as the host
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node \
  && groupadd -g 123 docker \
  && usermod -aG docker node \
  && usermod -aG sudo node \
  && echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node

# Set working directory
WORKDIR /risx-mssp-back

# Install Python dependencies for the Python scripts
WORKDIR /python-scripts
COPY /python-scripts/requirements.txt ./requirements.txt
RUN pip install -r requirements.txt

# Return to backend working directory
WORKDIR /risx-mssp-back

# Only copy package files for initial installation
# The actual source code will be mounted via volume
COPY /risx-mssp-back/package*.json ./
RUN npm install

# Copy entrypoint script
COPY /entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Use a non-root user
USER node

# Expose the application port
EXPOSE 5555

# Set environment variables
ENV FORCE_INIT=0
ENV INIT_CHECK_DIR=/init_check
ENV NODE_ENV=development

# Define the entrypoint
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

# The actual command will be provided in docker-compose.yml
# Default to development mode with nodemon for auto-reloading
CMD ["npm", "run", "dev"]