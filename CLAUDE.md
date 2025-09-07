# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docsify-based documentation site that provides a simple way to create documentation websites. The project uses Docsify to generate a static documentation site with automatic sidebar generation and various plugins for enhanced functionality.

## Key Components

1. **index.html**: Main Docsify configuration with custom plugins and styling
2. **_sidebar.md**: Docsify sidebar (manually maintained)
3. **installation.md**: Installation guide documentation
4. **guide/getting-started.md**: Getting started guide
5. **vercel.json**: Vercel deployment configuration

## Common Development Tasks

### Running the Documentation Site
```bash
# Serve the documentation site locally
npx serve
# or
npx http-server
```

### Deployment
This project is configured for deployment on Vercel with the vercel.json configuration file.

## Architecture

The system works by:
1. Using Docsify to dynamically generate documentation pages from Markdown files
2. Automatically generating navigation based on the sidebar configuration
3. Providing a responsive design that works on desktop and mobile devices
4. Including various plugins for enhanced functionality (table of contents, copy code, etc.)

## File Structure
```
.
├── index.html              # Main Docsify configuration
├── _sidebar.md             # Sidebar navigation
├── installation.md         # Installation guide
├── guide/                  # Guide documentation
│   └── getting-started.md  # Getting started guide
├── _media/                 # Media files
│   └── icon.svg            # Site icon
└── vercel.json             # Vercel deployment config
```

## Development Environment

To develop this documentation site:
1. Edit the Markdown files to update content
2. Modify index.html to change the site configuration or add plugins
3. Update _sidebar.md to modify navigation
4. Use a local server to preview changes