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

# Fix the VNC browser hostname issue directly in the file
RUN sed -i 's/def vnc_address(self) -> str:/def _original_vnc_address(self) -> str:\n        pass\n\n    @property\n    def vnc_address(self) -> str:/' /app/src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py && \
    sed -i 's|return f"http://{self._hostname}:{self._novnc_port}/vnc.html"|import os\n        hostname = "host.docker.internal" if os.environ.get("USE_DOCKER_HOST_INTERNAL") else self._hostname\n        return f"http://{hostname}:{self._novnc_port}/vnc.html"|' /app/src/magentic_ui/tools/playwright/browser/vnc_docker_playwright_browser.py

# Install Python dependencies
RUN python -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir -e /app[dev,full]

# Set environment variables
ENV PATH="/app/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1

# Expose ports for UI and VNC
EXPOSE 8081 6080

# Start the app bound to 0.0.0.0
CMD ["/app/venv/bin/magentic-ui", "--port", "8081", "--host", "0.0.0.0"]
