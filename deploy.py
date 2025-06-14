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
        # Force UTF-8 environment
        os.environ['PYTHONIOENCODING'] = 'utf-8'
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
        with open(config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        print(f"{Colors.GREEN}OK: Loaded config: {config_file}{Colors.RESET}")
        return config
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}ERROR: Invalid JSON in config file: {e}{Colors.RESET}")
        return {}

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
        '-NoProfile',           # Don't load PowerShell profile
        '-NonInteractive',      # Don't prompt for user input
        '-ExecutionPolicy', 'Bypass',  # Bypass execution policy
        '-File', str(kicker_script)
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
        # Set up environment with proper encoding and paths
        env = os.environ.copy()
        env['PYTHONIOENCODING'] = 'utf-8'
        env['PWD'] = str(PROJECT_ROOT)
        
        if system == 'windows':
            # Windows-specific environment setup
            env['TEMP'] = str(PROJECT_ROOT / 'temp')
            env['TMP'] = str(PROJECT_ROOT / 'temp')
            (PROJECT_ROOT / 'temp').mkdir(exist_ok=True)
        
        # Run with proper encoding and working directory
        result = subprocess.run(
            cmd, 
            cwd=str(PROJECT_ROOT),
            env=env,
            encoding='utf-8',
            errors='replace',
            timeout=1800  # 30 minute timeout
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
        print(f"\n{Colors.YELLOW}WARNING:  Deployment interrupted by user{Colors.RESET}")
        return False
    except Exception as e:
        print(f"{Colors.RED}ERROR: Error running PowerShell script: {e}{Colors.RESET}")
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

def ensure_project_files():
    """Ensure project files are available in working directory"""
    
    # Check if we already have the project structure
    if (PROJECT_ROOT / "pwsh").exists() and (PROJECT_ROOT / "configs").exists():
        print(f"{Colors.GREEN}✓ Project files found in {PROJECT_ROOT}{Colors.RESET}")
        return True
    
    print(f"{Colors.YELLOW}📥 Project files not found in {PROJECT_ROOT}. Setting up...{Colors.RESET}")
    
    # Try to find project files in common locations
    possible_sources = []
    
    # 1. Where this script was originally run from
    script_dir = Path(__file__).parent
    if (script_dir / "pwsh").exists():
        possible_sources.append(script_dir)
    
    # 2. Current working directory
    cwd = Path.cwd()
    if (cwd / "pwsh").exists():
        possible_sources.append(cwd)
    
    # 3. Parent directories
    for parent in [cwd.parent, cwd.parent.parent]:
        if (parent / "pwsh").exists():
            possible_sources.append(parent)
    
    # 4. Common download locations
    if platform.system() == "Windows":
        common_locations = [
            Path.home() / "Downloads" / "opentofu-lab-automation",
            Path("C:/Users") / os.environ.get('USERNAME', '') / "Downloads" / "opentofu-lab-automation",
            Path("C:/temp") / "opentofu-lab-automation"
        ]
    else:
        common_locations = [
            Path.home() / "Downloads" / "opentofu-lab-automation",
            Path("/tmp") / "opentofu-lab-automation"
        ]
    
    for location in common_locations:
        if location.exists() and (location / "pwsh").exists():
            possible_sources.append(location)
    
    # Copy from the first valid source
    if possible_sources:
        source = possible_sources[0]
        print(f"{Colors.BLUE}📂 Copying project files from {source}...{Colors.RESET}")
        
        try:
            import shutil
            
            # Copy essential directories
            for dir_name in ["pwsh", "configs", "scripts", "docs"]:
                source_dir = source / dir_name
                if source_dir.exists():
                    dest_dir = PROJECT_ROOT / dir_name
                    if dest_dir.exists():
                        shutil.rmtree(dest_dir)
                    shutil.copytree(source_dir, dest_dir)
                    print(f"  ✓ Copied {dir_name}/")
            
            # Copy essential files
            for file_name in ["README.md", "LICENSE", "launcher.py", "gui.py"]:
                source_file = source / file_name
                if source_file.exists():
                    shutil.copy2(source_file, PROJECT_ROOT / file_name)
                    print(f"  ✓ Copied {file_name}")
            
            print(f"{Colors.GREEN}✓ Project setup complete in {PROJECT_ROOT}{Colors.RESET}")
            return True
            
        except Exception as e:
            print(f"{Colors.RED}✗ Failed to copy project files: {e}{Colors.RESET}")
    
    # Last resort: try to download
    print(f"{Colors.YELLOW}⬇️ Attempting to download project files...{Colors.RESET}")
    
    try:
        # Try git clone first
        result = subprocess.run([
            'git', 'clone', 
            'https://github.com/wizzense/opentofu-lab-automation.git',
            str(PROJECT_ROOT)
        ], capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print(f"{Colors.GREEN}✓ Downloaded project via git{Colors.RESET}")
            return True
        else:
            print(f"{Colors.YELLOW}Git clone failed, trying alternative download...{Colors.RESET}")
    
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    # Fallback: create minimal structure and download essential files
    try:
        (PROJECT_ROOT / "configs" / "config_files").mkdir(parents=True, exist_ok=True)
        (PROJECT_ROOT / "pwsh").mkdir(parents=True, exist_ok=True)
        
        # Download default config
        import urllib.request
        config_url = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/configs/config_files/default-config.json"
        urllib.request.urlretrieve(config_url, DEFAULT_CONFIG)
        
        print(f"{Colors.GREEN}✓ Downloaded essential configuration files{Colors.RESET}")
        return True
        
    except Exception as e:
        print(f"{Colors.RED}✗ Failed to download project files: {e}{Colors.RESET}")
        print(f"{Colors.YELLOW}Manual setup required. Please clone the repository to {PROJECT_ROOT}{Colors.RESET}")
        return False

# ...existing code...
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
    
    # Ensure project files are available in working directory
    if not ensure_project_files():
        print(f"{Colors.RED}ERROR: Unable to set up project files. Deployment cannot continue.{Colors.RESET}")
        return 1
    
    # Change to working directory
    os.chdir(PROJECT_ROOT)
    print(f"{Colors.GREEN}✓ Working directory: {PROJECT_ROOT}{Colors.RESET}")
    
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
    
    # Ensure project files are available
    files_available = ensure_project_files()
    if not files_available:
        print(f"{Colors.RED}ERROR: Required project files are missing{Colors.RESET}")
        print(f"{Colors.YELLOW}Manual setup required. Please clone the repository to {PROJECT_ROOT}{Colors.RESET}")
        return 1
    
    # Configuration
    config_path = args.config
    if not args.quick and not config_path and not args.non_interactive:
        setup_config = interactive_setup()
        if setup_config:
            # Save temporary config
            temp_config = PROJECT_ROOT / "temp-deploy-config.json"
            with open(temp_config, 'w', encoding='utf-8') as f:
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


