#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Cross-Platform Deployment Wrapper

A lightweight, cross-platform deployment script that handles:
- Platform detection (Windows/Linux/macOS)
- Prerequisites checking and installation
- Configuration management
- One-click lab deployment

Usage:
    python deploy.py # Interactive deployment
    python deploy.py --quick # Quick deployment with defaults
    python deploy.py --config custom.json # Use custom config
    python deploy.py --gui # Launch GUI (future feature)
"""

import os
import sys
import json
import platform
import subprocess
from pathlib import Path
from typing import Dict, Optional, Tuple, Any

# Set console encoding for Windows compatibility
if platform.system() == "Windows":
    try:
        import codecs
        codecs.register(lambda name: codecs.lookup('utf-8') if name == 'cp65001' else None)
    except:
        pass

# Force proper working directory - always use C:\temp on Windows, /tmp on others
def get_working_directory():
    """Get and ensure proper working directory exists"""
    if platform.system() == "Windows":
        work_dir = Path("C:/temp/opentofu-lab-automation")
    else:
        work_dir = Path("/tmp/opentofu-lab-automation")
    
    work_dir.mkdir(parents=True, exist_ok=True)
    return work_dir

# Project constants - use forced working directory
WORK_DIR = get_working_directory()
PROJECT_ROOT = WORK_DIR
PWSH_DIR = PROJECT_ROOT / "pwsh"
CONFIGS_DIR = PROJECT_ROOT / "configs"
DEFAULT_CONFIG = CONFIGS_DIR / "config_files" / "default-config.json"

class Colors:
    """ANSI color codes for cross-platform terminal output"""
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

def print_banner():
    """Display project banner"""
    # Use Windows-compatible characters and encoding
    try:
        banner = f"""
{Colors.BLUE}{Colors.BOLD}
===============================================================
 OpenTofu Lab Automation 
 Cross-Platform Deployment 
===============================================================
{Colors.RESET}
{Colors.GREEN}>> One-click infrastructure lab deployment{Colors.RESET}
{Colors.YELLOW}Platform: {platform.system()} {platform.release()}{Colors.RESET}
{Colors.YELLOW}Project: {PROJECT_ROOT}{Colors.RESET}
"""
        print(banner)
    except UnicodeEncodeError:
        # Fallback for systems with encoding issues
        print("\n" + "="*60)
        print(" OpenTofu Lab Automation")
        print(" Cross-Platform Deployment")
        print("="*60)
        print(f"Platform: {platform.system()} {platform.release()}")
        print(f"Project: {PROJECT_ROOT}")
        print("="*60 + "\n")

def detect_platform() -> Tuple[str, str]:
    """Detect operating system and architecture"""
    system = platform.system().lower()
    arch = platform.machine().lower()
    
    # Normalize architecture names
    if arch in ['x86_64', 'amd64']:
        arch = 'x64'
    elif arch in ['aarch64', 'arm64']:
        arch = 'arm64'
    
    return system, arch

def check_powershell() -> Optional[str]:
    """Check if PowerShell 7+ is available with timeout and non-interactive mode"""
    try:
        # Try pwsh first (PowerShell 7+) with explicit non-interactive flag
        result = subprocess.run([
            'pwsh', '-NoProfile', '-NonInteractive', '-Command', 
            '$PSVersionTable.PSVersion.Major'
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            version = int(result.stdout.strip())
            if version >= 7:
                return 'pwsh'
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError, ValueError):
        pass
    
    # Try Windows PowerShell on Windows with non-interactive flag
    system, _ = detect_platform()
    if system == 'windows':
        try:
            result = subprocess.run([
                'powershell', '-NoProfile', '-NonInteractive', '-Command', 
                '$PSVersionTable.PSVersion.Major'
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0:
                version = int(result.stdout.strip())
                if version >= 5:
                    print(f"{Colors.YELLOW}WARNING: Using Windows PowerShell {version}. PowerShell 7+ recommended.{Colors.RESET}")
                    return 'powershell'
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError, ValueError):
            pass
    
    return None

def install_powershell_instructions() -> str:
    """Get PowerShell installation instructions for current platform"""
    system, _ = detect_platform()
    
    instructions = {
        'windows': """
Windows Installation:
1. Download from: https://github.com/PowerShell/PowerShell/releases
2. Or use winget: winget install Microsoft.PowerShell
3. Or use Chocolatey: choco install powershell-core
        """,
        'linux': """
Linux Installation (Ubuntu/Debian):
1. curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
2. echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -rs)-prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
3. sudo apt update && sudo apt install powershell

