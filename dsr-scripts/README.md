# DSR-Scripts: Developer Toolbox

This folder contains scripts for automating common development workflows. Simply drop this folder into your project and use the scripts as needed.

## Quick Start

1. Add this folder to your project directory:
   ```
   my-project/
   └── dsr-scripts/
   ```

2. Run scripts from your project directory:
   ```bash
   # To set up a Python project
   ./dsr-scripts/setup_python_project.sh acme
   
   # To set up a Node.js project
   ./dsr-scripts/setup_node_project.sh prefix=acme
   ```

## Available Scripts

### Project Setup

#### `setup_python_project.sh`

Sets up a Python project with standard structure, virtual environment, and GitHub repository.

```bash
./dsr-scripts/setup_python_project.sh <prefix> [--no-github] [--public]
```

Example:
```bash
./dsr-scripts/setup_python_project.sh acme
```

#### `setup_node_project.sh`

Sets up a Node.js project with client-server structure and GitHub repository.

```bash
./dsr-scripts/setup_node_project.sh prefix=<prefix> [--no-github] [--public] [--client-framework <framework>]
```

Example:
```bash
./dsr-scripts/setup_node_project.sh prefix=acme --client-framework react
```

### GitHub Session Management

#### `github_start_session.sh`

Prepares your environment at the beginning of a coding session.

```bash
./dsr-scripts/github_start_session.sh [branch_name]
```

#### `github_checkin.sh`

Commits and pushes your code at the end of a session.

```bash
./dsr-scripts/github_checkin.sh [commit_message] [branch_name] [visibility]
```

## How It Works

These scripts operate in the parent directory where the `dsr-scripts` folder is located. The project name is based on the parent directory name, with a prefix added for standardization.

For example, if your directory is named "My Project" and you use prefix "acme", the resulting project will be named "acme-my-project".

The scripts will automatically:
- Create proper project structure
- Initialize git repository
- Set up GitHub integration (if enabled)
- Configure development environments