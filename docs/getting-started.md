# Getting Started with DSR DevOps Tools

This guide will help you get started with the DevOps tools in this repository.

## Prerequisites

These tools require:

- Bash shell (Linux, macOS, or Windows with Git Bash/WSL)
- Git installed and configured
- GitHub CLI (optional, but recommended)
- Python 3.6+ (for Python project setup)

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/DermotR/dsr-devops.git
   cd dsr-devops
   ```

2. Make the scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

3. Optionally, add the scripts to your PATH for easy access:
   ```bash
   # Add this to your .bashrc or .zshrc
   export PATH="$PATH:/path/to/dsr-devops/scripts"
   ```

## First-Time Setup

### GitHub CLI Setup

For the best experience, install and authenticate with GitHub CLI:

1. Install GitHub CLI from https://cli.github.com/
2. Authenticate with GitHub:
   ```bash
   gh auth login
   ```

## Using the Tools

### Creating a New Python Project

To create a new Python project with a standardized structure:

```bash
cd your-project-directory
/path/to/dsr-devops/scripts/setup_python_project.sh your-prefix
```

This will create a project named `your-prefix-project-name` based on your current directory name.

### Starting a Coding Session

At the beginning of each coding session, run:

```bash
cd your-project
/path/to/dsr-devops/scripts/github_start_session.sh
```

This will update your repository, check for changes, and ensure your environment is ready.

### Ending a Coding Session

At the end of your coding session, to check in your code:

```bash
cd your-project
/path/to/dsr-devops/scripts/github_checkin.sh "Your commit message"
```

This will commit your changes and push them to GitHub.

## Troubleshooting

### Scripts Not Executing

If you see "Permission denied" errors, make sure the scripts are executable:

```bash
chmod +x /path/to/dsr-devops/scripts/*.sh
```

### GitHub Repository Issues

If you encounter issues with GitHub repository creation:

1. Ensure you're authenticated with GitHub CLI:
   ```bash
   gh auth status
   ```

2. Check if your Git configuration is correct:
   ```bash
   git config --global --list
   ```