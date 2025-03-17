#!/bin/bash
#
# setup_python_project.sh - Bash wrapper for Python project setup script
#
# This script calls the Python setup script and handles system operations like
# making the script executable and activating the virtual environment.
#
# Usage:
#   ./setup_python_project.sh <prefix> [--no-github] [--public]
#
# Example:
#   ./setup_python_project.sh acme
#   This will create a project named "acme-my-project" if run from a folder named "my-project".
#
#   ./setup_python_project.sh acme --no-github
#   This will create the project but skip GitHub repository creation.
#
#   ./setup_python_project.sh acme --public
#   This will create the project with a public GitHub repository instead of private.

set -e  # Exit immediately if a command exits with a non-zero status

# Check if prefix argument is provided
if [ $# -lt 1 ]; then
    echo "Error: Missing prefix argument."
    echo "Usage: ./setup_python_project.sh <prefix> [--no-github] [--public]"
    exit 1
fi

PREFIX="$1"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SCRIPT="$SCRIPT_DIR/setup_python_project.py"

# Check for GitHub flag
GITHUB_FLAG=""
if [[ "$*" == *"--no-github"* ]]; then
    GITHUB_FLAG="--no-github"
fi

# Check for GitHub CLI if needed
if [ -z "$GITHUB_FLAG" ]; then
    if ! command -v gh &> /dev/null; then
        echo "Warning: GitHub CLI (gh) not found."
        echo "You can install it from: https://cli.github.com/"
        echo "Continuing without GitHub integration..."
        echo "To skip this check in the future, use --no-github flag."
        echo ""
        
        # Ask if user wants to continue without GitHub CLI
        read -p "Continue without GitHub integration? (y/n): " CONTINUE
        if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
            echo "Setup aborted. Please install GitHub CLI and try again."
            exit 1
        fi
        
        GITHUB_FLAG="--no-github"
    else
        # Check if the user is authenticated with GitHub
        if ! gh auth status &> /dev/null; then
            echo "You need to authenticate with GitHub CLI first."
            echo "Run 'gh auth login' and follow the prompts."
            echo ""
            
            # Ask if user wants to authenticate now
            read -p "Would you like to authenticate now? (y/n): " AUTH_NOW
            if [[ $AUTH_NOW == "y" || $AUTH_NOW == "Y" ]]; then
                gh auth login
                if ! gh auth status &> /dev/null; then
                    echo "Authentication failed. Continuing without GitHub integration."
                    GITHUB_FLAG="--no-github"
                fi
            else
                echo "Continuing without GitHub integration..."
                GITHUB_FLAG="--no-github"
            fi
        fi
    fi
fi

# Check if Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python setup script not found at $PYTHON_SCRIPT"
    exit 1
fi

# Make the Python script executable if it's not already
if [ ! -x "$PYTHON_SCRIPT" ]; then
    echo "Making Python script executable..."
    chmod +x "$PYTHON_SCRIPT"
fi

# Check for public flag
VISIBILITY_FLAG=""
if [[ "$*" == *"--public"* ]]; then
    VISIBILITY_FLAG="--public"
fi

# Run the Python setup script
echo "Running Python setup script with prefix: $PREFIX"
"$PYTHON_SCRIPT" "$PREFIX" $GITHUB_FLAG $VISIBILITY_FLAG

# Activate the virtual environment
if [ -d ".venv" ]; then
    echo "Activating virtual environment..."
    
    # Get the correct activation script based on platform
    if [ -f ".venv/bin/activate" ]; then
        ACTIVATE_SCRIPT=".venv/bin/activate"  # Unix/Mac
    elif [ -f ".venv/Scripts/activate" ]; then
        ACTIVATE_SCRIPT=".venv/Scripts/activate"  # Windows
    else
        echo "Error: Could not find activation script in .venv directory."
        exit 1
    fi
    
    # Provide instructions for activating the virtual environment
    echo ""
    echo "Virtual environment setup complete."
    echo "To activate the virtual environment, run:"
    echo "source $ACTIVATE_SCRIPT"
    echo ""
    echo "After activation, your prompt will change to show (.venv) prefix."
    echo "To deactivate later, simply type 'deactivate'."
    echo ""
    
    # Offer to activate the environment now
    read -p "Would you like to activate the virtual environment now? (y/n): " ACTIVATE_NOW
    if [[ $ACTIVATE_NOW == "y" || $ACTIVATE_NOW == "Y" ]]; then
        echo "Activating virtual environment..."
        source "$ACTIVATE_SCRIPT"
        echo "Virtual environment activated. You can now run Python commands within this environment."
        echo "To deactivate the virtual environment when finished, type 'deactivate'."
    else
        echo "Virtual environment not activated. Activate manually when needed."
    fi
else
    echo "Warning: Virtual environment directory '.venv' not found."
fi