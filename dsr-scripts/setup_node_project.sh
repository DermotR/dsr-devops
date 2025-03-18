#!/bin/bash
#
# setup_node_project.sh - Bash script for Node.js project setup
#
# This script sets up a standardized Node.js project with client-server structure,
# package.json files, and GitHub repository.
#
# Usage:
#   ./dsr-scripts/setup_node_project.sh [project_name] [--no-github] [--public] [--client-framework <framework>]
#
# Example:
#   ./dsr-scripts/setup_node_project.sh
#   ./dsr-scripts/setup_node_project.sh my-custom-name
#   ./dsr-scripts/setup_node_project.sh --no-github
#   ./dsr-scripts/setup_node_project.sh --public
#   ./dsr-scripts/setup_node_project.sh --client-framework react
#
# Note: If project_name is not provided, the parent folder name will be used.
#

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Default to parent folder name for project name
PARENT_FOLDER=$(basename "$PARENT_DIR")
# Convert spaces and underscores to hyphens, make lowercase
SANITIZED_FOLDER=$(echo "$PARENT_FOLDER" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')
PROJECT_NAME="$SANITIZED_FOLDER"
PROJECT_DIR="$PARENT_DIR"

# Parse command line arguments
if [ $# -ge 1 ]; then
    # Check if first argument doesn't start with -- (not a flag)
    if [[ "$1" != --* ]]; then
        PROJECT_NAME="$1"
        shift # Remove the first argument (project name)
    fi
fi

# Default values
USE_GITHUB=true
REPO_VISIBILITY="private"
CLIENT_FRAMEWORK=""

# Parse command line arguments
shift # Remove the first argument (prefix)
while (( "$#" )); do
    case "$1" in
        --no-github)
            USE_GITHUB=false
            shift
            ;;
        --public)
            REPO_VISIBILITY="public"
            shift
            ;;
        --client-framework)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                CLIENT_FRAMEWORK=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            shift
            ;;
    esac
done

echo "Setting up Node.js project with name: $PROJECT_NAME in parent directory ($PARENT_DIR)"

# Function to setup client framework specific settings
setup_client_framework() {
    case "$CLIENT_FRAMEWORK" in
        react)
            CLIENT_START_COMMAND="react-scripts start"
            CLIENT_BUILD_COMMAND="react-scripts build"
            CLIENT_TEST_COMMAND="react-scripts test"
            echo "Setting up React client..."
            
            # Add React specific dependencies to client package.json
            sed -i '' -e 's/"axios": "^1.4.0"/"axios": "^1.4.0",\n    "react": "^18.2.0",\n    "react-dom": "^18.2.0",\n    "react-scripts": "5.0.1"/' "$PROJECT_DIR/client/package.json"
            
            # Create React specific files
            mkdir -p "$PROJECT_DIR/client/public" "$PROJECT_DIR/client/src"
            whaty 
            # Create index.html
            cat > "$PROJECT_DIR/client/public/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="$PROJECT_NAME - React application" />
    <title>$PROJECT_NAME</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
            
            # Create App.js
            cat > "$PROJECT_DIR/client/src/App.js" << EOF
import React from 'react';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <h1>$PROJECT_NAME</h1>
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
      </header>
    </div>
  );
}

export default App;
EOF
            
            # Create index.js
            cat > "$PROJECT_DIR/client/src/index.js" << EOF
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF
            ;;
            
        vue)
            CLIENT_START_COMMAND="vue-cli-service serve"
            CLIENT_BUILD_COMMAND="vue-cli-service build"
            CLIENT_TEST_COMMAND="vue-cli-service test:unit"
            echo "Setting up Vue client..."
            
            # Add Vue specific dependencies to client package.json
            sed -i '' -e 's/"axios": "^1.4.0"/"axios": "^1.4.0",\n    "vue": "^3.2.47",\n    "@vue\/cli-service": "~5.0.8"/' "$PROJECT_DIR/client/package.json"
            
            # Create Vue specific files (minimal setup)
            mkdir -p "$PROJECT_DIR/client/public" "$PROJECT_DIR/client/src"
            
            # Create index.html
            cat > "$PROJECT_DIR/client/public/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width,initial-scale=1.0">
    <title>$PROJECT_NAME</title>
  </head>
  <body>
    <noscript>
      <strong>We're sorry but this app doesn't work properly without JavaScript enabled. Please enable it to continue.</strong>
    </noscript>
    <div id="app"></div>
    <!-- built files will be auto injected -->
  </body>
</html>
EOF
            
            # Create main.js
            cat > "$PROJECT_DIR/client/src/main.js" << EOF
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
EOF
            
            # Create App.vue
            cat > "$PROJECT_DIR/client/src/App.vue" << EOF
<template>
  <div id="app">
    <header>
      <h1>$PROJECT_NAME</h1>
      <p>
        Edit <code>src/App.vue</code> and save to reload.
      </p>
    </header>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>
