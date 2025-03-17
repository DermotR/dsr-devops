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
# Set up a Python project
./dsr-scripts/setup_python_project.sh acme

# Set up a Node.js project
./dsr-scripts/setup_node_project.sh prefix=acme

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
   - Templates for various project types

2. **GitHub Workflow Tools:**
   - Session start script (pulls latest code, checks environment)
   - Check-in script (commits and pushes changes)

3. **Templates & Resources:**
   - Node.js client-server project template
   - Common .gitignore files
   - Project structure templates

## How It Works

These scripts are designed to be self-contained and operate relative to their location. When you run a script, it automatically:

1. Detects that it's being run from within the `dsr-scripts` folder
2. Looks one level up to find your project directory
3. Uses your project folder name to generate the project name (with your prefix)
4. Sets up everything in your project directory, not inside the `dsr-scripts` folder
5. Automatically excludes the `dsr-scripts` folder from git

## Project Naming Convention

Project names are generated from your folder name with a prefix:

- Folder: `My Project`
- Prefix: `acme`
- Result: `acme-my-project`

This ensures consistent naming across projects.

## Documentation

For detailed usage instructions, see the [README.md](./dsr-scripts/README.md) inside the `dsr-scripts` folder.

## License

MIT