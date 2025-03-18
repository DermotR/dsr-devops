#!/bin/bash
#
# setup_python_project.sh - Bash wrapper for Python project setup script
#
# This script calls the Python setup script and handles system operations like
# making the script executable and activating the virtual environment.
#
# Usage:
#   ./dsr-scripts/setup_python_project.sh [project_name] [--no-github] [--public]
#
# Example:
#   ./dsr-scripts/setup_python_project.sh
#   This will create a project based on the folder name.
#
#   ./dsr-scripts/setup_python_project.sh my-custom-name
#   This will create a project with the specified name.
#
#   ./dsr-scripts/setup_python_project.sh --no-github
#   This will create the project but skip GitHub repository creation.
#
#   ./dsr-scripts/setup_python_project.sh --public
#   This will create the project with a public GitHub repository instead of private.
#

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_SCRIPT="$SCRIPT_DIR/setup_python_project.py"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Default to parent folder name for project name
PARENT_FOLDER=$(basename "$PARENT_DIR")
# Convert spaces and underscores to hyphens, make lowercase
SANITIZED_FOLDER=$(echo "$PARENT_FOLDER" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
PROJECT_NAME="$SANITIZED_FOLDER"

# Parse command line arguments
if [ $# -ge 1 ]; then
    # Check if first argument doesn't start with -- (not a flag)
    if [[ "$1" != --* ]]; then
        PROJECT_NAME="$1"
        shift # Remove the first argument (project name)
    fi
fi

# Check for GitHub flag
GITHUB_FLAG=""
if [[ "$*" == *"--no-github"* ]]; then
    GITHUB_FLAG="--no-github"
fi

# Check for public flag
VISIBILITY_FLAG=""
if [[ "$*" == *"--public"* ]]; then
    VISIBILITY_FLAG="--public"
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

# Check if directory is empty enough to proceed
if [ "$(ls -A $PARENT_DIR | grep -v -E '^\.|^dsr-scripts$' | wc -l)" -ne 0 ]; then
    echo "Warning: Directory $PARENT_DIR is not empty (excluding dsr-scripts folder)."
    read -p "Do you want to continue anyway? Files may be overwritten. (y/n): " CONTINUE
    if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
        echo "Setup aborted."
        exit 1
    fi
fi

# Run the Python setup script from the parent directory
echo "Running Python setup script with project name: $PROJECT_NAME in parent directory: $PARENT_DIR"
cd "$PARENT_DIR"

# Only pass project name if it's a custom name (not derived from directory)
if [ "$PROJECT_NAME" != "$SANITIZED_FOLDER" ]; then
    "$PYTHON_SCRIPT" "$PROJECT_NAME" $GITHUB_FLAG $VISIBILITY_FLAG
else
    # Use default (parent directory name)
    "$PYTHON_SCRIPT" $GITHUB_FLAG $VISIBILITY_FLAG
fi

# Add .gitignore to exclude dsr-scripts directory
if [ -f "$PARENT_DIR/.gitignore" ]; then
    if ! grep -q "dsr-scripts/" "$PARENT_DIR/.gitignore"; then
        echo "" >> "$PARENT_DIR/.gitignore"
        echo "# DSR DevOps scripts" >> "$PARENT_DIR/.gitignore"
        echo "dsr-scripts/" >> "$PARENT_DIR/.gitignore"
        
        # If git is initialized, update the gitignore
        if [ -d "$PARENT_DIR/.git" ]; then
            cd "$PARENT_DIR"
            git add .gitignore
            git commit -m "Add dsr-scripts directory to .gitignore"
        fi
    fi
fi

# Activate the virtual environment
if [ -d "$PARENT_DIR/.venv" ]; then
    echo "Activating virtual environment..."
    
    # Get the correct activation script based on platform
    if [ -f "$PARENT_DIR/.venv/bin/activate" ]; then
        ACTIVATE_SCRIPT="$PARENT_DIR/.venv/bin/activate"  # Unix/Mac
    elif [ -f "$PARENT_DIR/.venv/Scripts/activate" ]; then
        ACTIVATE_SCRIPT="$PARENT_DIR/.venv/Scripts/activate"  # Windows
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
        echo "Creating activation script..."
        
        # Create a temporary activation script
        TEMP_SCRIPT=$(mktemp)
        cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
source "$ACTIVATE_SCRIPT"
cd "$PARENT_DIR"
echo "Virtual environment activated for $PROJECT_NAME. You are now in $PARENT_DIR"
echo "To deactivate the virtual environment when finished, type 'deactivate'"
exec bash
EOF
        
        chmod +x "$TEMP_SCRIPT"
        
        echo "Activating virtual environment in a new shell..."
        echo "When you're done, type 'exit' to return to your original shell."
        exec "$TEMP_SCRIPT"
    else
        echo "Virtual environment not activated. Activate manually when needed."
    fi
else
    echo "Warning: Virtual environment directory '.venv' not found."
fi