EOF
            ;;
            
        angular)
            CLIENT_START_COMMAND="ng serve"
            CLIENT_BUILD_COMMAND="ng build"
            CLIENT_TEST_COMMAND="ng test"
            echo "Setting up Angular client..."
            echo "Note: Angular setup is minimal. You may want to use 'ng new' for a complete setup."
            
            # Add Angular specific dependencies to client package.json
            sed -i '' -e 's/"axios": "^1.4.0"/"axios": "^1.4.0",\n    "@angular\/common": "^15.2.0",\n    "@angular\/core": "^15.2.0",\n    "@angular\/platform-browser": "^15.2.0",\n    "@angular\/platform-browser-dynamic": "^15.2.0",\n    "rxjs": "~7.8.0",\n    "zone.js": "~0.12.0"/' "$PROJECT_DIR/client/package.json"
            
            # Create a minimal Angular structure
            mkdir -p "$PROJECT_DIR/client/src/app"
            
            # Create index.html
            cat > "$PROJECT_DIR/client/src/index.html" << EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>$PROJECT_NAME</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF
            
            # Create main.ts
            cat > "$PROJECT_DIR/client/src/main.ts" << EOF
import { platformBrowserDynamic } from '@angular/platform-browser-dynamic';
import { AppModule } from './app/app.module';

platformBrowserDynamic().bootstrapModule(AppModule)
  .catch(err => console.error(err));
EOF
            
            # Create app.module.ts
            cat > "$PROJECT_DIR/client/src/app/app.module.ts" << EOF
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { AppComponent } from './app.component';

