#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Unified Launcher (Consolidated)

Merges functionality from launcher.py and enhanced_launcher.py into a single,
comprehensive cross-platform entry point for all deployment and GUI functionality.

Features:
- Interactive menu system
- GUI interface launching
- Configuration builder
- Enhanced deployment
- Health checks and validation
- Repository re-cloning
- Cross-platform working directory management

Usage:
    ./launcher.py                      # Interactive mode with menu
    ./launcher.py deploy               # Deploy lab environment
    ./launcher.py gui                  # Launch GUI interface
    ./launcher.py config               # Configuration builder
    ./launcher.py validate             # Validate setup
    ./launcher.py health               # Health check
    ./launcher.py reclone              # Re-clone repository
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
import shutil
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

def get_working_directory():
    """Get and ensure proper working directory exists"""
    if platform.system() == "Windows":
        work_dir = Path("C:/temp/opentofu-lab-automation")
    else:
        work_dir = Path("/tmp/opentofu-lab-automation")
    
    work_dir.mkdir(parents=True, exist_ok=True)
    return work_dir

def ensure_utf8_encoding():
    """Ensure UTF-8 encoding for Windows compatibility"""
    if platform.system() == "Windows":
        try:
            os.environ['PYTHONUTF8'] = '1'
            sys.stdout.reconfigure(encoding='utf-8')
            sys.stderr.reconfigure(encoding='utf-8')
        except:
            pass

class UnifiedLauncher:
    """Main launcher class that handles all operations"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent
        self.working_directory = get_working_directory()
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
    
    def _get_powershell_command(self) -> Optional[str]:
        """Get available PowerShell command"""
        candidates = ['pwsh', 'powershell'] if self.platform == "Windows" else ['pwsh']
        
        for cmd in candidates:
            try:
                result = subprocess.run([cmd, '-NoProfile', '-NonInteractive', '-Command', 'Write-Host "OK"'],
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    return cmd
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue
        return None
    
    def _print_header(self, title: str):
        """Print a formatted header"""
        print(f"{Colors.BLUE}{Colors.BOLD}")
        print("=" * 70)
        print(f"  {title}")
        print("=" * 70)
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
    
    def print_banner(self):
        """Display enhanced launcher banner"""
        banner = f"""
{'='*70}
    OpenTofu Lab Automation - Unified Launcher
    
    🚀 Enhanced Configuration & Deployment Tools
    🔧 Working Directory Enforcement 
    🌐 Cross-Platform Support
    ⚡ Improved Error Handling
    📦 Repository Management
{'='*70}

