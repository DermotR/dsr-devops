# DSR DevOps

A collection of DevOps scripts and tools for streamlining development workflows.

## Overview

This repository contains scripts and utilities to automate common development tasks, including:

- Project setup
- GitHub repository management
- Development environment preparation
- Session management (start/end of coding sessions)

## Repository Structure

```
├── scripts/          # Automation scripts
│   ├── github_checkin.sh           # Check in code at end of session
│   ├── github_start_session.sh     # Prepare environment at start of session
│   ├── setup_python_project.py     # Python script for project setup
│   └── setup_python_project.sh     # Shell wrapper for project setup
├── docs/             # Documentation
└── templates/        # Template files for project scaffolding
```

## Scripts

### GitHub Session Management

#### Start Session (`scripts/github_start_session.sh`)

Prepares your development environment at the start of a coding session:

- Pulls latest code from remote repository
- Handles branch management
- Checks for uncommitted changes
- Sets up project dependencies (Python, Node.js)

Usage:
```bash
./scripts/github_start_session.sh [branch_name]
```

#### End Session (`scripts/github_checkin.sh`)

Automates the process of checking in code at the end of a coding session:

- Adds and commits changes
- Handles branch management
- Pushes to remote repository

Usage:
```bash
./scripts/github_checkin.sh [commit_message] [branch_name] [visibility]
```

### Project Setup

#### Python Project Setup (`scripts/setup_python_project.sh`)

Creates a standardized Python project structure with:

- Virtual environment
- Standard directory structure
- Initial Git repository
- GitHub integration

Usage:
```bash
./scripts/setup_python_project.sh <prefix> [--no-github] [--public]
```

## Installation

Clone this repository to your local machine:

```bash
git clone https://github.com/DermotR/dsr-devops.git
cd dsr-devops
```

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

## Contributing

Feel free to submit issues and pull requests for new features or improvements.

## License

MIT