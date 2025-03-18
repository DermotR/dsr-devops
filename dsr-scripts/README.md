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
   ./dsr-scripts/setup_python_project.sh
   
   # To set up a Node.js project
   ./dsr-scripts/setup_node_project.sh
   
   # To set up a Vite React-TS + Node.js/Prisma project
   ./dsr-scripts/setup_vite_react_prisma.sh
   ```

## Available Scripts

### Project Setup

#### `setup_python_project.sh`

Sets up a Python project with standard structure, virtual environment, and GitHub repository.

```bash
./dsr-scripts/setup_python_project.sh [project_name] [--no-github] [--public]
```

Example:
```bash
# Use folder name as project name
./dsr-scripts/setup_python_project.sh

# Specify a custom project name
./dsr-scripts/setup_python_project.sh my-custom-project

# Create a public repository
./dsr-scripts/setup_python_project.sh --public
```

**Note on Virtual Environment Activation:**  
The script offers to activate the virtual environment after creation. If you choose to activate it, this will launch a new shell with the virtual environment active. When you're done, type `exit` to return to your original shell.

#### `setup_node_project.sh`

Sets up a Node.js project with client-server structure and GitHub repository.

```bash
./dsr-scripts/setup_node_project.sh [project_name] [--no-github] [--public] [--client-framework <framework>]
```

Example:
```bash
# Use folder name as project name
./dsr-scripts/setup_node_project.sh

# Specify a custom project name
./dsr-scripts/setup_node_project.sh my-custom-project

# Create a React-based project
./dsr-scripts/setup_node_project.sh --client-framework react
```

#### `setup_vite_react_prisma.sh`

Sets up a modern full-stack TypeScript project with Vite React frontend and Node.js backend with Prisma ORM.

```bash
./dsr-scripts/setup_vite_react_prisma.sh [project_name] [--no-github] [--public]
```

Example:
```bash
# Use folder name as project name
./dsr-scripts/setup_vite_react_prisma.sh

# Specify a custom project name
./dsr-scripts/setup_vite_react_prisma.sh my-custom-project

# Create a public repository
./dsr-scripts/setup_vite_react_prisma.sh --public
```

**Features:**
- TypeScript throughout the entire stack
- Vite for fast development and optimized builds
- React frontend with TypeScript templates
- Node.js Express backend
- Prisma ORM with SQLite (configurable to other databases)
- Concurrently to run both frontend and backend simultaneously

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

These scripts operate in the parent directory where the `dsr-scripts` folder is located. The project name is based on the parent directory name, converted to a standardized format (lowercase with hyphens instead of spaces).

For example, if your directory is named "My Project", the resulting project will be named "my-project". You can also provide a custom project name as the first argument to any setup script.

The scripts will automatically:
- Create proper project structure
- Initialize git repository
- Set up GitHub integration (if enabled)
- Configure development environments