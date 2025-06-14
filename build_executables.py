#!/usr/bin/env python3
"""
Build Script: Creates standalone executables for OpenTofu Lab Automation tools

This script creates standalone executables for:
- enhanced_launcher.py
- gui_enhanced.py

Requirements:
- PyInstaller: pip install pyinstaller
"""

import os
import sys
import shutil
import subprocess
import platform
from pathlib import Path

def ensure_pyinstaller():
    """Ensure PyInstaller is installed"""
    try:
        import PyInstaller
        print("✓ PyInstaller already installed")
        return True
    except ImportError:
        print("Installing PyInstaller...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "pyinstaller"], check=True)
            print("✓ PyInstaller installed successfully")
            return True
        except Exception as e:
            print(f"✗ Failed to install PyInstaller: {e}")
            return False

def build_executable(script_path, name=None, onefile=True, console=True, icon=None):
    """Build executable using PyInstaller"""
    script_path = Path(script_path)
    if not script_path.exists():
        print(f"✗ Source script not found: {script_path}")
        return False
    
    print(f"Building executable for: {script_path}")
    
    # Prepare command
    cmd = [sys.executable, "-m", "PyInstaller"]
    
    # Add options
    if onefile:
        cmd.append("--onefile")
    else:
        cmd.append("--onedir")
        
    if not console:
        cmd.append("--noconsole")
        
    if name:
        cmd.extend(["--name", name])
    
    if icon and Path(icon).exists():
        cmd.extend(["--icon", icon])
    
    # Add paths
    cmd.extend([
        "--workpath", "build",
        "--distpath", "dist",
        "--specpath", "build",
        str(script_path)
    ])
    
    # Execute PyInstaller
    try:
        print(f"Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)
        
        # Verify output
        exe_ext = ".exe" if platform.system() == "Windows" else ""
        output_name = name or script_path.stem
        output_path = Path("dist") / f"{output_name}{exe_ext}"
        
        if output_path.exists():
            print(f"✓ Successfully built: {output_path}")
            return True
        else:
            print(f"✗ Build failed, executable not found: {output_path}")
            return False
            
    except Exception as e:
        print(f"✗ Build error: {e}")
        return False

def copy_required_files(dist_dir="dist"):
    """Copy necessary supporting files to dist directory"""
    dist_path = Path(dist_dir)
    if not dist_path.exists():
        print(f"✗ Distribution directory not found: {dist_path}")
        return False
    
    print("Copying supporting files...")
    
    # Ensure directories
    config_dir = dist_path / "configs" / "config_files"
    config_dir.mkdir(parents=True, exist_ok=True)
    
    pwsh_dir = dist_path / "pwsh"
    pwsh_dir.mkdir(parents=True, exist_ok=True)
    
    py_dir = dist_path / "py"
    py_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy configuration schema
    try:
        # Copy Python modules
        for py_file in ["config_schema.py", "config_schema_simple.py", "enhanced_powershell_executor.py"]:
            src = Path("py") / py_file
            if src.exists():
                shutil.copy2(src, py_dir / py_file)
                print(f"  ✓ Copied {py_file}")
        
        # Copy PowerShell scripts
        for ps_file in ["CrossPlatformExecutor.ps1", "CrossPlatformExecutor_Enhanced.ps1"]:
            src = Path("pwsh") / ps_file
            if src.exists():
                shutil.copy2(src, pwsh_dir / ps_file)
                print(f"  ✓ Copied {ps_file}")
        
        # Copy default config
        default_config = Path("configs") / "config_files" / "default-config.json"
        if default_config.exists():
            shutil.copy2(default_config, config_dir / "default-config.json")
            print(f"  ✓ Copied default-config.json")
            
        # Copy README for documentation
        readme = Path("README.md")
        if readme.exists():
            shutil.copy2(readme, dist_path / "README.md")
            print(f"  ✓ Copied README.md")
            
        print("✓ Successfully copied supporting files")
        return True
            
    except Exception as e:
        print(f"✗ Error copying files: {e}")
        return False

def create_startup_batch(dist_dir="dist"):
    """Create Windows batch file for easy startup"""
    if platform.system() != "Windows":
        return True
        
    dist_path = Path(dist_dir)
    
    try:
        # Create launcher.bat
        with open(dist_path / "launcher.bat", "w") as f:
            f.write('@echo off\n')
            f.write('echo Starting OpenTofu Lab Automation...\n')
            f.write('enhanced_launcher.exe\n')
        print("✓ Created launcher.bat")
        
        # Create README.txt with instructions
        with open(dist_path / "README.txt", "w") as f:
            f.write("OpenTofu Lab Automation\n")
            f.write("=======================\n\n")
            f.write("Quick Start:\n")
            f.write("1. Double-click launcher.bat or enhanced_launcher.exe\n")
            f.write("2. For GUI interface, double-click gui_enhanced.exe\n\n")
            f.write("See README.md for full documentation.\n")
            
        print("✓ Created README.txt")
        return True
        
    except Exception as e:
        print(f"✗ Error creating startup files: {e}")
        return False

def create_zip_archive(dist_dir="dist"):
    """Create ZIP archive of distribution"""
    dist_path = Path(dist_dir)
    if not dist_path.exists():
        print(f"✗ Distribution directory not found: {dist_path}")
        return False
        
    try:
        import zipfile
        
        # Create ZIP archive
        zip_path = Path(f"OpenTofuLabAutomation-{platform.system().lower()}.zip")
        
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, _, files in os.walk(dist_path):
                for file in files:
                    file_path = Path(root) / file
                    zipf.write(file_path, file_path.relative_to(dist_path))
        
        print(f"✓ Created distribution archive: {zip_path}")
        return True
        
    except Exception as e:
        print(f"✗ Error creating ZIP archive: {e}")
        return False

def main():
    """Main build process"""
    print("=" * 60)
    print("Building OpenTofu Lab Automation Executables")
    print("=" * 60)
    
    # Ensure PyInstaller is available
    if not ensure_pyinstaller():
        return 1
    
    # Clean previous builds
    for path in ["build", "dist"]:
        if Path(path).exists():
            print(f"Cleaning {path}...")
            try:
                shutil.rmtree(path)
            except Exception as e:
                print(f"Warning: Could not clean {path}: {e}")
    
    # Build enhanced_launcher executable
    if not build_executable("enhanced_launcher.py", "enhanced_launcher", 
                         onefile=True, console=True):
        return 1
    
    # Build gui_enhanced executable
    if not build_executable("gui_enhanced.py", "gui_enhanced", 
                         onefile=True, console=False):
        return 1
    
    # Copy supporting files
    if not copy_required_files():
        return 1
    
    # Create startup files
    create_startup_batch()
    
    # Create distribution archive
    create_zip_archive()
    
    print("\n" + "=" * 60)
    print("Build process completed successfully!")
    print("=" * 60)
    print(f"Executables and files available in: {Path('dist').absolute()}")
    print(f"ZIP archive: OpenTofuLabAutomation-{platform.system().lower()}.zip")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
