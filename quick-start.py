#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Universal Quick Start

One script that works everywhere: Windows, Linux, macOS
Downloads the project and starts the launcher.

Usage:
    python quick-start.py
    python3 quick-start.py
    ./quick-start.py
"""

import os
import sys
import platform
import subprocess
import tempfile
import shutil
from pathlib import Path

def print_status(msg, level="INFO"):
    """Print colored status message"""
    colors = {
        "INFO": "\0330;34m",  # Blue
        "SUCCESS": "\0330;32m",  # Green
        "WARNING": "\0331;33m",  # Yellow
        "ERROR": "\0330;31m",   # Red
    }
    reset = "\0330m"
    
    # Disable colors on Windows if needed
    if platform.system() == "Windows":
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
        except:
            colors = {k: "" for k in colors}
            reset = ""
    
    print(f"{colors.get(level, '')}{level}: {msg}{reset}")

def run_command(cmd, shell=True, check=True):
    """Run a command and return result"""
    try:
        result = subprocess.run(cmd, shell=shell, check=check, 
                              capture_output=True, text=True)
        return result
    except subprocess.CalledProcessError as e:
        print_status(f"Command failed: {e}", "ERROR")
        if e.stdout:
            print(f"STDOUT: {e.stdout}")
        if e.stderr:
            print(f"STDERR: {e.stderr}")
        return None

def check_dependencies():
    """Check if required tools are available and offer to install missing ones"""
    print_status("Checking dependencies...")
    
    # Check Python
    python_version = sys.version_info
    if python_version < (3, 7):
        print_status(f"Python 3.7+ required, found {python_version.major}.{python_version.minor}", "ERROR")
        print_status("Please install Python 3.7+ from https://python.org", "ERROR")
        return False
    print_status(f" Python {python_version.major}.{python_version.minor}.{python_version.micro}", "SUCCESS")
    
    # Check git
    git_result = run_command("git --version", check=False)
    if not git_result or git_result.returncode != 0:
        print_status("Git not found. Git is recommended for the best experience.", "WARNING")
        
        # Offer to install git on Windows
        if platform.system() == "Windows":
            try:
                response = input("Would you like to install Git for Windows? (y/N): ").strip().lower()
                if response == 'y':
                    print_status("Please download Git from https://git-scm.com/download/windows", "INFO")
                    print_status("After installing Git, restart this script.", "INFO")
                    return False
            except (EOFError, KeyboardInterrupt):
                # Handle GUI/non-interactive mode
                print_status("Running in non-interactive mode, continuing without Git", "WARNING")
        
        return "no-git"
    print_status(" Git available", "SUCCESS")
    
    return True

def download_project():
    """Download the project using git or fallback methods"""
    project_dir = Path.cwd() / "opentofu-lab-automation"
    
    if project_dir.exists():
        print_status(f"Project directory already exists at {project_dir}", "WARNING")
        try:
            response = input("Continue with existing directory? (y/N): ").strip().lower()
            if response != 'y':
                print_status("Aborted by user", "INFO")
                return None
        except (EOFError, KeyboardInterrupt):
            # Handle GUI/non-interactive mode - default to continue
            print_status("Running in non-interactive mode, using existing directory", "INFO")
        return project_dir
    
    print_status("Downloading OpenTofu Lab Automation...")
    
    # Try git clone first
    git_result = run_command(
        "git clone https://github.com/wizzense/opentofu-lab-automation.git",
        check=False
    )
    
    if git_result and git_result.returncode == 0:
        print_status(" Downloaded via git clone", "SUCCESS")
        return project_dir
    
    # Git failed, try wget or curl
    print_status("Git clone failed, trying download...", "WARNING")
    
    # Download ZIP file
    zip_url = "https://github.com/wizzense/opentofu-lab-automation/archive/refs/heads/main.zip"
    zip_file = "opentofu-lab-automation.zip"
    
    # Try different download methods
    download_commands = 
        f"curl -L -o {zip_file} {zip_url}",
        f"wget -O {zip_file} {zip_url}",
    
    
    download_success = False
    for cmd in download_commands:
        result = run_command(cmd, check=False)
        if result and result.returncode == 0:
            download_success = True
            break
    
    if not download_success:
        print_status("Could not download project. Please install git or curl/wget.", "ERROR")
        print_status("Manual alternative:", "INFO")
        print_status("1. Download: https://github.com/wizzense/opentofu-lab-automation/archive/refs/heads/main.zip", "INFO")
        print_status("2. Extract and run: python launcher.py", "INFO")
        return None
    
    # Extract ZIP
    try:
        import zipfile
        with zipfile.ZipFile(zip_file, 'r') as zip_ref:
            zip_ref.extractall()
        
        # Rename extracted folder
        extracted_name = "opentofu-lab-automation-main"
        if Path(extracted_name).exists():
            Path(extracted_name).rename(project_dir)
        
        # Clean up
        Path(zip_file).unlink()
        
        print_status(" Downloaded and extracted", "SUCCESS")
        return project_dir
        
    except Exception as e:
        print_status(f"Error extracting: {e}", "ERROR")
        return None

def launch_project(project_dir):
    """Launch the project using the unified launcher"""
    launcher_path = project_dir / "launcher.py"
    
    if not launcher_path.exists():
        print_status("Launcher not found. Project may be incomplete.", "ERROR")
        return False
    
    print_status("Starting OpenTofu Lab Automation launcher...", "INFO")
    
    # Change to project directory and run launcher
    os.chdir(project_dir)
    
    try:
        subprocess.run(sys.executable, "launcher.py", check=True)
        return True
    except subprocess.CalledProcessError:
        print_status("Failed to start launcher", "ERROR")
        return False
    except KeyboardInterrupt:
        print_status("Interrupted by user", "INFO")
        return True

def main():
    """Main quick start function"""
    print_status("OpenTofu Lab Automation - Universal Quick Start", "INFO")
    print_status("=" * 50, "INFO")
    
    # Check dependencies
    deps_result = check_dependencies()
    if deps_result is False:
        sys.exit(1)
    
    # Download project
    project_dir = download_project()
    if not project_dir:
        sys.exit(1)
    
    # Launch project
    success = launch_project(project_dir)
    if not success:
        print_status("Quick start completed with errors", "WARNING")
        sys.exit(1)
    
    print_status("Quick start completed successfully!", "SUCCESS")

if __name__ == "__main__":
    main()
