# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Project Structure

This is a monorepo containing:

- `client/`: Frontend application
- `server/`: Backend API server
- `shared/`: Shared code, types, and utilities

## Getting Started

### Prerequisites

- Node.js 16+ and npm
- Git

### Installation

```bash
# Clone the repository
git clone {{REPO_URL}}
cd {{PROJECT_NAME}}

# Install dependencies
npm install
```

### Development

To run both client and server in development mode:

```bash
npm start
```

To run only the client:

```bash
npm run start:client
```

To run only the server:

```bash
npm run start:server
```

### Building

To build all packages:

```bash
npm run build
```

### Testing

To run tests:

```bash
npm test
```

## Directory Structure

```
├── client/                 # Frontend application
│   ├── public/             # Static assets
│   ├── src/                # Source code
│   └── package.json        # Client dependencies
├── server/                 # Backend application
│   ├── src/                # Source code
│   └── package.json        # Server dependencies
├── shared/                 # Shared code
│   ├── src/                # Source code
│   └── package.json        # Shared dependencies
└── package.json            # Root dependencies and workspace config
```