Or use snap: sudo snap install powershell --classic
        """,
        'darwin': """
macOS Installation:
1. Download from: https://github.com/PowerShell/PowerShell/releases
2. Or use Homebrew: brew install powershell
3. Or use MacPorts: sudo port install powershell
        """
    }
    
    return instructions.get(system, "Visit: https://docs.microsoft.com/powershell/scripting/install/installing-powershell")

def check_git() -> bool:
    """Check if Git is available"""
    try:
        subprocess.run(['git', '--version'], capture_output=True, check=True, timeout=5)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return False

def load_config(config_path: Optional[str] = None) -> Dict[str, Any]:
    """Load deployment configuration"""
    if config_path:
        config_file = Path(config_path)
    else:
        config_file = DEFAULT_CONFIG
    
    if not config_file.exists():
        print(f"{Colors.RED}ERROR: Config file not found: {config_file}{Colors.RESET}")
        return {}
    
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        print(f"{Colors.GREEN}OK: Loaded config: {config_file}{Colors.RESET}")
        return config
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}ERROR: Invalid JSON in config file: {e}{Colors.RESET}")
        return {}

def ensure_project_files():
    """Ensure project files are available in working directory"""
    # Check if we already have the project structure
    if (PROJECT_ROOT / "pwsh").exists() and (PROJECT_ROOT / "configs").exists():
        print(f"{Colors.GREEN}✓ Project files found in {PROJECT_ROOT}{Colors.RESET}")
        return True
    
    print(f"{Colors.YELLOW}⚠ Project files not found in {PROJECT_ROOT}. Setting up...{Colors.RESET}")
    
    try:
        # Create basic directory structure
        (PROJECT_ROOT / "pwsh").mkdir(parents=True, exist_ok=True)
        (PROJECT_ROOT / "configs").mkdir(parents=True, exist_ok=True)
        print(f"{Colors.GREEN}✓ Created basic project structure{Colors.RESET}")
        return True
    except Exception as e:
        print(f"{Colors.RED}ERROR: Failed to create project structure: {e}{Colors.RESET}")
        return False

def run_kicker_bootstrap(config_path: Optional[str] = None, quiet: bool = False, non_interactive: bool = False) -> bool:
    """Execute the kicker-bootstrap script with proper working directory and encoding"""
    system, _ = detect_platform()
    pwsh_cmd = check_powershell()
    
    if not pwsh_cmd:
        print(f"{Colors.RED}ERROR: PowerShell not found!{Colors.RESET}")
        print(install_powershell_instructions())
        return False
    
    # Ensure project files are available in working directory
    if not ensure_project_files():
        print(f"{Colors.RED}ERROR: Could not setup project files in {PROJECT_ROOT}{Colors.RESET}")
        return False
    
    # Force working directory and create if needed
    PROJECT_ROOT.mkdir(parents=True, exist_ok=True)
    os.chdir(PROJECT_ROOT)
    print(f"{Colors.BLUE}Working directory: {PROJECT_ROOT}{Colors.RESET}")
    
    # Validate we're not in system32 or other problematic directories
    current_dir = Path.cwd()
    if "system32" in str(current_dir).lower() or "windows" in str(current_dir).lower():
        print(f"{Colors.RED}ERROR: Invalid working directory detected: {current_dir}{Colors.RESET}")
        print(f"{Colors.YELLOW}Forcing change to: {PROJECT_ROOT}{Colors.RESET}")
        try:
            os.chdir(PROJECT_ROOT)
            print(f"{Colors.GREEN}✓ Changed to proper working directory{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}ERROR: Could not change directory: {e}{Colors.RESET}")
            return False
    
    # Build command arguments with proper flags for non-interactive execution
    kicker_script = PWSH_DIR / "kicker-bootstrap.ps1"
    if not kicker_script.exists():
        # Try alternative locations
        alt_script = PROJECT_ROOT / "pwsh" / "runner.ps1"
        if alt_script.exists():
            kicker_script = alt_script
            print(f"{Colors.YELLOW}Using runner.ps1 instead of kicker-bootstrap.ps1{Colors.RESET}")
        else:
            print(f"{Colors.RED}ERROR: PowerShell script not found at {kicker_script}{Colors.RESET}")
            print(f"{Colors.YELLOW}Available files in pwsh/: {list((PWSH_DIR).glob('*.ps1')) if PWSH_DIR.exists() else 'Directory not found'}{Colors.RESET}")
            return False
    
    # Build command with proper non-interactive flags
    cmd = [
        pwsh_cmd, 
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(kicker_script)
    ]
    
    if config_path:
        cmd.extend(['-ConfigFile', config_path])
    if quiet:
        cmd.append('-Quiet')
    if non_interactive:
        cmd.append('-NonInteractive')
    
    safe_print(f"{Colors.BLUE}>> Launching PowerShell deployment...{Colors.RESET}", 
               f"{Colors.BLUE}Starting deployment...{Colors.RESET}")
    print(f"{Colors.YELLOW}Command: {' '.join(cmd)}{Colors.RESET}")
    print(f"{Colors.YELLOW}Working Directory: {Path.cwd()}{Colors.RESET}")
    
    try:
        env = os.environ.copy()
        env['PYTHONIOENCODING'] = 'utf-8'
        env['PWD'] = str(PROJECT_ROOT)
        if system == 'windows':
            env['TEMP'] = str(PROJECT_ROOT / 'temp')
            env['TMP'] = str(PROJECT_ROOT / 'temp')
        
        result = subprocess.run(
            cmd, 
            env=env, 
            cwd=PROJECT_ROOT, 
            timeout=1800  # 30 minutes
        )
        
        if result.returncode == 0:
            print(f"{Colors.GREEN}✓ Deployment completed successfully{Colors.RESET}")
        else:
            print(f"{Colors.RED}✗ Deployment failed with exit code {result.returncode}{Colors.RESET}")
        
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        print(f"\n{Colors.RED}ERROR: Deployment timed out after 30 minutes{Colors.RESET}")
        return False
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}WARNING: Deployment interrupted by user{Colors.RESET}")
        return False
    except Exception as e:
        print(f"{Colors.RED}ERROR: Error running PowerShell script: {e}{Colors.RESET}")
        return False

def interactive_setup() -> Dict[str, Any]:
    """Interactive configuration setup"""
    print(f"\n{Colors.BOLD}Setup: Interactive Setup{Colors.RESET}")
    print("Configure your lab deployment (press Enter for defaults):")
    
    config = {}
    
    # Basic questions
    repo_url = input(f"\nRepository: Repository URL [{Colors.YELLOW}default: use built-in{Colors.RESET}]: ").strip()
    if repo_url:
        config['RepoUrl'] = repo_url
    
    local_path = input(f"Path: Local deployment path [{Colors.YELLOW}default: C:\\Temp or /tmp{Colors.RESET}]: ").strip()
    if local_path:
        config['LocalPath'] = local_path
    
    # Verbosity
    verbosity = input(f"Verbosity: Verbosity (silent/normal/detailed) [{Colors.YELLOW}default: normal{Colors.RESET}]: ").strip().lower()
    if verbosity in ['silent', 'normal', 'detailed']:
        config['Verbosity'] = verbosity
    
    return config

def safe_print(text: str, fallback: Optional[str] = None):
    """Print text with Unicode fallback for Windows compatibility"""
    try:
        print(text)
    except UnicodeEncodeError:
        if fallback:
            print(fallback)
        else:
            import re
            clean_text = re.sub(r'[^\x00-\x7F]+', '', text)
            print(clean_text)

def main():
    """Main deployment function"""
    import argparse
    
    parser = argparse.ArgumentParser(description="OpenTofu Lab Automation Deployment")
    parser.add_argument("--quick", action="store_true", help="Quick deployment with defaults")
    parser.add_argument("--config", help="Custom configuration file path")
    parser.add_argument("--gui", action="store_true", help="Launch GUI (future feature)")
    parser.add_argument("--quiet", action="store_true", help="Quiet mode")
    
    args = parser.parse_args()
    
    print_banner()
    
    try:
        if args.quick:
            success = run_kicker_bootstrap(args.config, args.quiet, True)
        elif args.gui:
            print(f"{Colors.YELLOW}GUI mode not yet implemented. Using interactive mode.{Colors.RESET}")
            config = interactive_setup()
            success = run_kicker_bootstrap(args.config, args.quiet, False)
        else:
            config = interactive_setup()
            success = run_kicker_bootstrap(args.config, args.quiet, False)
        
        if success:
            print(f"\n{Colors.GREEN}{Colors.BOLD}✓ Deployment completed successfully!{Colors.RESET}")
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}✗ Deployment failed. Check logs above.{Colors.RESET}")
            sys.exit(1)
            
    except Exception as e:
        print(f"{Colors.RED}ERROR: Unexpected error: {e}{Colors.RESET}")
        sys.exit(1)

if __name__ == "__main__":
    main()
