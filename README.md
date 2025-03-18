# DSR DevOps Toolbox

A collection of tools for streamlining development workflows, packaged as a self-contained folder that can be dropped into any project.

## Quick Start

Simply copy the `dsr-scripts` folder into your project directory:

```
your-project/
└── dsr-scripts/
```

Then run any of the included scripts from your project directory:

```bash
# Set up a Python project (uses folder name as project name)
./dsr-scripts/setup_python_project.sh

# Set up a Node.js project (uses folder name as project name)
./dsr-scripts/setup_node_project.sh

# Start a coding session
./dsr-scripts/github_start_session.sh

# Check in your code at the end of a session
./dsr-scripts/github_checkin.sh "Your commit message"
```

## What's Included

The `dsr-scripts` folder contains:

1. **Project Setup Tools:**
   - Python project setup script
   - Node.js project setup script with client-server architecture
   - Vite React + Prisma fullstack setup script
   - Templates for various project types

2. **GitHub Workflow Tools:**
   - Session start script (pulls latest code, checks environment)
   - Check-in script (commits and pushes changes)

3. **Templates & Resources:**
   - Node.js client-server project template
   - Common .gitignore files
   - Project structure templates

## OS Support

- **macOS/Linux**: All scripts have `.sh` extensions and are Bash compatible
- **Windows**: PowerShell scripts with `.ps1` extensions are available for key setup operations

The scripts automatically check for required dependencies and will prompt you to install any missing tools before proceeding.

## How It Works

These scripts are designed to be self-contained and operate relative to their location. When you run a script, it automatically:

1. Detects that it's being run from within the `dsr-scripts` folder
2. Looks one level up to find your project directory
3. Uses your project folder name as the default project name
4. Sets up everything in your project directory, not inside the `dsr-scripts` folder
5. Automatically excludes the `dsr-scripts` folder from git

## Project Naming Convention

By default, project names are derived directly from the parent folder name, converted to lowercase with hyphens instead of spaces:

- Folder: `My Project`
- Default project name: `my-project`

You can also specify a custom project name as the first argument to the setup scripts:

```bash
./dsr-scripts/setup_python_project.sh custom-project-name
```

## Documentation

For detailed usage instructions, see the [README.md](./dsr-scripts/README.md) inside the `dsr-scripts` folder.

## License

MIT