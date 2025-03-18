# setup_vite_react_prisma.ps1 - PowerShell script for setting up a Vite React-TS frontend with Node.js + Prisma backend
#
# This script sets up a standardized project with Vite React-TS for the frontend
# and a Node.js backend with Prisma ORM, along with a GitHub repository.
#
# Usage:
#   .\dsr-scripts\setup_vite_react_prisma.ps1 [project_name] [-NoGithub] [-Public]
#
# Example:
#   .\dsr-scripts\setup_vite_react_prisma.ps1
#   .\dsr-scripts\setup_vite_react_prisma.ps1 my-custom-name
#   .\dsr-scripts\setup_vite_react_prisma.ps1 -NoGithub
#   .\dsr-scripts\setup_vite_react_prisma.ps1 -Public
#
# Note: If project_name is not provided, the parent folder name will be used.

# Stop execution on error
$ErrorActionPreference = "Stop"

# Get the absolute path of the script directory
function Get-ScriptPath {
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        Write-Error "Unable to determine script path."
        exit 1
    }
    return $scriptPath
}

$SCRIPT_PATH = Get-ScriptPath
$SCRIPT_DIR = Split-Path -Parent $SCRIPT_PATH
$TEMPLATES_DIR = Join-Path -Path $SCRIPT_DIR -ChildPath "templates"

# Get the parent directory that contains the script directory
$PARENT_DIR = Split-Path -Parent $SCRIPT_DIR

# Validate parent directory
if ($PARENT_DIR -match "\.Trash|\.trash") {
    Write-Error "Error: Script appears to be running from a trash directory."
    Write-Error "Please move the dsr-scripts directory to your project directory and try again."
    exit 1
}

# Verify that the script directory is named 'dsr-scripts'
if ((Split-Path -Leaf $SCRIPT_DIR) -ne "dsr-scripts") {
    Write-Warning "The script directory is not named 'dsr-scripts' but '$(Split-Path -Leaf $SCRIPT_DIR)'."
    Write-Warning "This may cause unexpected behavior. Consider renaming the directory."
    Write-Output ""
    $CONTINUE_WRONG_DIR = Read-Host "Continue anyway? (y/n)"
    if ($CONTINUE_WRONG_DIR -notmatch "^[yY]$") {
        Write-Error "Setup aborted."
        exit 1
    }
}

# Verify that the script directory exists and is a directory
if (-not (Test-Path -Path $SCRIPT_DIR -PathType Container)) {
    Write-Error "The script directory '$SCRIPT_DIR' does not exist or is not a directory."
    exit 1
}

# Check if script is being run from within the dsr-scripts directory
$CURRENT_DIR = Get-Location
if ($CURRENT_DIR.Path -eq $SCRIPT_DIR) {
    Write-Error "Error: This script should be run from the parent directory, not from within dsr-scripts."
    Write-Error "Please change to your project directory and run: .\dsr-scripts\$(Split-Path -Leaf $SCRIPT_PATH)"
    exit 1
}

# Default to parent folder name for project name
$PARENT_FOLDER = Split-Path -Leaf $PARENT_DIR
Write-Output "Parent directory detected as: $PARENT_DIR"
Write-Output "Parent folder name is: $PARENT_FOLDER"

# Convert spaces and underscores to hyphens, make lowercase
$SANITIZED_FOLDER = $PARENT_FOLDER.ToLower() -replace "[ _]", "-"
$PROJECT_NAME = $SANITIZED_FOLDER
$PROJECT_DIR = $PARENT_DIR

# Parse command line arguments
param(
    [Parameter(Position=0)]
    [string]$CustomProjectName,
    
    [Parameter()]
    [switch]$NoGithub,
    
    [Parameter()]
    [switch]$Public
)

if ($CustomProjectName) {
    $PROJECT_NAME = $CustomProjectName
}

# Default values
$USE_GITHUB = -not $NoGithub
$REPO_VISIBILITY = if ($Public) { "public" } else { "private" }

Write-Output "Setting up Vite React-TS + Node.js/Prisma project with name: $PROJECT_NAME in parent directory ($PARENT_DIR)"

