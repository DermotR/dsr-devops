#!/bin/bash
#
# github_checkin.sh - Script to check in code to GitHub at the end of a session
#
# This script helps automate the process of committing and pushing changes to GitHub.
# It handles adding files, creating a commit with a message, and pushing to the remote repository.
#
# Usage:
#   ./dsr-scripts/github_checkin.sh [commit_message] [branch_name] [visibility]
#
# Example:
#   ./dsr-scripts/github_checkin.sh "Add new feature"
#   ./dsr-scripts/github_checkin.sh "Fix bug in login form" feature/login-fix
#

set -e  # Exit immediately if a command exits with a non-zero status

# Script directory and parent directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
COMMIT_MESSAGE="Session update $(date '+%Y-%m-%d %H:%M')"
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
REPO_VISIBILITY="private"  # Default to private repository

# Check if commit message is provided
if [ $# -ge 1 ]; then
    COMMIT_MESSAGE="$1"
fi

# Check if branch name is provided
if [ $# -ge 2 ]; then
    BRANCH_NAME="$2"
fi

# Check if visibility is provided
if [ $# -ge 3 ]; then
    if [[ "$3" == "public" || "$3" == "private" ]]; then
        REPO_VISIBILITY="$3"
    else
        echo "Warning: Invalid visibility option '$3'. Using default: 'private'."
        echo "Valid options are 'public' or 'private'."
    fi
fi

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: Not in a git repository."
        echo "Please run this script from within a git repository."
        exit 1
    fi
}

# Function to check GitHub CLI availability
check_github_cli() {
    if ! command -v gh &>/dev/null; then
        echo "Warning: GitHub CLI (gh) not found."
        echo "You can install it from: https://cli.github.com/"
        echo "Continuing without using GitHub CLI-specific features..."
        return 1
    fi
    
    # Check if authenticated
    if ! gh auth status &>/dev/null; then
        echo "Warning: Not authenticated with GitHub CLI."
        echo "Run 'gh auth login' to authenticate."
        return 1
    fi
    
    return 0
}

# Function to check if remote repository exists
check_remote() {
    if ! git remote get-url origin &>/dev/null; then
        echo "Warning: No remote repository 'origin' found."
        
        if check_github_cli; then
            echo "Would you like to create a GitHub repository? (y/n): "
            read -r CREATE_REPO
            if [[ $CREATE_REPO == "y" || $CREATE_REPO == "Y" ]]; then
                # Use the parent directory name for the repository name
                REPO_NAME=$(basename "$PARENT_DIR" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
                echo "Creating GitHub repository '$REPO_NAME' with visibility: $REPO_VISIBILITY..."
                cd "$PARENT_DIR"
                gh repo create "$REPO_NAME" "--$REPO_VISIBILITY" --source=. --remote=origin
                echo "GitHub repository created and connected as 'origin'."
            else
                echo "Skipping repository creation."
                echo "You'll need to manually push your changes later."
            fi
        else
            echo "You'll need to manually set up a remote repository."
            echo "git remote add origin <repository-url>"
        fi
    fi
}

# Main function
main() {
    echo "Starting GitHub check-in process..."
    
    # Change to parent directory
    cd "$PARENT_DIR"
    
    # Check if we're in a git repository
    check_git_repo
    
    # Check if remote exists
    check_remote
    
    # Show status
    echo -e "\nCurrent git status:"
    git status
    
    echo -e "\nShowing changes to be committed:"
    git diff --stat
    
    # Confirm with user
    echo -e "\nReady to commit the above changes with message: '$COMMIT_MESSAGE'"
    echo "Proceed? (y/n): "
    read -r PROCEED
    
    if [[ $PROCEED != "y" && $PROCEED != "Y" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
    
    # Add all changes
    echo -e "\nAdding all changes..."
    git add .
    
    # Create commit
    echo "Creating commit..."
    git commit -m "$COMMIT_MESSAGE"
    
    # Check if we need to switch to the specified branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]]; then
        echo "Current branch is '$CURRENT_BRANCH', but target branch is '$BRANCH_NAME'."
        echo "Would you like to switch to '$BRANCH_NAME'? (y/n): "
        read -r SWITCH_BRANCH
        
        if [[ $SWITCH_BRANCH == "y" || $SWITCH_BRANCH == "Y" ]]; then
            # Check if branch exists
            if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
                echo "Switching to existing branch '$BRANCH_NAME'..."
                git checkout "$BRANCH_NAME"
                # Merge changes from the original branch
                echo "Merging changes from '$CURRENT_BRANCH'..."
                git merge "$CURRENT_BRANCH"
            else
                echo "Creating and switching to new branch '$BRANCH_NAME'..."
                git checkout -b "$BRANCH_NAME"
            fi
        fi
    fi
    
    # Push to remote if it exists
    if git remote get-url origin &>/dev/null; then
        echo "Pushing to remote repository..."
        git push -u origin "$BRANCH_NAME"
        echo "Changes pushed successfully!"
        
        # Show repository URL if GitHub CLI is available
        if check_github_cli; then
            REPO_URL=$(gh repo view --json url -q .url)
            echo -e "\nRepository URL: $REPO_URL"
        fi
    else
        echo -e "\nNo remote repository configured."
        echo "You'll need to push your changes manually:"
        echo "git remote add origin <repository-url>"
        echo "git push -u origin $BRANCH_NAME"
    fi
    
    echo -e "\nGitHub check-in process completed!"
}

# Run the main function
main