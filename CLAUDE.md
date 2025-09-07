# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dockerized Docsify environment that provides automatic documentation updates through Git Webhooks. The project is based on `stilleshan/docsify` image with added features including a right-side table of contents plugin and automatic sidebar generation.

## Key Components

1. **Dockerfile**: Builds the Docker image with Git support and copies necessary files
2. **entrypoint.sh**: Container entrypoint that handles initialization, Git setup, and service startup
3. **generate-sidebar.js**: Node.js script that automatically generates the Docsify sidebar based on the directory structure
4. **listener.js**: Node.js webhook listener that updates documentation when changes are pushed to the Git repository
5. **index.html**: Main Docsify configuration with custom plugins and styling
6. **docker-compose.yml**: Example deployment configuration

## Common Development Tasks

### Building the Docker Image
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t sqing33/docsify:latest \
  -t ghcr.io/sqing33/docsify:latest \
  --push .
```

### Running with Docker Compose
```bash
docker-compose up -d
```

### Environment Variables
- `DOCSIFY_PORT`: Docsify service port (default: 6158)
- `ENABLE_GIT`: Enable Git functionality (default: true)
- `WEBHOOK_PORT`: Webhook listener port (default: 6159)
- `WEBHOOK_SECRET`: Secret for webhook signature verification
- `GIT_REMOTE_URL`: Git repository URL
- `GIT_REMOTE`: Git remote name (default: origin)
- `GIT_BRANCH`: Git branch to monitor (default: main)

## Architecture

The system works by:
1. Initializing a Git repository in the `/docs` directory on container startup
2. Pulling documentation from a remote Git repository
3. Generating a sidebar automatically based on the directory structure
4. Listening for webhook events from Gitea/GitHub
5. Automatically pulling updates and regenerating the sidebar when changes are detected

## File Structure
```
.
├── Dockerfile              # Docker image build file
├── entrypoint.sh           # Container entrypoint script
├── generate-sidebar.js     # Sidebar generation script
├── listener.js             # Webhook listener service
├── index.html              # Docsify main HTML and configuration
├── _sidebar.md             # Docsify sidebar (auto-generated)
├── README.md               # Project documentation
└── icon.svg                # Site icon
```