# Function to check for required tools and install if missing
function Test-RequiredTools {
    # Check Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warning "Node.js is not installed or not in PATH."
        Write-Output "You need Node.js to continue."
        Write-Output "You can download it from: https://nodejs.org/"
        
        $installNode = Read-Host "Do you want to open the Node.js download page? (y/n)"
        if ($installNode -match "^[yY]$") {
            Start-Process "https://nodejs.org/en/download/"
        }
        
        Write-Error "Node.js is required. Please install and try again."
        exit 1
    }
    
    # Check npm
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Warning "npm is not installed or not in PATH."
        Write-Error "npm is required and should be installed with Node.js. Please check your installation."
        exit 1
    }
    
    # Check GitHub CLI if needed
    if ($USE_GITHUB) {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Warning "GitHub CLI (gh) not found."
            Write-Output "You can install it from: https://cli.github.com/"
            
            $installGh = Read-Host "Do you want to open the GitHub CLI download page? (y/n)"
            if ($installGh -match "^[yY]$") {
                Start-Process "https://cli.github.com/"
            }
            
            Write-Output "Continuing without GitHub integration..."
            $USE_GITHUB = $false
        }
        else {
            # Check if the user is authenticated with GitHub
            $ghAuthStatus = gh auth status 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Output "You need to authenticate with GitHub CLI first."
                Write-Output "Run 'gh auth login' and follow the prompts."
                Write-Output ""
                
                # Ask if user wants to authenticate now
                $AUTH_NOW = Read-Host "Would you like to authenticate now? (y/n)"
                if ($AUTH_NOW -match "^[yY]$") {
                    gh auth login
                    $ghAuthStatus = gh auth status 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Output "Authentication failed. Continuing without GitHub integration."
                        $USE_GITHUB = $false
                    }
                }
                else {
                    Write-Output "Continuing without GitHub integration..."
                    $USE_GITHUB = $false
                }
            }
        }
    }
    
    # Check Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "Git is not installed or not in PATH."
        Write-Output "You need Git to continue."
        Write-Output "You can download it from: https://git-scm.com/downloads"
        
        $installGit = Read-Host "Do you want to open the Git download page? (y/n)"
        if ($installGit -match "^[yY]$") {
            Start-Process "https://git-scm.com/downloads"
        }
        
        Write-Error "Git is required. Please install and try again."
        exit 1
    }
}

