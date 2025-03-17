#!/usr/bin/env python3
"""
Python Project Setup Script

This script sets up a standardized Python project with virtual environment,
GitHub repository, and recommended project structure.

Usage:
    ./setup_python_project.py <prefix> [--no-github]

Example:
    ./setup_python_project.py acme
    
    This will create a project named "acme-my-project" if run from a folder named "my-project".
"""

import os
import sys
import subprocess
import re
import shutil
from pathlib import Path


def get_project_name(prefix):
    """Generate a project name based on current folder and given prefix."""
    current_folder = os.path.basename(os.getcwd())
    # Convert spaces and underscores to hyphens, make lowercase
    sanitized_name = re.sub(r'[\s_]+', '-', current_folder.lower())
    return f"{prefix}-{sanitized_name}"


def setup_virtual_environment(project_name):
    """Create and set up a Python virtual environment."""
    print(f"Creating virtual environment for {project_name}...")
    
    # Create venv
    subprocess.run(["python3", "-m", "venv", ".venv"], check=True)
    
    # Create requirements files
    with open("requirements.txt", "w") as f:
        f.write("# Project dependencies\n")
    
    with open("requirements-dev.txt", "w") as f:
        f.write("# Development dependencies\n")
        f.write("pytest\n")
        f.write("black\n")
        f.write("flake8\n")
        f.write("mypy\n")
    
    # Activate and install base requirements
    if os.name == 'nt':  # Windows
        pip_path = ".venv/Scripts/pip"
    else:  # Unix/Mac
        pip_path = ".venv/bin/pip"
    
    subprocess.run([pip_path, "install", "--upgrade", "pip"], check=True)
    subprocess.run([pip_path, "install", "-r", "requirements-dev.txt"], check=True)
    
    print("Virtual environment created and dependencies installed.")


def create_project_structure(project_name):
    """Create standardized project directory structure."""
    print(f"Creating project structure for {project_name}...")
    
    # Create directories
    os.makedirs(f"src/{project_name.replace('-', '_')}", exist_ok=True)
    os.makedirs("tests", exist_ok=True)
    os.makedirs("docs", exist_ok=True)
    
    # Create __init__.py files
    package_dir = f"src/{project_name.replace('-', '_')}"
    with open(f"{package_dir}/__init__.py", "w") as f:
        f.write(f'"""Main package for {project_name}."""\n\n')
        f.write("__version__ = '0.1.0'\n")
    
    # Create main module file
    with open(f"{package_dir}/main.py", "w") as f:
        f.write(f'"""Main module for {project_name}."""\n\n')
        f.write("def main():\n")
        f.write('    """Main entry point."""\n')
        f.write('    print("Hello, world!")\n\n\n')
        f.write('if __name__ == "__main__":\n')
        f.write('    main()\n')
    
    # Create basic test file
    with open("tests/test_main.py", "w") as f:
        f.write(f'"""Tests for {project_name}."""\n\n')
        f.write(f"from {project_name.replace('-', '_')}.main import main\n\n")
        f.write("def test_main():\n")
        f.write('    """Test the main function."""\n')
        f.write('    # This is a placeholder test\n')
        f.write('    assert True\n')
    
    # Create setup.py
    with open("setup.py", "w") as f:
        f.write('"""Package setup."""\n\n')
        f.write('from setuptools import setup, find_packages\n\n')
        f.write('setup(\n')
        f.write(f'    name="{project_name}",\n')
        f.write('    version="0.1.0",\n')
        f.write('    packages=find_packages(where="src"),\n')
        f.write('    package_dir={"": "src"},\n')
        f.write('    install_requires=[\n')
        f.write('        # List your dependencies here\n')
        f.write('    ],\n')
        f.write(')\n')
    
    # Create pyproject.toml
    with open("pyproject.toml", "w") as f:
        f.write('[build-system]\n')
        f.write('requires = ["setuptools>=42", "wheel"]\n')
        f.write('build-backend = "setuptools.build_meta"\n\n')
        f.write('[tool.black]\n')
        f.write('line-length = 88\n')
        f.write('target-version = ["py38"]\n')
    
    print("Project structure created.")


def get_github_username():
    """Get GitHub username from gh CLI if available."""
    try:
        result = subprocess.run(
            ["gh", "api", "user", "--jq", ".login"],
            check=True,
            capture_output=True,
            text=True
        )
        username = result.stdout.strip()
        return username if username else "yourusername"
    except subprocess.CalledProcessError:
        return "yourusername"

