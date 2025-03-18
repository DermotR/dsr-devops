#!/bin/bash
#
# setup_vite_react_prisma.sh - Bash script for setting up a Vite React-TS frontend with Node.js + Prisma backend
#
# This script sets up a standardized project with Vite React-TS for the frontend
# and a Node.js backend with Prisma ORM, along with a GitHub repository.
#
# Usage:
#   ./dsr-scripts/setup_vite_react_prisma.sh [project_name] [--no-github] [--public]
#
# Example:
#   ./dsr-scripts/setup_vite_react_prisma.sh
#   ./dsr-scripts/setup_vite_react_prisma.sh my-custom-name
#   ./dsr-scripts/setup_vite_react_prisma.sh --no-github
#   ./dsr-scripts/setup_vite_react_prisma.sh --public
#
# Note: If project_name is not provided, the parent folder name will be used.
#

set -e  # Exit immediately if a command exits with a non-zero status

# Get the absolute path of the script directory with better macOS compatibility
get_script_path() {
    local source="${BASH_SOURCE[0]}"
    
    # Handle different flavors of readlink
    if command -v readlink >/dev/null 2>&1; then
        # Try GNU readlink -f first (Linux)
        if readlink -f "$source" >/dev/null 2>&1; then
            echo "$(readlink -f "$source")"
            return
        fi
        
        # Try MacOS/BSD approach if GNU readlink -f fails
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        local file="$(basename "$source")"
        echo "$dir/$file"
        return
    fi

    # Fallback if readlink is not available
    local dir="$(cd -P "$(dirname "$source")" && pwd)"
    local file="$(basename "$source")"
    echo "$dir/$file"
}

SCRIPT_PATH=$(get_script_path)
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Get the parent directory that contains the script directory
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Validate parent directory
if [[ "$PARENT_DIR" == */.Trash* || "$PARENT_DIR" == */.trash* ]]; then
    echo "Error: Script appears to be running from a trash directory."
    echo "Please move the dsr-scripts directory to your project directory and try again."
    exit 1
fi

# Verify that the script directory is named 'dsr-scripts'
if [[ "$(basename "$SCRIPT_DIR")" != "dsr-scripts" ]]; then
    echo "Warning: The script directory is not named 'dsr-scripts' but '$(basename "$SCRIPT_DIR")'."
    echo "This may cause unexpected behavior. Consider renaming the directory."
    echo ""
    read -p "Continue anyway? (y/n): " CONTINUE_WRONG_DIR
    if [[ $CONTINUE_WRONG_DIR != "y" && $CONTINUE_WRONG_DIR != "Y" ]]; then
        echo "Setup aborted."
        exit 1
    fi
fi

# Verify that the script directory exists and is a directory
if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "Error: The script directory '$SCRIPT_DIR' does not exist or is not a directory."
    exit 1
fi

# Check if script is being run from within the dsr-scripts directory
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == "$SCRIPT_DIR" ]]; then
    echo "Error: This script should be run from the parent directory, not from within dsr-scripts."
    echo "Please change to your project directory and run: ./dsr-scripts/$(basename "$0")"
    exit 1
fi

# Default to parent folder name for project name
PARENT_FOLDER=$(basename "$PARENT_DIR")
echo "Parent directory detected as: $PARENT_DIR"
echo "Parent folder name is: $PARENT_FOLDER"

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

# Parse command line arguments
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
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            shift
            ;;
    esac
done

echo "Setting up Vite React-TS + Node.js/Prisma project with name: $PROJECT_NAME in parent directory ($PARENT_DIR)"

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
    echo "Setting up Vite React-TS + Node.js/Prisma project: $PROJECT_NAME"
    
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
    
    # Create frontend using Vite
    echo "Creating frontend using Vite with React + TypeScript..."
    cd "$PROJECT_DIR"
    npm create vite@latest frontend -- --template react-ts
    
    # Set up frontend
    echo "Setting up frontend..."
    cd "$PROJECT_DIR/frontend"
    npm install
    
    # Install axios for API requests
    npm install axios
    
    # Create API service file
    echo "Creating API service file..."
    mkdir -p "$PROJECT_DIR/frontend/src/services"
    cat > "$PROJECT_DIR/frontend/src/services/api.ts" << EOF
