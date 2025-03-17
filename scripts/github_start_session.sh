#!/bin/bash
#
# github_start_session.sh - Script to prepare the environment at the start of a coding session
#
# This script pulls the latest code from GitHub, checks for any conflicts,
# ensures all dependencies are installed, and performs environment checks.
#
# Usage:
#   ./github_start_session.sh [branch_name]
#
# Example:
#   ./github_start_session.sh
#   ./github_start_session.sh feature/new-module
#

set -e  # Exit immediately if a command exits with a non-zero status

# Default to current branch if not specified
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Check if branch name is provided
if [ $# -ge 1 ]; then
    BRANCH_NAME="$1"
fi

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: Not in a git repository."
        echo "Please run this script from within a git repository."
        exit 1
    fi
}

# Function to check if the working directory is clean
check_working_directory() {
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Warning: You have uncommitted changes in your working directory."
        git status
        
        echo -e "\nOptions:"
        echo "1. Stash changes (recommended)"
        echo "2. Continue anyway (might cause conflicts)"
        echo "3. Cancel"
        read -p "Choose an option (1-3): " CHOICE
        
        case $CHOICE in
            1)
                echo "Stashing changes..."
                STASH_MSG="Automatic stash by github_start_session.sh on $(date '+%Y-%m-%d %H:%M')"
                git stash push -m "$STASH_MSG"
                echo "Changes stashed. You can recover them later with 'git stash pop'."
                ;;
            2)
                echo "Continuing with uncommitted changes. Be prepared for potential conflicts."
                ;;
            3)
                echo "Operation cancelled. Please commit or stash your changes manually."
                exit 0
                ;;
            *)
                echo "Invalid option. Operation cancelled."
                exit 1
                ;;
        esac
    fi
}

# Function to check for and setup remote repository
check_remote() {
    if ! git remote get-url origin &>/dev/null; then
        echo "Warning: No remote repository 'origin' found."
        
        if command -v gh &>/dev/null; then
            if gh auth status &>/dev/null; then
                echo "Would you like to connect to a GitHub repository? (y/n): "
                read -r CONNECT_REPO
                if [[ $CONNECT_REPO == "y" || $CONNECT_REPO == "Y" ]]; then
                    echo "Enter the GitHub repository URL or owner/name: "
                    read -r REPO_URL
                    
                    # Handle the case where user inputs 'owner/repo' format
                    if [[ ! $REPO_URL == *"://"* && ! $REPO_URL == git@* ]]; then
                        REPO_URL="https://github.com/$REPO_URL.git"
                    fi
                    
                    echo "Connecting to repository: $REPO_URL"
                    git remote add origin "$REPO_URL"
                    git fetch origin
                    echo "Repository connected as 'origin'."
                fi
            fi
        else
            echo "GitHub CLI not available. Please set up remote manually."
            echo "git remote add origin <repository-url>"
            exit 1
        fi
    fi
}

# Function to synchronize with remote repository
sync_with_remote() {
    echo "Fetching updates from remote repository..."
    git fetch origin
    
    # Check if the local branch exists
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        # Check if the branch exists on the remote
        if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
            echo "Checking for updates to branch '$BRANCH_NAME'..."
            
            # Check if local is behind remote
            LOCAL=$(git rev-parse "$BRANCH_NAME")
            REMOTE=$(git rev-parse "origin/$BRANCH_NAME")
            BASE=$(git merge-base "$BRANCH_NAME" "origin/$BRANCH_NAME")
            
            if [ "$LOCAL" = "$REMOTE" ]; then
                echo "Branch '$BRANCH_NAME' is up to date."
            elif [ "$LOCAL" = "$BASE" ]; then
                echo "Your branch is behind the remote. Pulling changes..."
                git pull --ff-only origin "$BRANCH_NAME"
            else
                if [ "$REMOTE" = "$BASE" ]; then
                    echo "Your branch is ahead of remote. Consider pushing your changes."
                else
                    echo "Warning: Your branch has diverged from the remote."
                    echo "Options:"
                    echo "1. Pull with rebase (recommended for local changes)"
                    echo "2. Pull with merge"
                    echo "3. Skip update (handle manually later)"
                    read -p "Choose an option (1-3): " PULL_OPTION
                    
                    case $PULL_OPTION in
                        1)
                            echo "Pulling with rebase..."
                            git pull --rebase origin "$BRANCH_NAME"
                            ;;
                        2)
                            echo "Pulling with merge..."
                            git pull origin "$BRANCH_NAME"
                            ;;
                        3)
                            echo "Skipping update. Remember to resolve this manually."
                            ;;
                        *)
                            echo "Invalid option. Skipping update."
                            ;;
                    esac
                fi
            fi
        else
            echo "Branch '$BRANCH_NAME' doesn't exist on remote."
            echo "This appears to be a local branch only."
        fi
    else
        echo "Branch '$BRANCH_NAME' doesn't exist locally."
        
        # Check if it exists on remote
        if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
            echo "Branch '$BRANCH_NAME' exists on remote but not locally."
            read -p "Would you like to check out this branch? (y/n): " CHECKOUT_BRANCH
            
            if [[ $CHECKOUT_BRANCH == "y" || $CHECKOUT_BRANCH == "Y" ]]; then
                echo "Checking out branch '$BRANCH_NAME'..."
                git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
            else
                echo "Staying on current branch."
                BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
                echo "Current branch is '$BRANCH_NAME'."
            fi
        else
            echo "Branch '$BRANCH_NAME' doesn't exist locally or remotely."
            read -p "Would you like to create this branch? (y/n): " CREATE_BRANCH
            
            if [[ $CREATE_BRANCH == "y" || $CREATE_BRANCH == "Y" ]]; then
                echo "Creating and checking out branch '$BRANCH_NAME'..."
                git checkout -b "$BRANCH_NAME"
            else
                echo "Staying on current branch."
                BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
                echo "Current branch is '$BRANCH_NAME'."
            fi
        fi
    fi
}

