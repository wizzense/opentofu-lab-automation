#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Cross-Platform Deployment Wrapper

A lightweight, cross-platform deployment script that handles:
- Platform detection (Windows/Linux/macOS)
- Prerequisites checking and installation
- Configuration management
- One-click lab deployment

Usage:
    python deploy.py                    # Interactive deployment
    python deploy.py --quick            # Quick deployment with defaults
    python deploy.py --config custom.json  # Use custom config
    python deploy.py --gui              # Launch GUI (future feature)
"""

import os
import sys
import platform
import subprocess
import json
import argparse
from pathlib import Path
from typing import Dict, Optional, Tuple

# Set console encoding for Windows compatibility
if platform.system() == "Windows":
    try:
        import codecs
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except:
        pass

# Project constants
PROJECT_ROOT = Path(__file__).parent
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
        print("         OpenTofu Lab Automation")
        print("         Cross-Platform Deployment")
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
    """Check if PowerShell 7+ is available"""
    try:
        # Try pwsh first (PowerShell 7+)
        result = subprocess.run(['pwsh', '-Command', '$PSVersionTable.PSVersion.Major'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            version = int(result.stdout.strip())
            if version >= 7:
                return 'pwsh'
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError, ValueError):
        pass
    
    # Try Windows PowerShell on Windows
    system, _ = detect_platform()
    if system == 'windows':
        try:
            result = subprocess.run(['powershell', '-Command', '$PSVersionTable.PSVersion.Major'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                version = int(result.stdout.strip())
                if version >= 5:
                    print(f"{Colors.YELLOW}WARNING:  Using Windows PowerShell {version}. PowerShell 7+ recommended.{Colors.RESET}")
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

def load_config(config_path: Optional[str] = None) -> Dict:
    """Load deployment configuration"""
    if config_path:
        config_file = Path(config_path)
    else:
        config_file = DEFAULT_CONFIG
    
    if not config_file.exists():
        print(f"{Colors.RED}ERROR: Config file not found: {config_file}{Colors.RESET}")
        return {}
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        print(f"{Colors.GREEN}OK: Loaded config: {config_file}{Colors.RESET}")
        return config
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}ERROR: Invalid JSON in config file: {e}{Colors.RESET}")
        return {}

def run_kicker_bootstrap(config_path: Optional[str] = None, quiet: bool = False, non_interactive: bool = False) -> bool:
    """Execute the kicker-bootstrap script"""
    system, _ = detect_platform()
    pwsh_cmd = check_powershell()
    
    if not pwsh_cmd:
        print(f"{Colors.RED}ERROR: PowerShell not found!{Colors.RESET}")
        print(install_powershell_instructions())
        return False
    
    # Build command arguments
    kicker_script = PWSH_DIR / "kicker-bootstrap.ps1"
    cmd = [pwsh_cmd, '-File', str(kicker_script)]
    
    if config_path:
        cmd.extend(['-ConfigFile', config_path])
    if quiet:
        cmd.append('-Quiet')
    if non_interactive:
        cmd.append('-NonInteractive')
    
    safe_print(f"{Colors.BLUE}>> Launching kicker-bootstrap...{Colors.RESET}", 
               f"{Colors.BLUE}Starting deployment...{Colors.RESET}")
    print(f"{Colors.YELLOW}Command: {' '.join(cmd)}{Colors.RESET}")
    
    try:
        # Run with real-time output
        result = subprocess.run(cmd, cwd=PROJECT_ROOT)
        return result.returncode == 0
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}WARNING:  Deployment interrupted by user{Colors.RESET}")
        return False
    except Exception as e:
        print(f"{Colors.RED}ERROR: Error running kicker-bootstrap: {e}{Colors.RESET}")
        return False

def interactive_setup() -> Dict:
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

def safe_print(text: str, fallback: str = None):
    """Print text with Unicode fallback for Windows compatibility"""
    try:
        print(text)
    except UnicodeEncodeError:
        if fallback:
            print(fallback)
        else:
            # Strip emoji and special characters
            import re
            clean_text = re.sub(r'[^\x00-\x7F]+', '', text)
            print(clean_text)

def main():
    """Main deployment function"""
    parser = argparse.ArgumentParser(
        description="OpenTofu Lab Automation - Cross-Platform Deployment",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python deploy.py                    # Interactive deployment
  python deploy.py --quick            # Quick deployment with defaults
  python deploy.py --config my.json   # Use custom configuration
  python deploy.py --quiet --non-interactive  # Headless deployment
        """
    )
    
    parser.add_argument('--config', '-c', help='Custom configuration file path')
    parser.add_argument('--quick', '-q', action='store_true', help='Quick deployment with defaults')
    parser.add_argument('--quiet', action='store_true', help='Reduce output verbosity')
    parser.add_argument('--non-interactive', action='store_true', help='Non-interactive mode')
    parser.add_argument('--gui', action='store_true', help='Launch GUI interface (future feature)')
    parser.add_argument('--check', action='store_true', help='Check prerequisites only')
    
    args = parser.parse_args()
    
    # Handle GUI request
    if args.gui:
        try:
            # Import and run GUI
            gui_script = PROJECT_ROOT / "gui.py"
            subprocess.run([sys.executable, str(gui_script)])
            return 0
        except Exception as e:
            print(f"{Colors.RED}ERROR: Failed to launch GUI: {e}{Colors.RESET}")
            print(f"{Colors.YELLOW}Falling back to CLI interface...{Colors.RESET}")
            # Continue with CLI
    
    print_banner()
    
    # Prerequisites check
    print(f"\n{Colors.BOLD}🔍 Checking Prerequisites{Colors.RESET}")
    
    system, arch = detect_platform()
    print(f"OK: Platform: {system} {arch}")
    
    pwsh_cmd = check_powershell()
    if pwsh_cmd:
        print(f"OK: PowerShell: {pwsh_cmd}")
    else:
        print(f"{Colors.RED}ERROR: PowerShell 7+ not found{Colors.RESET}")
        if not args.check:
            print(install_powershell_instructions())
            return 1
    
    git_available = check_git()
    if git_available:
        print("OK: Git: Available")
    else:
        print(f"{Colors.YELLOW}WARNING:  Git: Not found (will be installed during deployment){Colors.RESET}")
    
    if args.check:
        print(f"\n{Colors.GREEN}OK: Prerequisites check complete{Colors.RESET}")
        return 0
    
    # Configuration
    config_path = args.config
    if not args.quick and not config_path and not args.non_interactive:
        setup_config = interactive_setup()
        if setup_config:
            # Save temporary config
            temp_config = PROJECT_ROOT / "temp-deploy-config.json"
            with open(temp_config, 'w') as f:
                json.dump(setup_config, f, indent=2)
            config_path = str(temp_config)
            print(f"{Colors.GREEN}OK: Temporary config saved: {temp_config}{Colors.RESET}")
    
    # Load and display configuration
    config = load_config(config_path)
    if config:
        print(f"\n{Colors.BOLD}Platform: Configuration Summary{Colors.RESET}")
        for key, value in config.items():
            print(f"  {key}: {value}")
    
    # Deployment
    print(f"\n{Colors.BOLD}>> Starting Deployment{Colors.RESET}")
    success = run_kicker_bootstrap(
        config_path=config_path,
        quiet=args.quiet,
        non_interactive=args.non_interactive or args.quick
    )
    
    # Cleanup temporary config
    temp_config = PROJECT_ROOT / "temp-deploy-config.json"
    if temp_config.exists():
        temp_config.unlink()
    
    # Results
    if success:
        print(f"\n{Colors.GREEN}{Colors.BOLD}🎉 Deployment completed successfully!{Colors.RESET}")
        print(f"\n{Colors.BLUE}Next steps:{Colors.RESET}")
        print("1. Check the deployment logs for any warnings")
        print("2. Verify your lab environment is accessible")
        print("3. Review the configuration for any needed adjustments")
        return 0
    else:
        print(f"\n{Colors.RED}{Colors.BOLD}ERROR: Deployment failed{Colors.RESET}")
        print(f"\n{Colors.BLUE}Troubleshooting:{Colors.RESET}")
        print("1. Check the error messages above")
        print("2. Verify your configuration file")
        print("3. Ensure all prerequisites are installed")
        print("4. Try running with --check to verify prerequisites")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        try:
            print(f"\n{Colors.YELLOW}WARNING: Deployment interrupted by user{Colors.RESET}")
        except UnicodeEncodeError:
            print("\nWARNING: Deployment interrupted by user")
        sys.exit(130)
    except Exception as e:
        try:
            print(f"\n{Colors.RED}ERROR: Unexpected error: {e}{Colors.RESET}")
        except UnicodeEncodeError:
            print(f"\nERROR: Unexpected error: {e}")
        sys.exit(1)