import axios from 'axios';

const API_URL = 'http://localhost:8080';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

// User related API calls
export const userApi = {
  // Get all users
  getUsers: async () => {
    try {
      const response = await api.get('/api/users');
      return response.data;
    } catch (error) {
      console.error('Error fetching users:', error);
      throw error;
    }
  },
  
  // Create new user
  createUser: async (userData: { name: string; email: string }) => {
    try {
      const response = await api.post('/api/users', userData);
      return response.data;
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }
};

// Health check
export const healthCheck = async () => {
  try {
    const response = await api.get('/');
    return response.data;
  } catch (error) {
    console.error('API health check failed:', error);
    throw error;
  }
};

export default api;
EOF
    
    # Update App.tsx with example usage
    echo "Updating App.tsx with API example..."
    cat > "$PROJECT_DIR/frontend/src/App.tsx" << EOF
import { useState, useEffect } from 'react'
import './App.css'
import { healthCheck, userApi } from './services/api'

// User type definition
interface User {
  id: number;
  name: string | null;
  email: string;
  createdAt: string;
  updatedAt: string;
}

function App() {
  const [apiStatus, setApiStatus] = useState<string>('Checking API connection...');
  const [users, setUsers] = useState<User[]>([]);
  const [newUser, setNewUser] = useState({ name: '', email: '' });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Check API connection on component mount
  useEffect(() => {
    const checkApiConnection = async () => {
      try {
        const response = await healthCheck();
        setApiStatus(\`API connected: \${response.message}\`);
        
        // Load users after confirming API connection
        loadUsers();
      } catch (err) {
        setApiStatus('API connection failed. Make sure the backend server is running.');
        setLoading(false);
        setError('Failed to connect to API');
      }
    };
    
    checkApiConnection();
  }, []);
  
  // Load users from API
  const loadUsers = async () => {
    try {
      setLoading(true);
      const data = await userApi.getUsers();
      setUsers(data);
      setError(null);
    } catch (err) {
      setError('Failed to load users');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };
  
  // Handle input changes
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setNewUser(prev => ({ ...prev, [name]: value }));
  };
  
  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newUser.name || !newUser.email) {
      setError('Name and email are required');
      return;
    }
    
    try {
      setLoading(true);
      await userApi.createUser(newUser);
      setNewUser({ name: '', email: '' });
      loadUsers();
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to create user');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <h1>$PROJECT_NAME</h1>
      
      <div className="api-status">
        <p>{apiStatus}</p>
      </div>
      
      <div className="card">
        <h2>Add New User</h2>
        {error && <p className="error">{error}</p>}
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="name">Name:</label>
            <input
              type="text"
              id="name"
              name="name"
              value={newUser.name}
              onChange={handleInputChange}
              placeholder="Enter name"
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="email">Email:</label>
            <input
              type="email"
              id="email"
              name="email"
              value={newUser.email}
              onChange={handleInputChange}
              placeholder="Enter email"
            />
          </div>
          
          <button type="submit" disabled={loading}>
            {loading ? 'Processing...' : 'Add User'}
          </button>
        </form>
      </div>
      
      <div className="card">
        <h2>Users</h2>
        {loading && <p>Loading...</p>}
        
        {users.length === 0 && !loading ? (
          <p>No users found. Add one above!</p>
        ) : (
          <ul className="user-list">
            {users.map(user => (
              <li key={user.id}>
                <strong>{user.name || 'Unnamed'}</strong>
                <span>{user.email}</span>
                <span className="user-date">
                  {new Date(user.createdAt).toLocaleDateString()}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}

export default App
EOF

    # Create basic CSS file
    echo "Creating App CSS..."
    cat > "$PROJECT_DIR/frontend/src/App.css" << EOF
#root {
  max-width: 1280px;
  margin: 0 auto;
  padding: 2rem;
}

.container {
  font-family: system-ui, -apple-system, sans-serif;
  max-width: 800px;
  margin: 0 auto;
}

.card {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 20px;
  margin: 20px 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.api-status {
  padding: 10px;
  border-radius: 4px;
  background-color: #e6f7ff;
  margin-bottom: 20px;
}

.error {
  color: #d32f2f;
  background-color: #ffebee;
  padding: 10px;
  border-radius: 4px;
  margin-bottom: 10px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

button {
  background-color: #0070f3;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 10px 15px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.3s;
}

button:hover {
  background-color: #005cc5;
}

button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.user-list {
  list-style: none;
  padding: 0;
}

.user-list li {
  padding: 10px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.user-list li:last-child {
  border-bottom: none;
}

.user-date {
  color: #777;
  font-size: 14px;
}
EOF
    
    # Create backend directory
    echo "Creating backend directory structure..."
    mkdir -p "$PROJECT_DIR/backend/src/controllers"
    mkdir -p "$PROJECT_DIR/backend/src/routes"
    mkdir -p "$PROJECT_DIR/backend/src/models"
    
    # Initialize backend package.json
    echo "Initializing backend package.json..."
    cd "$PROJECT_DIR/backend"
    npm init -y
    
    # Update backend package.json with necessary scripts and dependencies
    sed -i '' 's/"main": "index.js"/"main": "dist\/index.js"/' package.json
    sed -i '' 's/"test": "echo \\"Error: no test specified\\" && exit 1"/"start": "node dist\/index.js",\n    "dev": "nodemon src\/index.ts",\n    "build": "tsc",\n    "lint": "eslint src --ext .ts",\n    "prisma:generate": "prisma generate",\n    "prisma:migrate": "prisma migrate dev",\n    "prisma:studio": "prisma studio"/' package.json
    
    # Install backend dependencies
    echo "Installing backend dependencies..."
    npm install express cors dotenv
    npm install -D typescript ts-node nodemon @types/node @types/express @types/cors prisma
    npm install @prisma/client
    
    # Create tsconfig.json for backend
    echo "Creating tsconfig.json for backend..."
    cat > "$PROJECT_DIR/backend/tsconfig.json" << EOF
{
  "compilerOptions": {
    "target": "es2019",
    "module": "commonjs",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
EOF
    
    # Create .env file for backend
    echo "Creating .env file for backend..."
    cat > "$PROJECT_DIR/backend/.env" << EOF
PORT=8080
DATABASE_URL="file:./dev.db"
EOF
    
    # Initialize Prisma
    echo "Initializing Prisma..."
    npx prisma init --datasource-provider sqlite
    
    # Update the Prisma schema with our User model
    echo "Updating Prisma schema with User model..."
    cat > "$PROJECT_DIR/backend/prisma/schema.prisma" << EOF
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
EOF

    # Generate Prisma client and create migrations
    echo "Generating Prisma client..."
    cd "$PROJECT_DIR/backend"
    npx prisma generate
    
    # Create initial migration and apply it
    echo "Creating and applying initial Prisma migration..."
    npx prisma migrate dev --name init_user_model --create-only
    npx prisma migrate deploy
    
    # Create server entry point file
    echo "Creating server entry point file..."
    cat > "$PROJECT_DIR/backend/src/index.ts" << EOF
import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

// Load environment variables
dotenv.config();

// Initialize Prisma client
const prisma = new PrismaClient();

// Create Express application
const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors({
  origin: 'http://localhost:5173', // Frontend Vite default port
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true
}));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to $PROJECT_NAME API' });
});

// User routes
app.get('/api/users', async (req, res) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching users' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    const newUser = await prisma.user.create({
      data: {
        name,
        email,
      },
    });
    res.status(201).json(newUser);
  } catch (error) {
    res.status(500).json({ error: 'Error creating user' });
  }
});

// Start server
app.listen(port, () => {
  console.log(\`Server running on port \${port}\`);
});

// Handle shutdown
process.on('SIGINT', async () => {
  await prisma.\$disconnect();
  process.exit(0);
});
EOF
    
    # Create root package.json for the entire project
    echo "Creating root package.json..."
    cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A Vite React-TS frontend with Node.js + Prisma backend",
  "main": "index.js",
  "scripts": {
    "frontend": "cd frontend && npm run dev",
    "backend": "cd backend && npm run dev",
    "dev": "concurrently \"npm run frontend\" \"npm run backend\"",
    "build:frontend": "cd frontend && npm run build",
    "build:backend": "cd backend && npm run build",
    "build": "npm run build:frontend && npm run build:backend",
    "prisma:generate": "cd backend && npm run prisma:generate",
    "prisma:migrate": "cd backend && npm run prisma:migrate",
    "prisma:studio": "cd backend && npm run prisma:studio"
  },
  "keywords": ["vite", "react", "typescript", "node", "prisma"],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "concurrently": "^8.0.1"
  }
}
EOF
    
    # Install concurrently for running both frontend and backend
    echo "Installing concurrently..."
    cd "$PROJECT_DIR"
    npm install
    
    # Create README.md
    echo "Creating README.md..."
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

A full-stack TypeScript project with Vite React frontend and Node.js + Prisma backend.

## Project Structure

- \`/frontend\`: Vite React TypeScript application
- \`/backend\`: Node.js Express API with Prisma ORM
  - \`/prisma\`: Prisma schema and migrations
  - \`/src\`: TypeScript source code

## Getting Started

### Prerequisites

- Node.js (v14+)
- npm or yarn

### Installation

1. Clone the repository:
   \`\`\`bash
   git clone [repository_url]
   cd $PROJECT_NAME
   \`\`\`

2. Install dependencies:
   \`\`\`bash
   npm install
   cd frontend && npm install
   cd ../backend && npm install
   \`\`\`

3. Set up the database:
   \`\`\`bash
   cd backend
   npm run prisma:migrate
   npm run prisma:generate
   \`\`\`

### Development

Run both frontend and backend simultaneously:
\`\`\`bash
npm run dev
\`\`\`

Or run them separately:
\`\`\`bash
# Frontend (Vite React)
npm run frontend

# Backend (Node + Express + Prisma)
npm run backend
\`\`\`

#### Database Management
Open Prisma Studio (database GUI):
\`\`\`bash
npm run prisma:studio
\`\`\`

### Building for Production

\`\`\`bash
npm run build
\`\`\`

## Features

- **Frontend**: Vite, React, TypeScript
- **Backend**: Node.js, Express, TypeScript
- **Database**: Prisma ORM with SQLite (can be changed to PostgreSQL, MySQL, etc.)
- **Development**: Hot reloading, TypeScript compilation
EOF
    
    # Create a shared .gitignore
    echo "Creating .gitignore..."
    cat > "$PROJECT_DIR/.gitignore" << EOF
# Dependencies
node_modules
.pnp
.pnp.js

# Production
build
dist
out

# Prisma
*.db
*.db-journal

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Testing
coverage
.nyc_output

# DSR DevOps scripts
dsr-scripts/
EOF
    
    # Initialize git repo
    echo "Initializing git repository..."
    cd "$PROJECT_DIR"
    git init
    
    # Make sure .gitignore excludes dsr-scripts directory
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
        sed -i '' "s|git clone \[repository_url\]|git clone $REPO_URL|g" "$PROJECT_DIR/README.md"
        git add README.md
        git commit -m "Update README with actual repository URL"
        git push
        
        echo "GitHub repository created: $REPO_URL"
    fi
    
    echo -e "\nProject setup complete for $PROJECT_NAME!"
    echo "Directory: $PROJECT_DIR"
    
    echo -e "\nTo start developing:"
    echo "cd $(basename "$PROJECT_DIR")"
    echo "npm run dev"
    
    echo -e "\nDevelopment database is already set up with the User model."
    echo "To explore the database with Prisma Studio:"
    echo "npm run prisma:studio"
    
    echo -e "\nPORT CONFIGURATION:"
    echo "- Frontend runs on: http://localhost:5173 (Vite default)"
    echo "- Backend runs on: http://localhost:8080 (configured in backend/.env)"
    echo ""
    echo "If you need to change ports due to conflicts:"
    echo "- Frontend: Edit the 'vite.config.ts' file"
    echo "- Backend: Edit the 'PORT' value in 'backend/.env' file"
    
    # Ask if user wants to start the development server
    echo ""
    read -p "Would you like to start the development server now? (y/n): " START_DEV
    if [[ $START_DEV == "y" || $START_DEV == "Y" ]]; then
        echo "Starting development server..."
        cd "$PROJECT_DIR"
        npm run dev
    else
        echo "You can start the server later with 'npm run dev'"
    fi
}

# Run the main function
main