# Function to check for Python environment
check_python_environment() {
    if [ -f "requirements.txt" ]; then
        echo "Python project detected. Checking dependencies..."
        
        # Check for virtualenv
        if [ -d ".venv" ] || [ -d "venv" ] || [ -d "env" ]; then
            VENV_DIR=".venv"
            [ -d "venv" ] && VENV_DIR="venv"
            [ -d "env" ] && VENV_DIR="env"
            
            echo "Virtual environment found: $VENV_DIR"
            
            # Detect the appropriate pip path
            if [ -f "$VENV_DIR/bin/pip" ]; then
                PIP_PATH="$VENV_DIR/bin/pip"
            elif [ -f "$VENV_DIR/Scripts/pip" ]; then
                PIP_PATH="$VENV_DIR/Scripts/pip"
            else
                echo "Warning: pip not found in virtual environment."
                PIP_PATH="pip"
            fi
            
            # Ask if the user wants to update packages
            read -p "Would you like to update project dependencies? (y/n): " UPDATE_DEPS
            if [[ $UPDATE_DEPS == "y" || $UPDATE_DEPS == "Y" ]]; then
                echo "Updating dependencies..."
                $PIP_PATH install -U -r requirements.txt
                
                # Check for dev dependencies
                if [ -f "requirements-dev.txt" ]; then
                    read -p "Update development dependencies as well? (y/n): " UPDATE_DEV
                    if [[ $UPDATE_DEV == "y" || $UPDATE_DEV == "Y" ]]; then
                        echo "Updating development dependencies..."
                        $PIP_PATH install -U -r requirements-dev.txt
                    fi
                fi
            fi
        else
            echo "No virtual environment found."
            read -p "Would you like to create a virtual environment and install dependencies? (y/n): " CREATE_VENV
            
            if [[ $CREATE_VENV == "y" || $CREATE_VENV == "Y" ]]; then
                echo "Creating virtual environment in .venv..."
                python -m venv .venv
                
                if [ -f ".venv/bin/pip" ]; then
                    PIP_PATH=".venv/bin/pip"
                elif [ -f ".venv/Scripts/pip" ]; then
                    PIP_PATH=".venv/Scripts/pip"
                else
                    echo "Error: pip not found in created virtual environment."
                    exit 1
                fi
                
                echo "Installing dependencies..."
                $PIP_PATH install -U pip
                $PIP_PATH install -r requirements.txt
                
                if [ -f "requirements-dev.txt" ]; then
                    $PIP_PATH install -r requirements-dev.txt
                fi
                
                echo -e "\nVirtual environment created and dependencies installed."
                echo "To activate the virtual environment, run:"
                if [ -f ".venv/bin/activate" ]; then
                    echo "source .venv/bin/activate"
                elif [ -f ".venv/Scripts/activate" ]; then
                    echo ".venv\\Scripts\\activate"
                fi
            fi
        fi
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        echo "Python project detected. Consider reviewing your dependencies."
    fi
}

# Function to check for Node.js environment
check_node_environment() {
    if [ -f "package.json" ]; then
        echo "Node.js project detected. Checking dependencies..."
        
        # Check if we have package-lock.json or yarn.lock to determine package manager
        if [ -f "yarn.lock" ]; then
            PKG_MANAGER="yarn"
            INSTALL_CMD="yarn"
        elif [ -f "pnpm-lock.yaml" ]; then
            PKG_MANAGER="pnpm"
            INSTALL_CMD="pnpm install"
        else
            PKG_MANAGER="npm"
            INSTALL_CMD="npm install"
        fi
        
        echo "Using package manager: $PKG_MANAGER"
        
        # Ask if the user wants to update packages
        read -p "Would you like to update project dependencies? (y/n): " UPDATE_DEPS
        if [[ $UPDATE_DEPS == "y" || $UPDATE_DEPS == "Y" ]]; then
            echo "Updating dependencies..."
            $INSTALL_CMD
        fi
    fi
}

# Main function
main() {
    echo "Starting coding session..."
    
    # Check if we're in a git repository
    check_git_repo
    
    # Check if working directory is clean
    check_working_directory
    
    # Check remote setup
    check_remote
    
    # Sync with remote repository
    sync_with_remote
    
    # Check environment specific to the project type
    check_python_environment
    check_node_environment
    
    echo -e "\nCurrent git status:"
    git status
    
    echo -e "\nEnvironment is now ready for coding. Happy hacking!"
}

# Run the main function
main