# Main function
function Setup-Project {
    Write-Output "Setting up Vite React-TS + Node.js/Prisma project: $PROJECT_NAME"
    
    # Check required tools
    Test-RequiredTools
    
    # Check if directory is empty enough to proceed
    $dirContents = Get-ChildItem -Path $PROJECT_DIR -Force | Where-Object { $_.Name -ne '.git' -and $_.Name -ne 'dsr-scripts' }
    if ($dirContents.Count -gt 0) {
        Write-Warning "Directory $PROJECT_DIR is not empty (excluding dsr-scripts folder)."
        $CONTINUE = Read-Host "Do you want to continue anyway? Files may be overwritten. (y/n)"
        if ($CONTINUE -notmatch "^[yY]$") {
            Write-Error "Setup aborted."
            exit 1
        }
    }
    
    # Create frontend using Vite
    Write-Output "Creating frontend using Vite with React + TypeScript..."
    Set-Location -Path $PROJECT_DIR
    npm create vite@latest frontend -- --template react-ts
    
    # Set up frontend
    Write-Output "Setting up frontend..."
    Set-Location -Path "$PROJECT_DIR\frontend"
    npm install
    
    # Install axios for API requests
    npm install axios
    
    # Create API service file
    Write-Output "Creating API service file..."
    New-Item -Path "$PROJECT_DIR\frontend\src\services" -ItemType Directory -Force
    $apiServiceContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\frontend\src\services\api.ts" -Value $apiServiceContent
    
    # Update App.tsx with example usage
    Write-Output "Updating App.tsx with API example..."
    $appTsxContent = @"
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
        setApiStatus(`API connected: \${response.message}`);
        
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
"@
    Set-Content -Path "$PROJECT_DIR\frontend\src\App.tsx" -Value $appTsxContent
    
    # Create basic CSS file
    Write-Output "Creating App CSS..."
    $appCssContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\frontend\src\App.css" -Value $appCssContent
    
    # Create backend directory
    Write-Output "Creating backend directory structure..."
    New-Item -Path "$PROJECT_DIR\backend\src\controllers" -ItemType Directory -Force
    New-Item -Path "$PROJECT_DIR\backend\src\routes" -ItemType Directory -Force
    New-Item -Path "$PROJECT_DIR\backend\src\models" -ItemType Directory -Force
    
    # Initialize backend package.json
    Write-Output "Initializing backend package.json..."
    Set-Location -Path "$PROJECT_DIR\backend"
    npm init -y
    
    # Update backend package.json
    $backendPackageJson = Get-Content -Path "$PROJECT_DIR\backend\package.json" -Raw | ConvertFrom-Json
    $backendPackageJson.main = "dist/index.js"
    $backendPackageJson.scripts = @{
        "start" = "node dist/index.js"
        "dev" = "nodemon src/index.ts"
        "build" = "tsc"
        "lint" = "eslint src --ext .ts"
        "prisma:generate" = "prisma generate"
        "prisma:migrate" = "prisma migrate dev"
        "prisma:studio" = "prisma studio"
    }
    $backendPackageJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$PROJECT_DIR\backend\package.json"
    
    # Install backend dependencies
    Write-Output "Installing backend dependencies..."
    npm install express cors dotenv
    npm install -D typescript ts-node nodemon @types/node @types/express @types/cors prisma
    npm install @prisma/client
    
    # Create tsconfig.json for backend
    Write-Output "Creating tsconfig.json for backend..."
    $tsConfigContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\backend\tsconfig.json" -Value $tsConfigContent
    
    # Create .env file for backend
    Write-Output "Creating .env file for backend..."
    $envContent = @"
PORT=8080
DATABASE_URL="file:./dev.db"
"@
    Set-Content -Path "$PROJECT_DIR\backend\.env" -Value $envContent
    
    # Initialize Prisma
    Write-Output "Initializing Prisma..."
    npx prisma init --datasource-provider sqlite
    
    # Update the Prisma schema with our User model
    Write-Output "Updating Prisma schema with User model..."
    $prismaSchemaContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\backend\prisma\schema.prisma" -Value $prismaSchemaContent
    
    # Generate Prisma client and create migrations
    Write-Output "Generating Prisma client..."
    Set-Location -Path "$PROJECT_DIR\backend"
    npx prisma generate
    
    # Create initial migration and apply it
    Write-Output "Creating and applying initial Prisma migration..."
    npx prisma migrate dev --name init_user_model --create-only
    npx prisma migrate deploy
    
    # Create server entry point file
    Write-Output "Creating server entry point file..."
    $serverFileContent = @"
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
  console.log(`Server running on port \${port}`);
});

// Handle shutdown
process.on('SIGINT', async () => {
  await prisma.`$disconnect`();
  process.exit(0);
});
"@
    Set-Content -Path "$PROJECT_DIR\backend\src\index.ts" -Value $serverFileContent
    
    # Create root package.json for the entire project
    Write-Output "Creating root package.json..."
    $rootPackageJsonContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\package.json" -Value $rootPackageJsonContent
    
    # Install concurrently for running both frontend and backend
    Write-Output "Installing concurrently..."
    Set-Location -Path $PROJECT_DIR
    npm install
    
    # Create README.md
    Write-Output "Creating README.md..."
    $readmeContent = @"
# $PROJECT_NAME

A full-stack TypeScript project with Vite React frontend and Node.js + Prisma backend.

## Project Structure

- `/frontend`: Vite React TypeScript application
- `/backend`: Node.js Express API with Prisma ORM
  - `/prisma`: Prisma schema and migrations
  - `/src`: TypeScript source code

## Getting Started

### Prerequisites

- Node.js (v14+)
- npm or yarn

### Installation

1. Clone the repository:
   ```
   git clone [repository_url]
   cd $PROJECT_NAME
   ```

2. Install dependencies:
   ```
   npm install
   cd frontend && npm install
   cd ..\backend && npm install
   ```

3. Set up the database:
   ```
   cd backend
   npm run prisma:migrate
   npm run prisma:generate
   ```