def setup_git(project_name, use_github=True, visibility="private"):
    """Initialize git repository and make initial commit. Optionally create GitHub repo."""
    print("Setting up Git repository...")
    
    # Get GitHub username if using GitHub
    github_username = get_github_username() if use_github else "yourusername"
    
    # Validate visibility option
    if visibility not in ["public", "private"]:
        print(f"Warning: Invalid visibility '{visibility}'. Defaulting to 'private'.")
        visibility = "private"
    
    # Create .gitignore
    with open(".gitignore", "w") as f:
        f.write("# Python\n")
        f.write("__pycache__/\n")
        f.write("*.py[cod]\n")
        f.write("*$py.class\n")
        f.write("*.so\n")
        f.write(".Python\n")
        f.write("env/\n")
        f.write("build/\n")
        f.write("develop-eggs/\n")
        f.write("dist/\n")
        f.write("downloads/\n")
        f.write("eggs/\n")
        f.write(".eggs/\n")
        f.write("lib/\n")
        f.write("lib64/\n")
        f.write("parts/\n")
        f.write("sdist/\n")
        f.write("var/\n")
        f.write("*.egg-info/\n")
        f.write(".installed.cfg\n")
        f.write("*.egg\n\n")
        f.write("# Virtual Environment\n")
        f.write(".venv/\n")
        f.write("venv/\n")
        f.write("ENV/\n\n")
        f.write("# IDE\n")
        f.write(".idea/\n")
        f.write(".vscode/\n")
        f.write("*.swp\n")
        f.write("*.swo\n\n")
        f.write("# Testing\n")
        f.write(".coverage\n")
        f.write("htmlcov/\n")
        f.write(".pytest_cache/\n")
    
    # Create README.md
    with open("README.md", "w") as f:
        f.write(f"# {project_name}\n\n")
        f.write("## Description\n\n")
        f.write("A brief description of the project.\n\n")
        f.write("## Installation\n\n")
        f.write("```bash\n")
        f.write("# Clone the repository\n")
        f.write(f"git clone https://github.com/{github_username}/{project_name}.git\n")
        f.write(f"cd {project_name}\n\n")
        f.write("# Create and activate virtual environment\n")
        f.write("python -m venv .venv\n")
        f.write("source .venv/bin/activate  # On Windows: .venv\\Scripts\\activate\n\n")
        f.write("# Install dependencies\n")
        f.write("pip install -r requirements.txt\n")
        f.write("```\n\n")
        f.write("## Usage\n\n")
        f.write("```python\n")
        f.write(f"from {project_name.replace('-', '_')}.main import main\n\n")
        f.write("main()\n")
        f.write("```\n")
    
    # Initialize git
    subprocess.run(["git", "init"], check=True)
    subprocess.run(["git", "add", "."], check=True)
    subprocess.run(["git", "commit", "-m", "Initial commit with project structure"], check=True)
    
    # Check if GitHub CLI is available and create remote repository if requested
    if use_github:
        try:
            # Check if gh CLI is installed
            subprocess.run(["gh", "--version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            
            print(f"Creating GitHub repository for {project_name}...")
            
            # Create GitHub repo
            try:
                subprocess.run(
                    ["gh", "repo", "create", project_name, f"--{visibility}", "--source=.", "--remote=origin"],
                    check=True
                )
                print(f"GitHub repository created: {project_name}")
                
                # Push to GitHub
                subprocess.run(["git", "push", "-u", "origin", "main"], check=True)
                print("Initial commit pushed to GitHub.")
                
            except subprocess.CalledProcessError as e:
                print(f"Error creating GitHub repository: {e}")
                print("You can manually create and connect to GitHub repository:")
                print(f"1. Create a new repository named '{project_name}' on GitHub")
                print("2. Run the following commands to connect to GitHub:")
                print(f"   git remote add origin https://github.com/{github_username}/{project_name}.git")
                print("   git branch -M main")
                print("   git push -u origin main")
                
        except subprocess.CalledProcessError:
            print("GitHub CLI (gh) not found. Please install GitHub CLI to automate repository creation.")
            print("You can install it from: https://cli.github.com/")
            print("\nManual GitHub setup:")
            print(f"1. Create a new repository named '{project_name}' on GitHub")
            print("2. Run the following commands to connect to GitHub:")
            print(f"   git remote add origin https://github.com/{github_username}/{project_name}.git")
            print("   git branch -M main")
            print("   git push -u origin main")
    else:
        print("\nSkipping GitHub repository creation as requested.")
        print("You can manually create and connect to GitHub repository:")
        print(f"1. Create a new repository named '{project_name}' on GitHub")
        print("2. Run the following commands to connect to GitHub:")
        print(f"   git remote add origin https://github.com/{github_username}/{project_name}.git")
        print("   git branch -M main")
        print("   git push -u origin main")
    
    print("\nGit repository initialized with initial commit.")


def main():
    """Main entry point for the script."""
    if len(sys.argv) < 2:
        print("Error: Missing prefix argument.")
        print("Usage: ./setup_python_project.py <prefix> [--no-github] [--public]")
        sys.exit(1)
    
    prefix = sys.argv[1]
    project_name = get_project_name(prefix)
    
    # Check for optional flags
    use_github = "--no-github" not in sys.argv
    visibility = "public" if "--public" in sys.argv else "private"
    
    print(f"Setting up Python project: {project_name}")
    
    # Execute setup functions
    setup_virtual_environment(project_name)
    create_project_structure(project_name)
    setup_git(project_name, use_github, visibility)
    
    print(f"\nProject setup complete for {project_name}!")
    print("Don't forget to activate your virtual environment:")
    if os.name == 'nt':  # Windows
        print(".venv\\Scripts\\activate")
    else:  # Unix/Mac
        print("source .venv/bin/activate")


if __name__ == "__main__":
    main()