@NgModule({
  declarations: [
    AppComponent
  ],
  imports: [
    BrowserModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
EOF
            
            # Create app.component.ts
            cat > "$PROJECT_DIR/client/src/app/app.component.ts" << EOF
import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  template: \`
    <div>
      <h1>$PROJECT_NAME</h1>
      <p>
        Edit <code>src/app/app.component.ts</code> and save to reload.
      </p>
    </div>
  \`
})
export class AppComponent {
  title = '$PROJECT_NAME';
}
EOF
            ;;
            
        *)
            # Default to vanilla JS
            CLIENT_START_COMMAND="echo \"No start command configured. Add your preferred command to package.json\""
            CLIENT_BUILD_COMMAND="echo \"No build command configured. Add your preferred command to package.json\""
            CLIENT_TEST_COMMAND="echo \"No test command configured. Add your preferred command to package.json\""
            echo "Setting up vanilla JavaScript client..."
            
            # Create minimal structure
            mkdir -p "$PROJECT_DIR/client/src" "$PROJECT_DIR/client/public"
            
            # Create index.html
            cat > "$PROJECT_DIR/client/public/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PROJECT_NAME</title>
</head>
<body>
    <h1>$PROJECT_NAME</h1>
    <p>Edit src/index.js and public/index.html to get started</p>
    
    <script src="../src/index.js"></script>
</body>
</html>
EOF
            
            # Create index.js
            cat > "$PROJECT_DIR/client/src/index.js" << EOF
// Client entry point
console.log('$PROJECT_NAME client application started');

// Add your JavaScript code here
EOF
            ;;
    esac
}

# Function to check GitHub CLI availability
check_github_cli() {
    if ! command -v gh &> /dev/null; then
        echo "Warning: GitHub CLI (gh) not found."
        echo "You can install it from: https://cli.github.com/"
        echo "Continuing without GitHub integration..."
        echo "To skip this check in the future, use --no-github flag."
        echo ""
        
        USE_GITHUB=false
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
                    USE_GITHUB=false
                fi
            else
                echo "Continuing without GitHub integration..."
                USE_GITHUB=false
            fi
        fi
    fi
}

# Main function
main() {
    echo "Setting up Node.js project: $PROJECT_NAME"
    
    # Check GitHub CLI if needed
    if $USE_GITHUB; then
        check_github_cli
    fi
    
    # Check if directory is empty enough to proceed
    if [ "$(ls -A $PROJECT_DIR | grep -v -E '^\.|^dsr-scripts$' | wc -l)" -ne 0 ]; then
        echo "Warning: Directory $PROJECT_DIR is not empty (excluding dsr-scripts folder)."
        read -p "Do you want to continue anyway? Files may be overwritten. (y/n): " CONTINUE
        if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
            echo "Setup aborted."
            exit 1
        fi
    fi
    
    # Create directory structure
    echo "Creating project structure..."
    mkdir -p "$PROJECT_DIR/client" "$PROJECT_DIR/server" "$PROJECT_DIR/shared"
    
    # Copy template files
    echo "Copying template files..."
    cp -r "$TEMPLATES_DIR/node-fullstack"/* "$PROJECT_DIR/"
    cp "$TEMPLATES_DIR/node-fullstack/.gitignore" "$PROJECT_DIR/"
    
    # Set up client framework specific code
    setup_client_framework
    
    # Configure server
    SERVER_START_COMMAND="nodemon src/index.js"
    SERVER_BUILD_COMMAND="echo \"No build command configured. Add your preferred command to package.json\""
    SERVER_TEST_COMMAND="echo \"No test command configured. Add your preferred command to package.json\""
    
    # Configure shared
    SHARED_BUILD_COMMAND="echo \"No build command configured. Add your preferred command to package.json\""
    SHARED_TEST_COMMAND="echo \"No test command configured. Add your preferred command to package.json\""
    
    # Replace placeholders in files
    echo "Configuring project files..."
    
    # Replace in root package.json
    sed -i '' -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_DIR/package.json"
    sed -i '' -e "s/{{PROJECT_DESCRIPTION}}/$PROJECT_NAME - A Node.js client-server application/g" "$PROJECT_DIR/package.json"
    
    # Replace in client package.json
    sed -i '' -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_DIR/client/package.json"
    sed -i '' -e "s/{{CLIENT_START_COMMAND}}/$CLIENT_START_COMMAND/g" "$PROJECT_DIR/client/package.json"
    sed -i '' -e "s/{{CLIENT_BUILD_COMMAND}}/$CLIENT_BUILD_COMMAND/g" "$PROJECT_DIR/client/package.json"
    sed -i '' -e "s/{{CLIENT_TEST_COMMAND}}/$CLIENT_TEST_COMMAND/g" "$PROJECT_DIR/client/package.json"
    
    # Replace in server package.json
    sed -i '' -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_DIR/server/package.json"
    sed -i '' -e "s/{{SERVER_START_COMMAND}}/$SERVER_START_COMMAND/g" "$PROJECT_DIR/server/package.json"
    sed -i '' -e "s/{{SERVER_BUILD_COMMAND}}/$SERVER_BUILD_COMMAND/g" "$PROJECT_DIR/server/package.json"
    sed -i '' -e "s/{{SERVER_TEST_COMMAND}}/$SERVER_TEST_COMMAND/g" "$PROJECT_DIR/server/package.json"
    
    # Replace in shared package.json
    sed -i '' -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_DIR/shared/package.json"
    sed -i '' -e "s/{{SHARED_BUILD_COMMAND}}/$SHARED_BUILD_COMMAND/g" "$PROJECT_DIR/shared/package.json"
    sed -i '' -e "s/{{SHARED_TEST_COMMAND}}/$SHARED_TEST_COMMAND/g" "$PROJECT_DIR/shared/package.json"
    
    # Replace in README.md
    sed -i '' -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$PROJECT_DIR/README.md"
    sed -i '' -e "s/{{PROJECT_DESCRIPTION}}/$PROJECT_NAME - A Node.js client-server application/g" "$PROJECT_DIR/README.md"
    sed -i '' -e "s|{{REPO_URL}}|https://github.com/yourusername/$PROJECT_NAME.git|g" "$PROJECT_DIR/README.md"
    
    # Initialize git repo
    echo "Initializing git repository..."
    cd "$PROJECT_DIR"
    git init
    
    # Make sure .gitignore exists and excludes dsr-scripts directory
    if ! grep -q "dsr-scripts/" "$PROJECT_DIR/.gitignore"; then
        echo "" >> "$PROJECT_DIR/.gitignore"
        echo "# DSR DevOps scripts" >> "$PROJECT_DIR/.gitignore"
        echo "dsr-scripts/" >> "$PROJECT_DIR/.gitignore"
    fi
    
    # Create a temporary .git/info/exclude to ensure dsr-scripts is excluded
    mkdir -p "$PROJECT_DIR/.git/info"
    echo "dsr-scripts/" >> "$PROJECT_DIR/.git/info/exclude"
    
    # Add files in a more compatible way
    echo "Adding files to git..."
    # First add .gitignore to make sure it's respected
    git add .gitignore
    # Then add everything else (letting .gitignore exclude the dsr-scripts directory)
    git add .
    
    git commit -m "Initial commit: $PROJECT_NAME project structure"
    
    # Set up GitHub repository if requested
    if $USE_GITHUB; then
        echo "Setting up GitHub repository..."
        gh repo create "$PROJECT_NAME" "--$REPO_VISIBILITY" --source=. --remote=origin
        git push -u origin main
        
        # Update README with actual repo URL
        REPO_URL=$(gh repo view --json url -q .url)
        sed -i '' -e "s|https://github.com/yourusername/$PROJECT_NAME.git|$REPO_URL|g" "$PROJECT_DIR/README.md"
        git add README.md
        git commit -m "Update README with actual repository URL"
        git push
        
        echo "GitHub repository created: $REPO_URL"
    fi
    
    echo -e "\nProject setup complete for $PROJECT_NAME!"
    echo "Directory: $PROJECT_DIR"
    
    echo -e "\nTo start developing:"
    echo "cd $(basename "$PROJECT_DIR")"
    echo "npm install"
    echo "npm start"
}

# Run the main function
main