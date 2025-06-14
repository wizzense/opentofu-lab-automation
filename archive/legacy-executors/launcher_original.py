#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Unified Launcher

A single cross-platform entry point that consolidates all deployment and GUI functionality.
Replaces multiple deploy/launch scripts with one intelligent launcher.

Usage:
    ./launcher.py                      # Interactive mode with menu
    ./launcher.py deploy               # Deploy lab environment
    ./launcher.py gui                  # Launch GUI interface
    ./launcher.py validate             # Validate setup
    ./launcher.py --help              # Show help

Supported Platforms: Windows, Linux, macOS
Python Requirements: 3.7+
"""

import os
import sys
import platform
import subprocess
import argparse
import json
from pathlib import Path
from typing import Dict, Optional, List

# Console colors for cross-platform output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color
    
    @classmethod
    def disable_on_windows(cls):
        """Disable colors on Windows if not supported"""
        if platform.system() == "Windows":
            try:
                # Try to enable ANSI color support on Windows 10+
                import ctypes
                kernel32 = ctypes.windll.kernel32
                kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
            except:
                # Fall back to no colors
                cls.RED = cls.GREEN = cls.YELLOW = cls.BLUE = cls.BOLD = cls.NC = ''

# Initialize colors
Colors.disable_on_windows()

class UnifiedLauncher:
    """Main launcher class that handles all operations"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.platform = platform.system()
        self.python_cmd = self._detect_python()
        
    def _detect_python(self) -> str:
        """Detect the best Python command to use"""
        candidates = ['python3', 'python']
        
        for cmd in candidates:
            try:
                result = subprocess.run([cmd, '--version'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0 and 'Python 3.' in result.stdout:
                    return cmd
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue
                
        return None
    
    def _print_header(self, title: str):
        """Print a formatted header"""
        print(f"{Colors.BLUE}{Colors.BOLD}")
        print("=" * 60)
        print(f"  {title}")
        print("=" * 60)
        print(f"{Colors.NC}")
    
    def _print_success(self, message: str):
        """Print success message"""
        print(f"{Colors.GREEN}✅ {message}{Colors.NC}")
    
    def _print_error(self, message: str):
        """Print error message"""
        print(f"{Colors.RED}❌ {message}{Colors.NC}")
    
    def _print_info(self, message: str):
        """Print info message"""
        print(f"{Colors.BLUE}ℹ️  {message}{Colors.NC}")
    
    def _print_warning(self, message: str):
        """Print warning message"""
        print(f"{Colors.YELLOW}⚠️  {message}{Colors.NC}")
    
    def check_prerequisites(self) -> bool:
        """Check if all prerequisites are met"""
        self._print_info("Checking prerequisites...")
        
        # Check Python
        if not self.python_cmd:
            self._print_error("Python 3.7+ is required but not found")
            self._print_platform_python_install_instructions()
            return False
        else:
            try:
                result = subprocess.run([self.python_cmd, '--version'], 
                                      capture_output=True, text=True)
                self._print_success(f"Python found: {result.stdout.strip()}")
            except:
                self._print_error("Python check failed")
                return False
        
        # Check tkinter for GUI functionality
        try:
            subprocess.run([self.python_cmd, '-c', 'import tkinter'], 
                         capture_output=True, check=True)
            self._print_success("GUI support (tkinter) available")
        except subprocess.CalledProcessError:
            self._print_warning("GUI support (tkinter) not available - deploy mode only")
        
        # Check project structure
        required_files = ['deploy.py', 'gui.py', 'configs', 'pwsh', 'scripts']
        missing_files = []
        
        for file_path in required_files:
            if not (self.project_root / file_path).exists():
                missing_files.append(file_path)
        
        if missing_files:
            self._print_error(f"Missing required files/directories: {', '.join(missing_files)}")
            return False
        else:
            self._print_success("Project structure validated")
        
        return True
    
    def _print_platform_python_install_instructions(self):
        """Print platform-specific Python installation instructions"""
        print(f"\n{Colors.YELLOW}Python Installation Instructions:{Colors.NC}")
        
        if self.platform == "Windows":
            print("• Download from: https://python.org")
            print("• Make sure to check 'Add Python to PATH' during installation")
        elif self.platform == "Darwin":  # macOS
            print("• Install with Homebrew: brew install python3")
            print("• Or download from: https://python.org")
        else:  # Linux
            print("• Ubuntu/Debian: sudo apt install python3")
            print("• CentOS/RHEL: sudo yum install python3")
            print("• Or use your distribution's package manager")
    
    def show_interactive_menu(self):
        """Show interactive menu for user selection"""
        self._print_header("OpenTofu Lab Automation - Unified Launcher")
        
        options = [
            ("1", "Deploy Lab Environment", "deploy"),
            ("2", "Launch GUI Interface", "gui"),
            ("3", "Validate Setup", "validate"),
            ("4", "Run Health Check", "health"),
            ("5", "Re-clone Repository", "reclone"),
            ("6", "Show Help", "help"),
            ("q", "Quit", "quit")
        ]
        
        print("Select an option:")
        for key, description, _ in options:
            print(f"  {Colors.BOLD}{key}{Colors.NC}. {description}")
        
        print()
        choice = input(f"{Colors.BLUE}Enter your choice (1-6, q): {Colors.NC}").strip().lower()
        
        for key, _, action in options:
            if choice == key:
                return action
        
        self._print_warning("Invalid choice, please try again")
        return None
    
    def run_deployment(self, args: List[str] = None):
        """Run deployment using deploy.py"""
        self._print_header("Deploying Lab Environment")
        
        cmd = [self.python_cmd, str(self.project_root / "deploy.py")]
        if args:
            cmd.extend(args)
        
        try:
            result = subprocess.run(cmd, cwd=self.project_root)
            if result.returncode == 0:
                self._print_success("Deployment completed successfully")
            else:
                self._print_error("Deployment encountered errors")
                return False
        except Exception as e:
            self._print_error(f"Deployment failed: {e}")
            return False
        
        return True
    
    def run_gui(self):
        """Launch GUI interface"""
        self._print_header("Launching GUI Interface")
        
        # Check if tkinter is available
        try:
            subprocess.run([self.python_cmd, '-c', 'import tkinter'], 
                         capture_output=True, check=True)
        except subprocess.CalledProcessError:
            self._print_error("GUI not available - tkinter is required")
            self._print_info("Try installing tkinter:")
            if self.platform == "Linux":
                print("  Ubuntu/Debian: sudo apt install python3-tk")
                print("  CentOS/RHEL: sudo yum install tkinter")
            return False
        
        cmd = [self.python_cmd, str(self.project_root / "gui.py")]
        
        try:
            subprocess.run(cmd, cwd=self.project_root)
            self._print_success("GUI session completed")
        except Exception as e:
            self._print_error(f"GUI launch failed: {e}")
            return False
        
        return True
    
    def run_validation(self):
        """Run validation checks"""
        self._print_header("Running Validation Checks")
        
        # Run PowerShell validation if available
        pwsh_cmd = self._get_powershell_command()
        if pwsh_cmd:
            validation_script = self.project_root / "scripts" / "maintenance" / "unified-maintenance.ps1"
            if validation_script.exists():
                cmd = [pwsh_cmd, "-File", str(validation_script), "-Mode", "Quick"]
                try:
                    result = subprocess.run(cmd, cwd=self.project_root)
                    if result.returncode == 0:
                        self._print_success("PowerShell validation completed")
                    else:
                        self._print_warning("PowerShell validation had issues")
                except Exception as e:
                    self._print_error(f"PowerShell validation failed: {e}")
            else:
                self._print_warning("PowerShell validation script not found")
        else:
            self._print_warning("PowerShell not available - skipping PowerShell validation")
        
        # Run basic Python validation
        try:
            cmd = [self.python_cmd, "-c", "import json; print('Python JSON validation: OK')"]
            subprocess.run(cmd, check=True)
            self._print_success("Python validation completed")
        except Exception as e:
            self._print_error(f"Python validation failed: {e}")
            return False
        
        return True
    
    def run_health_check(self):
        """Run comprehensive health check"""
        self._print_header("Running Health Check")
        
        checks_passed = 0
        total_checks = 4
        
        # Check 1: Prerequisites
        if self.check_prerequisites():
            checks_passed += 1
        
        # Check 2: Config files
        config_dir = self.project_root / "configs"
        if config_dir.exists() and any(config_dir.iterdir()):
            self._print_success("Configuration files found")
            checks_passed += 1
        else:
            self._print_warning("Configuration files missing or empty")
        
        # Check 3: PowerShell modules
        pwsh_modules = self.project_root / "pwsh" / "modules"
        if pwsh_modules.exists() and any(pwsh_modules.iterdir()):
            self._print_success("PowerShell modules found")
            checks_passed += 1
        else:
            self._print_warning("PowerShell modules missing")
        
        # Check 4: Documentation
        readme = self.project_root / "README.md"
        if readme.exists() and readme.stat().st_size > 1000:  # At least 1KB
            self._print_success("Documentation found")
            checks_passed += 1
        else:
            self._print_warning("Documentation missing or incomplete")
        
        print(f"\n{Colors.BOLD}Health Check Summary:{Colors.NC}")
        print(f"  Checks passed: {checks_passed}/{total_checks}")
        
        if checks_passed == total_checks:
            self._print_success("All health checks passed!")
            return True
        elif checks_passed >= total_checks // 2:
            self._print_warning("Some issues found but system is functional")
            return True
        else:
            self._print_error("Multiple issues found - system may not work correctly")
            return False
    
    def reclone_repository(self):
        """Re-clone the repository to refresh the codebase"""
        self._print_header("Re-cloning Repository")
        
        # Confirm with user
        print(f"{Colors.YELLOW}⚠️  This will:")
        print("   • Create a backup of current directory")
        print("   • Download fresh copy from GitHub")
        print("   • Preserve your configuration files")
        print("   • Remove old files and replace with latest version")
        print(f"{Colors.NC}")
        
        confirm = input(f"{Colors.BLUE}Continue? (y/N): {Colors.NC}").strip().lower()
        if confirm != 'y':
            self._print_info("Operation cancelled")
            return False
        
        try:
            import shutil
            import tempfile
            from datetime import datetime
            
            # Create backup directory
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
            backup_dir = self.project_root.parent / f"opentofu-lab-backup-{timestamp}"
            
            self._print_info(f"Creating backup at: {backup_dir}")
            
            # Backup current configs
            configs_backup = None
            configs_dir = self.project_root / "configs"
            if configs_dir.exists():
                configs_backup = tempfile.mkdtemp()
                shutil.copytree(configs_dir, Path(configs_backup) / "configs")
                self._print_success("Configuration files backed up")
            
            # Backup current directory
            shutil.copytree(self.project_root, backup_dir)
            self._print_success(f"Full backup created: {backup_dir}")
            
            # Clone fresh repository
            repo_url = "https://github.com/wizzense/opentofu-lab-automation.git"
            temp_clone = tempfile.mkdtemp()
            
            self._print_info("Downloading fresh repository...")
            result = subprocess.run(['git', 'clone', repo_url, temp_clone], 
                                  capture_output=True, text=True)
            
            if result.returncode != 0:
                self._print_error(f"Git clone failed: {result.stderr}")
                return False
            
            # Remove old files (except .git if it exists)
            git_dir = self.project_root / ".git"
            git_backup = None
            if git_dir.exists():
                git_backup = tempfile.mkdtemp()
                shutil.copytree(git_dir, Path(git_backup) / ".git")
            
            # Clear current directory
            for item in self.project_root.iterdir():
                if item.name != ".git":
                    if item.is_dir():
                        shutil.rmtree(item)
                    else:
                        item.unlink()
            
            # Copy fresh files
            temp_clone_path = Path(temp_clone)
            for item in temp_clone_path.iterdir():
                if item.name != ".git":
                    dest = self.project_root / item.name
                    if item.is_dir():
                        shutil.copytree(item, dest)
                    else:
                        shutil.copy2(item, dest)
            
            # Restore .git if we had it
            if git_backup:
                shutil.copytree(Path(git_backup) / ".git", self.project_root / ".git")
            
            # Restore configs
            if configs_backup:
                shutil.copytree(Path(configs_backup) / "configs", self.project_root / "configs")
                self._print_success("Configuration files restored")
            
            # Cleanup temp directories
            shutil.rmtree(temp_clone)
            if configs_backup:
                shutil.rmtree(configs_backup)
            if git_backup:
                shutil.rmtree(git_backup)
            
            self._print_success("Repository successfully refreshed!")
            self._print_info(f"Backup available at: {backup_dir}")
            self._print_info("Please restart the launcher to use the updated code")
            
            return True
            
        except Exception as e:
            self._print_error(f"Re-clone failed: {e}")
            return False

def main():
    """Main entry point"""
    launcher = UnifiedLauncher()
    
    parser = argparse.ArgumentParser(description="OpenTofu Lab Automation - Unified Launcher")
    parser.add_argument('action', nargs='?', 
                       choices=['deploy', 'gui', 'validate', 'health', 'reclone', 'help'],
                       help='Action to perform')
    parser.add_argument('--quick', action='store_true',
                       help='Quick mode with minimal prompts')
    parser.add_argument('--config', type=str,
                       help='Custom configuration file')
    
    args, unknown_args = parser.parse_known_args()
    
    # Always check prerequisites first
    if not launcher.check_prerequisites() and args.action not in ['help', None]:
        launcher._print_error("Prerequisites not met. Please install required software.")
        return 1
    
    # Handle command line actions
    if args.action == 'deploy':
        deploy_args = []
        if args.quick:
            deploy_args.append('--quick')
        if args.config:
            deploy_args.extend(['--config', args.config])
        deploy_args.extend(unknown_args)
        
        success = launcher.run_deployment(deploy_args)
        return 0 if success else 1
        
    elif args.action == 'gui':
        success = launcher.run_gui()
        return 0 if success else 1
        
    elif args.action == 'validate':
        success = launcher.run_validation()
        return 0 if success else 1
        
    elif args.action == 'health':
        success = launcher.run_health_check()
        return 0 if success else 1
        
    elif args.action == 'reclone':
        success = launcher.reclone_repository()
        return 0 if success else 1
        
    elif args.action == 'help':
        launcher.show_help()
        return 0
    
    # Interactive mode
    else:
        while True:
            action = launcher.show_interactive_menu()
            
            if action == 'quit':
                launcher._print_info("Goodbye!")
                return 0
            elif action == 'deploy':
                launcher.run_deployment()
            elif action == 'gui':
                launcher.run_gui()
            elif action == 'validate':
                launcher.run_validation()
            elif action == 'health':
                launcher.run_health_check()
            elif action == 'reclone':
                if launcher.reclone_repository():
                    launcher._print_info("Repository refreshed! Exiting to restart with new code...")
                    return 0
            elif action == 'help':
                launcher.show_help()
            
            if action:
                print(f"\n{Colors.BLUE}Press Enter to return to menu...{Colors.NC}")
                input()

if __name__ == "__main__":
    sys.exit(main())
