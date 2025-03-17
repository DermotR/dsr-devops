#!/bin/bash
#
# init_repo.sh - Initialize and setup the GitHub repository
#
# This script initializes a new git repository, adds all files,
# creates the initial commit, and pushes to GitHub.
#
# Usage:
#   ./init_repo.sh [visibility]
#
# Example:
#   ./init_repo.sh
#   ./init_repo.sh public
#

set -e  # Exit immediately if a command exits with a non-zero status

# Constants
REPO_NAME="dsr-devops"
GITHUB_USER="DermotR"
COMMIT_MESSAGE="Initial commit: DevOps automation scripts and tools"

# Check if visibility is provided
VISIBILITY="private"  # Default
if [ $# -ge 1 ]; then
    if [[ "$1" == "public" || "$1" == "private" ]]; then
        VISIBILITY="$1"
    else
        echo "Warning: Invalid visibility option '$1'. Using default: '$VISIBILITY'."
        echo "Valid options are 'public' or 'private'."
    fi
fi

echo "Initializing GitHub repository: $GITHUB_USER/$REPO_NAME"
echo "Visibility: $VISIBILITY"

# Check if gh CLI is available
if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI (gh) not found."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated with GitHub
if ! gh auth status &>/dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Please run 'gh auth login' to authenticate."
    exit 1
fi

# Initialize git if not already a repository
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
fi

# Ensure scripts are executable
echo "Making scripts executable..."
chmod +x scripts/*.sh

# Add all files
echo "Adding files to git..."
git add .

# Initial commit
echo "Creating initial commit..."
git commit -m "$COMMIT_MESSAGE"

# Create GitHub repository
echo "Creating GitHub repository: $GITHUB_USER/$REPO_NAME..."
gh repo create "$GITHUB_USER/$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin

# Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main

# Display repository URL
REPO_URL=$(gh repo view --json url -q .url)
echo -e "\nRepository created successfully!"
echo "Repository URL: $REPO_URL"
echo -e "\nSetup complete! Your DSR DevOps repository is ready to use."