Platform: {self.platform} {platform.release()}
Working Directory: {self.working_directory}
Project Root: {self.project_root}
Python: {sys.version.split()[0]}
"""
        print(banner)
    
    def check_prerequisites(self) -> bool:
        """Check if all prerequisites are met"""
        self._print_info("Checking prerequisites...")
        
        issues = []
        
        # Check Python
        if not self.python_cmd:
            issues.append("Python 3.7+ is required")
            self._print_error("Python 3.7+ not found")
        else:
            self._print_success(f"Python found: {self.python_cmd}")
        
        # Check tkinter for GUI functionality
        try:
            import tkinter
            self._print_success("Tkinter (GUI support) available")
        except ImportError:
            issues.append("Tkinter not available (GUI features disabled)")
            self._print_warning("Tkinter not available (GUI features disabled)")
        
        # Check PowerShell
        pwsh_cmd = self._get_powershell_command()
        if pwsh_cmd:
            self._print_success(f"PowerShell found: {pwsh_cmd}")
        else:
            issues.append("PowerShell not found (required for deployment)")
            self._print_error("PowerShell not found")
        
        # Check project structure
        required_files = ['deploy.py', 'configs', 'pwsh', 'scripts']
        missing_files = []
        
        for file_path in required_files:
            full_path = self.project_root / file_path
            if full_path.exists():
                self._print_success(f"Found: {file_path}")
            else:
                missing_files.append(file_path)
                self._print_warning(f"Missing: {file_path}")
        
        if missing_files:
            issues.append(f"Missing project files: {', '.join(missing_files)}")
        
        if issues:
            self._print_error("Prerequisites check failed:")
            for issue in issues:
                print(f"  - {issue}")
            return False
        else:
            self._print_success("All prerequisites met")
            return True
    
    def show_interactive_menu(self):
        """Show interactive menu for user selection"""
        self.print_banner()
        
        options = [
            ("1", "Deploy Lab Environment", "deploy"),
            ("2", "Launch GUI Interface", "gui"),
            ("3", "Configuration Builder", "config"),
            ("4", "Validate Setup", "validate"),
            ("5", "Run Health Check", "health"),
            ("6", "Re-clone Repository", "reclone"),
            ("7", "Show Help", "help"),
            ("q", "Quit", "quit")
        ]
        
        print("Select an option:")
        for key, description, _ in options:
            print(f"  {Colors.BLUE}{key}{Colors.NC}. {description}")
        
        print()
        choice = input(f"{Colors.BLUE}Enter your choice (1-7, q): {Colors.NC}").strip().lower()
        
        for key, _, action in options:
            if choice == key.lower():
                return action
        
        self._print_warning("Invalid choice, please try again")
        return None
    
    def ensure_project_files(self, work_dir: Path = None):
        """Ensure project files are available in working directory"""
        if work_dir is None:
            work_dir = self.working_directory
            
        if (work_dir / "configs").exists() and (work_dir / "pwsh").exists():
            self._print_success(f"Project files found in {work_dir}")
            return True
        
        self._print_info(f"Setting up project files in {work_dir}...")
        
        # Copy from script location
        script_dir = self.project_root
        
        try:
            # Copy essential directories
            for dir_name in ["configs", "pwsh", "py", "scripts", "docs"]:
                src_dir = script_dir / dir_name
                dest_dir = work_dir / dir_name
                
                if src_dir.exists():
                    if dest_dir.exists():
                        shutil.rmtree(dest_dir)
                    shutil.copytree(src_dir, dest_dir)
                    self._print_success(f"Copied {dir_name}")
            
            # Copy essential files
            for file_name in ["deploy.py", "launcher.py", "PROJECT-MANIFEST.json", "AGENTS.md"]:
                src_file = script_dir / file_name
                dest_file = work_dir / file_name
                
                if src_file.exists():
                    shutil.copy2(src_file, dest_file)
                    self._print_success(f"Copied {file_name}")
            
            self._print_success("Project setup complete")
            return True
            
        except Exception as e:
            self._print_error(f"Failed to setup project files: {e}")
            return False
    
    def run_deployment(self, args: List[str] = None):
        """Run deployment using deploy.py"""
        self._print_header("Deploying Lab Environment")
        
        # Ensure project files
        if not self.ensure_project_files(self.working_directory):
            return False
        
        os.chdir(self.working_directory)
        
        cmd = [self.python_cmd, str(self.working_directory / "deploy.py")]
        if args:
            cmd.extend(args)
        
        try:
            result = subprocess.run(cmd, cwd=str(self.working_directory))
            if result.returncode == 0:
                self._print_success("Deployment completed successfully")
            else:
                self._print_error(f"Deployment failed with exit code {result.returncode}")
            return result.returncode == 0
        except Exception as e:
            self._print_error(f"Deployment error: {e}")
            return False
    
    def run_gui(self):
        """Launch GUI interface"""
        self._print_header("Launching GUI Interface")
        
        # Check if tkinter is available
        try:
            import tkinter
        except ImportError:
            self._print_error("Tkinter not available. Please install tkinter for GUI support.")
            return False
        
        # Ensure project files
        if not self.ensure_project_files(self.working_directory):
            return False
        
        os.chdir(self.working_directory)
        
        # Try enhanced GUI first, fallback to regular GUI
        gui_files = ["gui_enhanced.py", "gui.py"]
        
        for gui_file in gui_files:
            gui_path = self.working_directory / gui_file
            if gui_path.exists():
                try:
                    self._print_info(f"Launching {gui_file}...")
                    result = subprocess.run([self.python_cmd, str(gui_path)], 
                                          cwd=str(self.working_directory))
                    return result.returncode == 0
                except Exception as e:
                    self._print_warning(f"Failed to launch {gui_file}: {e}")
                    continue
        
        self._print_error("No GUI interface found")
        return False
    
    def run_config_builder(self):
        """Launch configuration builder"""
        self._print_header("Configuration Builder")
        
        # Ensure project files
        if not self.ensure_project_files(self.working_directory):
            return False
        
        os.chdir(self.working_directory)
        
        try:
            # Try to import and use configuration schema
            sys.path.append(str(self.working_directory))
            
            # Create basic configuration interactively
            config = {}
            
            print("\nConfiguration Builder - Enter values (press Enter for defaults):")
            print("-" * 60)
            
            # Basic configuration sections
            config['environment'] = {
                'name': input("Environment name [default]: ").strip() or "default",
                'type': input("Environment type (dev/test/prod) [dev]: ").strip() or "dev"
            }
            
            config['deployment'] = {
                'auto_deploy': input("Auto deploy (true/false) [true]: ").strip().lower() in ['true', 'yes', 'y', ''] or True,
                'timeout': int(input("Deployment timeout (seconds) [300]: ").strip() or "300")
            }
            
            config['powershell'] = {
                'execution_policy': input("PowerShell execution policy [Bypass]: ").strip() or "Bypass",
                'non_interactive': True
            }
            
            # Save configuration
            config_dir = self.working_directory / "configs" / "config_files"
            config_dir.mkdir(parents=True, exist_ok=True)
            config_file = config_dir / "launcher-generated-config.json"
            
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2)
            
            self._print_success(f"Configuration saved to: {config_file}")
            print(f"\nTo deploy with this configuration:")
            print(f"  python deploy.py --config {config_file}")
            
            return True
            
        except Exception as e:
            self._print_error(f"Configuration builder error: {e}")
            return False
    
    def run_validation(self):
        """Run validation checks"""
        self._print_header("Running Validation Checks")
        
        # Run PowerShell validation if available
        pwsh_cmd = self._get_powershell_command()
        if pwsh_cmd:
            validation_script = self.project_root / "scripts" / "maintenance" / "unified-maintenance.ps1"
            if validation_script.exists():
                try:
                    cmd = [pwsh_cmd, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
                           '-File', str(validation_script), '-Mode', 'Quick']
                    result = subprocess.run(cmd, cwd=str(self.project_root))
                    if result.returncode == 0:
                        self._print_success("PowerShell validation passed")
                    else:
                        self._print_warning("PowerShell validation had issues")
                except Exception as e:
                    self._print_warning(f"PowerShell validation error: {e}")
            else:
                self._print_warning("PowerShell validation script not found")
        else:
            self._print_warning("PowerShell not available for validation")
        
        # Run basic Python validation
        try:
            # Test PowerShell executor
            sys.path.append(str(self.project_root / "py"))
            from powershell_executor import PowerShellExecutor
            
            executor = PowerShellExecutor(working_directory=str(self.working_directory))
            if executor.test_execution():
                self._print_success("PowerShell executor validation passed")
            else:
                self._print_error("PowerShell executor validation failed")
        except Exception as e:
            self._print_error(f"Python validation error: {e}")
        
        return True
    
    def run_health_check(self):
        """Run comprehensive health check"""
        self._print_header("Running Health Check")
        
        checks_passed = 0
        total_checks = 5
        
        # Check 1: Prerequisites
        if self.check_prerequisites():
            checks_passed += 1
        
        # Check 2: Config files
        config_dir = self.project_root / "configs"
        if config_dir.exists() and any(config_dir.iterdir()):
            self._print_success("Configuration files found")
            checks_passed += 1
        else:
            self._print_warning("No configuration files found")
        
        # Check 3: PowerShell modules
        pwsh_modules = self.project_root / "pwsh" / "modules"
        if pwsh_modules.exists() and any(pwsh_modules.iterdir()):
            self._print_success("PowerShell modules found")
            checks_passed += 1
        else:
            self._print_warning("PowerShell modules not found")
        
        # Check 4: Documentation
        readme = self.project_root / "README.md"
        if readme.exists() and readme.stat().st_size > 1000:
            self._print_success("Documentation found")
            checks_passed += 1
        else:
            self._print_warning("Documentation missing or incomplete")
        
        # Check 5: Working directory
        if self.working_directory.exists() and os.access(self.working_directory, os.W_OK):
            self._print_success("Working directory accessible")
            checks_passed += 1
        else:
            self._print_error("Working directory not accessible")
        
        print(f"\n{Colors.BOLD}Health Check Summary:{Colors.NC}")
        print(f"  Checks passed: {checks_passed}/{total_checks}")
        
        if checks_passed == total_checks:
            self._print_success("System is healthy")
        elif checks_passed >= total_checks // 2:
            self._print_warning("System has some issues but is functional")
        else:
            self._print_error("System has significant issues")
        
        return checks_passed >= total_checks // 2
    
    def reclone_repository(self):
        """Re-clone the repository to refresh the codebase"""
        self._print_header("Re-cloning Repository")
        
        # This is a placeholder - in practice, you'd need the repository URL
        # and would clone to a fresh location, then copy files over
        
        repo_url = input("Enter repository URL (or press Enter to skip): ").strip()
        if not repo_url:
            self._print_info("Repository re-clone skipped")
            return True
        
        try:
            # Clone to a temporary location
            temp_dir = self.working_directory.parent / "temp-clone"
            if temp_dir.exists():
                shutil.rmtree(temp_dir)
            
            self._print_info(f"Cloning repository from {repo_url}...")
            result = subprocess.run(['git', 'clone', repo_url, str(temp_dir)], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self._print_success("Repository cloned successfully")
                
                # Copy new files over
                if self.ensure_project_files(temp_dir):
                    self._print_success("Repository refresh completed")
                    return True
                else:
                    self._print_error("Failed to update project files")
                    return False
            else:
                self._print_error(f"Git clone failed: {result.stderr}")
                return False
                
        except Exception as e:
            self._print_error(f"Repository re-clone error: {e}")
            return False


def main():
    """Main entry point"""
    ensure_utf8_encoding()
    
    launcher = UnifiedLauncher()
    
    parser = argparse.ArgumentParser(description="OpenTofu Lab Automation - Unified Launcher")
    parser.add_argument('action', nargs='?', 
                       choices=['deploy', 'gui', 'config', 'validate', 'health', 'reclone', 'help'],
                       help='Action to perform')
    parser.add_argument('--quick', action='store_true',
                       help='Quick mode with minimal prompts')
    parser.add_argument('--config', type=str,
                       help='Custom configuration file')
    
    args, unknown_args = parser.parse_known_args()
    
    # Handle command line actions
    if args.action == 'deploy':
        if not launcher.check_prerequisites():
            sys.exit(1)
        deploy_args = unknown_args
        if args.config:
            deploy_args.extend(['--config', args.config])
        if args.quick:
            deploy_args.append('--quick')
        success = launcher.run_deployment(deploy_args)
        sys.exit(0 if success else 1)
        
    elif args.action == 'gui':
        if not launcher.check_prerequisites():
            sys.exit(1)
        success = launcher.run_gui()
        sys.exit(0 if success else 1)
        
    elif args.action == 'config':
        success = launcher.run_config_builder()
        sys.exit(0 if success else 1)
        
    elif args.action == 'validate':
        success = launcher.run_validation()
        sys.exit(0 if success else 1)
        
    elif args.action == 'health':
        success = launcher.run_health_check()
        sys.exit(0 if success else 1)
        
    elif args.action == 'reclone':
        success = launcher.reclone_repository()
        sys.exit(0 if success else 1)
        
    elif args.action == 'help':
        parser.print_help()
        sys.exit(0)
    else:
        # Interactive mode
        while True:
            action = launcher.show_interactive_menu()
            if action is None:
                continue
            elif action == 'quit':
                print("Goodbye!")
                sys.exit(0)
            elif action == 'deploy':
                launcher.run_deployment()
            elif action == 'gui':
                launcher.run_gui()
            elif action == 'config':
                launcher.run_config_builder()
            elif action == 'validate':
                launcher.run_validation()
            elif action == 'health':
                launcher.run_health_check()
            elif action == 'reclone':
                launcher.reclone_repository()
            elif action == 'help':
                parser.print_help()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Operation cancelled by user{Colors.NC}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Fatal error: {e}{Colors.NC}")
        sys.exit(1)
