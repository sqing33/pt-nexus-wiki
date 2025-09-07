# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docsify-based documentation site that provides a simple way to create documentation websites. The project uses Docsify to generate a static documentation site with automatic sidebar generation and various plugins for enhanced functionality.

## Key Components

1. **README.md**: 项目概述和使用说明
2. **index.html**: Docsify 主配置文件，包含自定义插件和样式
3. **_sidebar.md**: Docsify 侧边栏（手动维护）
4. **docs/index.md**: 首页文档
5. **docs/installation.md**: 安装指南文档
6. **docs/guide/getting-started.md**: 入门教程
7. **vercel.json**: Vercel 部署配置

## Configuration Notes

- `subMaxLevel: 0` is set to prevent subheaders from appearing in the sidebar
- `basePath: '/docs/'` is configured to use docs as the root directory for documentation files
- `alias` configuration maps missing `_sidebar.md` files to the root `_sidebar.md` to prevent loading issues
- All documentation files are organized in the `docs/` directory

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
├── README.md               # Project overview and usage instructions
├── index.html              # Main Docsify configuration
├── _sidebar.md             # Sidebar navigation
├── docs/                   # Documentation files
│   ├── index.md            # Homepage
│   ├── installation.md     # Installation guide
│   └── guide/              # Guide documentation
│       └── getting-started.md  # Getting started guide
├── _media/                 # Media files
│   └── icon.svg            # Site icon
└── vercel.json             # Vercel deployment config
```

## Development Environment

To develop this documentation site:
1. Edit the Markdown files in the docs/ directory to update content
2. Modify index.html to change the site configuration or add plugins
3. Update _sidebar.md to modify navigation
4. Use a local server to preview changes