### Development

Run both frontend and backend simultaneously:
```
npm run dev
```

Or run them separately:
```
# Frontend (Vite React)
npm run frontend

# Backend (Node + Express + Prisma)
npm run backend
```

#### Database Management
Open Prisma Studio (database GUI):
```
npm run prisma:studio
```

### Building for Production

```
npm run build
```

## Features

- **Frontend**: Vite, React, TypeScript
- **Backend**: Node.js, Express, TypeScript
- **Database**: Prisma ORM with SQLite (can be changed to PostgreSQL, MySQL, etc.)
- **Development**: Hot reloading, TypeScript compilation
"@
    Set-Content -Path "$PROJECT_DIR\README.md" -Value $readmeContent
    
    # Create a shared .gitignore
    Write-Output "Creating .gitignore..."
    $gitignoreContent = @"
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
"@
    Set-Content -Path "$PROJECT_DIR\.gitignore" -Value $gitignoreContent
    
    # Initialize git repo
    Write-Output "Initializing git repository..."
    Set-Location -Path $PROJECT_DIR
    git init
    
    # Make sure .gitignore excludes dsr-scripts directory
    if (-not (Select-String -Path "$PROJECT_DIR\.gitignore" -Pattern "dsr-scripts/" -Quiet)) {
        Add-Content -Path "$PROJECT_DIR\.gitignore" -Value "`n# DSR DevOps scripts`ndsr-scripts/"
    }
    
    # Create a temporary .git/info/exclude to ensure dsr-scripts is excluded
    New-Item -Path "$PROJECT_DIR\.git\info" -ItemType Directory -Force
    Add-Content -Path "$PROJECT_DIR\.git\info\exclude" -Value "dsr-scripts/"
    
    # Add files to git
    Write-Output "Adding files to git..."
    # First add .gitignore to make sure it's respected
    git add .gitignore
    # Then add everything else (letting .gitignore exclude the dsr-scripts directory)
    git add .
    
    git commit -m "Initial commit: $PROJECT_NAME project structure"
    
    # Set up GitHub repository if requested
    if ($USE_GITHUB) {
        Write-Output "Setting up GitHub repository..."
        gh repo create $PROJECT_NAME "--$REPO_VISIBILITY" --source=. --remote=origin
        git push -u origin main
        
        # Update README with actual repo URL
        $REPO_URL = (gh repo view --json url -q .url)
        (Get-Content -Path "$PROJECT_DIR\README.md") -replace "git clone \[repository_url\]", "git clone $REPO_URL" | Set-Content -Path "$PROJECT_DIR\README.md"
        git add README.md
        git commit -m "Update README with actual repository URL"
        git push
        
        Write-Output "GitHub repository created: $REPO_URL"
    }
    
    Write-Output "`nProject setup complete for $PROJECT_NAME!"
    Write-Output "Directory: $PROJECT_DIR"
    
    Write-Output "`nTo start developing:"
    Write-Output "cd $(Split-Path -Leaf $PROJECT_DIR)"
    Write-Output "npm run dev"
    
    Write-Output "`nDevelopment database is already set up with the User model."
    Write-Output "To explore the database with Prisma Studio:"
    Write-Output "npm run prisma:studio"
    
    Write-Output "`nPORT CONFIGURATION:"
    Write-Output "- Frontend runs on: http://localhost:5173 (Vite default)"
    Write-Output "- Backend runs on: http://localhost:8080 (configured in backend\.env)"
    Write-Output ""
    Write-Output "If you need to change ports due to conflicts:"
    Write-Output "- Frontend: Edit the 'vite.config.ts' file"
    Write-Output "- Backend: Edit the 'PORT' value in 'backend\.env' file"
    
    # Ask if user wants to start the development server
    Write-Output ""
    $START_DEV = Read-Host "Would you like to start the development server now? (y/n)"
    if ($START_DEV -match "^[yY]$") {
        Write-Output "Starting development server..."
        Set-Location -Path $PROJECT_DIR
        npm run dev
    }
    else {
        Write-Output "You can start the server later with 'npm run dev'"
    }
}

# Run the main function
Setup-Project