# Magentic UI Docker Setup

This repository contains Docker configurations for running the Microsoft Magentic UI application with VNC browser support.

## Features

- Containerized Magentic UI with proper VNC browser support
- Fixed VNC browser hostname for Docker connectivity
- Exposed ports for UI (8082) and VNC (6080)

## Setup Instructions

1. Clone this repository
2. Copy `.env.template` to `.env` and add your OpenAI API key:
   ```
   cp .env.template .env
   # Edit .env to add your OpenAI API key
   ```
3. Build and start the containers:
   ```
   docker-compose build
   docker-compose up -d
   ```
4. Access the UI at http://localhost:8082

## VNC Browser Support

The VNC browser container will start automatically when a browser session is created through the UI. You can access the VNC browser session at port 6080.

## Requirements

- Docker and Docker Compose
- An OpenAI API key
