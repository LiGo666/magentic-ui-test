#!/bin/bash

# Stop all existing containers
echo "Stopping any running containers..."
docker-compose down
docker container prune -f

# Make sure we have the Docker network
echo "Ensuring Docker network exists..."
docker network ls | grep my-network >/dev/null 2>&1 || docker network create my-network

# Create a Dockerfile that we know works
echo "Creating working Dockerfile..."
cat > Dockerfile << 'EOD'
# Frontend build stage
FROM node:18 AS frontend-builder

# Install build dependencies
RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

WORKDIR /app/frontend
COPY ./magentic-ui/frontend /app/frontend
RUN mkdir -p /app/src/magentic_ui/backend/web/ui
RUN yarn install && yarn build

# Python application stage
FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh

WORKDIR /app
COPY ./magentic-ui /app
RUN mkdir -p /app/src/magentic_ui/backend/web/ui

# Copy built frontend
COPY --from=frontend-builder /app/frontend/public/ /app/src/magentic_ui/backend/web/ui/

# Install Python dependencies
RUN python -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir -e /app[dev,full]

# Set environment 
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Expose ports
EXPOSE 8081 6080

# Start the app bound to 0.0.0.0
CMD ["/app/venv/bin/magentic-ui", "--port", "8081", "--host", "0.0.0.0"]
EOD

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOD'
version: '3'

services:
  magentic-ui:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8082:8081"
      - "6080:6080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./workspace:/workspace
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - INSIDE_DOCKER=1
      - DOCKER_HOST=unix:///var/run/docker.sock
      - INTERNAL_WORKSPACE_ROOT=/workspace
      - EXTERNAL_WORKSPACE_ROOT=/workspace
      - DOCKER_NETWORK=my-network
      - USE_DOCKER_HOST_INTERNAL=1
    networks:
      - my-network
    extra_hosts:
      - "host.docker.internal:host-gateway"

networks:
  my-network:
    external: true
EOD

# Ensure the browser agent VNC image is built
echo "Building the VNC browser agent image..."
cd magentic-ui/src/magentic_ui/docker/magentic-ui-browser-docker && docker build -t magentic-ui-vnc-browser .
cd ../../../../..

# Build and start the main container
echo "Building and starting the main container..."
docker-compose build --no-cache
docker-compose up -d

# Check container status
echo "Checking container status..."
sleep 10
docker ps
