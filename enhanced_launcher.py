#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Enhanced Launcher

Provides access to the enhanced configuration builder and deployment tools.
Includes working directory enforcement and improved error handling.

Usage:
    python enhanced_launcher.py                    # Interactive menu
    python enhanced_launcher.py --gui              # Launch enhanced GUI
    python enhanced_launcher.py --config-builder   # Configuration builder only
    python enhanced_launcher.py --deploy          # Deploy with enhanced features
"""

import os
import sys
import platform
import subprocess
import argparse
from pathlib import Path
import json

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
            import codecs
            sys.stdout.reconfigure(encoding='utf-8')
            sys.stderr.reconfigure(encoding='utf-8')
            os.environ['PYTHONIOENCODING'] = 'utf-8'
        except:
            pass

def print_banner():
    """Display enhanced launcher banner"""
    banner = f"""
{'='*70}
    OpenTofu Lab Automation - Enhanced Launcher
    
    🚀 Enhanced Configuration & Deployment Tools
    🔧 Working Directory Enforcement 
    🌐 Cross-Platform Support
    ⚡ Improved Error Handling
{'='*70}

Platform: {platform.system()} {platform.release()}
Working Directory: {get_working_directory()}
Python: {sys.version.split()[0]}
"""
    print(banner)

def check_dependencies():
    """Check for required dependencies"""
    print("🔍 Checking dependencies...")
    
    issues = []
    
    # Check Python version
    if sys.version_info < (3, 7):
        issues.append("Python 3.7+ is required")
    else:
        print(f"  ✓ Python {sys.version.split()[0]}")
    
    # Check tkinter for GUI
    try:
        import tkinter
        print("  ✓ Tkinter (GUI support)")
    except ImportError:
        issues.append("Tkinter not available (GUI features disabled)")
        print("  ⚠ Tkinter not available (GUI features disabled)")
    
    # Check PowerShell
    pwsh_available = False
    for cmd in ['pwsh', 'powershell']:
        try:
            result = subprocess.run([cmd, '-Command', 'Write-Host "OK"'], 
                                  capture_output=True, timeout=5)
            if result.returncode == 0:
                print(f"  ✓ PowerShell ({cmd})")
                pwsh_available = True
                break
        except:
            continue
    
    if not pwsh_available:
        issues.append("PowerShell not found (required for deployment)")
        print("  ✗ PowerShell not found")
    
    return issues

def launch_enhanced_gui():
    """Launch the enhanced GUI"""
    print("🚀 Launching Enhanced GUI...")
    
    work_dir = get_working_directory()
    os.chdir(work_dir)
    
    # Copy project files if needed
    ensure_project_files(work_dir)
    
    try:
        gui_script = Path(__file__).parent / "gui_enhanced.py"
        if not gui_script.exists():
            print(f"✗ Enhanced GUI script not found: {gui_script}")
            return False
        
        subprocess.run([sys.executable, str(gui_script)], cwd=str(work_dir))
        return True
        
    except Exception as e:
        print(f"✗ Failed to launch enhanced GUI: {e}")
        return False

def launch_config_builder():
    """Launch configuration builder in CLI mode"""
    print("🔧 Configuration Builder")
    print("=" * 50)
    
    work_dir = get_working_directory()
    os.chdir(work_dir)
    
    # Import configuration schema
    try:
        sys.path.append(str(Path(__file__).parent))
        from config_schema_simple import ConfigSchema
        
        schema = ConfigSchema()
        print(f"✓ Loaded configuration schema with {len(schema.sections)} sections")
        
        # Interactive configuration
        config = {}
        
        print("\nConfiguration Builder - Enter values (press Enter for defaults):")
        print("-" * 60)
        
        for section_name, fields in schema.sections.items():
            print(f"\n📋 {section_name}:")
            
            for field in fields:
                if field.field_type == "bool":
                    while True:
                        response = input(f"  {field.display_name} (y/n) [{field.default_value}]: ").strip().lower()
                        if not response:
                            config[field.name] = field.default_value
                            break
                        elif response in ['y', 'yes', 'true', '1']:
                            config[field.name] = True
                            break
                        elif response in ['n', 'no', 'false', '0']:
                            config[field.name] = False
                            break
                        else:
                            print("    Please enter y/n")
                
                elif field.field_type == "choice":
                    print(f"    Choices: {', '.join(field.choices)}")
                    while True:
                        response = input(f"  {field.display_name} [{field.default_value}]: ").strip()
                        if not response:
                            config[field.name] = field.default_value
                            break
                        elif response in field.choices:
                            config[field.name] = response
                            break
                        else:
                            print(f"    Please choose from: {', '.join(field.choices)}")
                
                else:
                    response = input(f"  {field.display_name} [{field.default_value}]: ").strip()
                    config[field.name] = response if response else field.default_value
                
                # Show help text
                print(f"    💡 {field.help_text}")
        
        # Save configuration
        config_file = work_dir / "configs" / "config_files" / "enhanced-config.json"
        config_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        
        print(f"\n✓ Configuration saved to: {config_file}")
        print(f"\nTo deploy with this configuration:")
        print(f"  python deploy.py --config {config_file}")
        
        return True
        
    except Exception as e:
        print(f"✗ Configuration builder error: {e}")
        return False

def launch_enhanced_deploy():
    """Launch enhanced deployment"""
    print("🚀 Enhanced Deployment")
    print("=" * 50)
    
    work_dir = get_working_directory()
    os.chdir(work_dir)
    
    # Ensure project files
    ensure_project_files(work_dir)
    
    # Use the enhanced deploy script
    deploy_script = Path(__file__).parent / "deploy.py"
    if not deploy_script.exists():
        print(f"✗ Deploy script not found: {deploy_script}")
        return False
    
    print(f"Working directory: {work_dir}")
    print("Available deployment options:")
    print("  1. Quick deploy (recommended defaults)")
    print("  2. Deploy with custom configuration")
    print("  3. Check prerequisites only")
    
    choice = input("\nSelect option (1-3): ").strip()
    
    try:
        if choice == "1":
            subprocess.run([sys.executable, str(deploy_script), "--quick", "--non-interactive"], 
                         cwd=str(work_dir))
        elif choice == "2":
            config_path = input("Configuration file path (or Enter for default): ").strip()
            cmd = [sys.executable, str(deploy_script), "--non-interactive"]
            if config_path:
                cmd.extend(["--config", config_path])
            subprocess.run(cmd, cwd=str(work_dir))
        elif choice == "3":
            subprocess.run([sys.executable, str(deploy_script), "--check", "--non-interactive"], 
                         cwd=str(work_dir))
        else:
            print("Invalid choice")
            return False
            
        return True
        
    except Exception as e:
        print(f"✗ Deployment error: {e}")
        return False

def ensure_project_files(work_dir: Path):
    """Ensure project files are available in working directory"""
    
    if (work_dir / "configs").exists() and (work_dir / "pwsh").exists():
        print(f"✓ Project files found in {work_dir}")
        return True
    
    print(f"📥 Setting up project files in {work_dir}...")
    
    # Copy from script location
    script_dir = Path(__file__).parent
    
    try:
        import shutil
        
        # Copy essential directories
        for dir_name in ["configs", "pwsh", "py"]:
            source_dir = script_dir / dir_name
            if source_dir.exists():
                dest_dir = work_dir / dir_name
                if dest_dir.exists():
                    shutil.rmtree(dest_dir)
                shutil.copytree(source_dir, dest_dir)
                print(f"  ✓ Copied {dir_name}/")
        
        # Copy essential files
        for file_name in ["deploy.py", "gui_enhanced.py"]:
            source_file = script_dir / file_name
            if source_file.exists():
                shutil.copy2(source_file, work_dir / file_name)
                print(f"  ✓ Copied {file_name}")
        
        print(f"✓ Project setup complete")
        return True
        
    except Exception as e:
        print(f"✗ Failed to setup project files: {e}")
        return False

def interactive_menu():
    """Display interactive menu"""
    while True:
        print("\n" + "="*50)
        print("🚀 OpenTofu Lab Automation - Enhanced Launcher")
        print("="*50)
        print("1. Launch Enhanced GUI")
        print("2. Configuration Builder (CLI)")
        print("3. Enhanced Deployment")
        print("4. Check Dependencies")
        print("5. Exit")
        print("-" * 50)
        
        choice = input("Select option (1-5): ").strip()
        
        if choice == "1":
            launch_enhanced_gui()
        elif choice == "2":
            launch_config_builder()
        elif choice == "3":
            launch_enhanced_deploy()
        elif choice == "4":
            issues = check_dependencies()
            if not issues:
                print("✓ All dependencies are available")
            else:
                print("⚠ Issues found:")
                for issue in issues:
                    print(f"  - {issue}")
        elif choice == "5":
            print("👋 Goodbye!")
            break
        else:
            print("Invalid choice. Please select 1-5.")

def main():
    """Main entry point"""
    ensure_utf8_encoding()
    
    parser = argparse.ArgumentParser(
        description="OpenTofu Lab Automation - Enhanced Launcher",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--gui', action='store_true', help='Launch enhanced GUI')
    parser.add_argument('--config-builder', action='store_true', help='Launch configuration builder')
    parser.add_argument('--deploy', action='store_true', help='Launch enhanced deployment')
    parser.add_argument('--check', action='store_true', help='Check dependencies only')
    
    args = parser.parse_args()
    
    if not any([args.gui, args.config_builder, args.deploy, args.check]):
        # No specific action requested, show interactive menu
        print_banner()
        interactive_menu()
        return
    
    print_banner()
    
    if args.check:
        issues = check_dependencies()
        if not issues:
            print("✓ All dependencies are available")
        else:
            print("⚠ Issues found:")
            for issue in issues:
                print(f"  - {issue}")
            return 1
    
    if args.gui:
        if not launch_enhanced_gui():
            return 1
    
    if args.config_builder:
        if not launch_config_builder():
            return 1
    
    if args.deploy:
        if not launch_enhanced_deploy():
            return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        sys.exit(1)
