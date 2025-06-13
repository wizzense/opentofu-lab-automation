#!/usr/bin/env python3
"""
GUI Launcher for OpenTofu Lab Automation

Simple launcher script that checks for dependencies and launches the GUI.
"""

import sys
import subprocess
import os
from pathlib import Path

def check_dependencies():
    """Check if required dependencies are available"""
    try:
        import tkinter
        return True
    except ImportError:
        print("❌ tkinter is not available!")
        print("\nInstallation instructions:")
        print("  • Ubuntu/Debian: sudo apt-get install python3-tk")
        print("  • CentOS/RHEL: sudo yum install tkinter")
        print("  • macOS: tkinter included with Python")
        print("  • Windows: tkinter included with Python")
        return False

def main():
    if not check_dependencies():
        input("\nPress Enter to exit...")
        return 1
    
    # Get script directory
    script_dir = Path(__file__).parent
    gui_script = script_dir / "gui.py"
    
    if not gui_script.exists():
        print(f"❌ GUI script not found: {gui_script}")
        input("Press Enter to exit...")
        return 1
    
    try:
        # Launch GUI
        subprocess.run([sys.executable, str(gui_script)])
        return 0
    except Exception as e:
        print(f"❌ Failed to launch GUI: {e}")
        input("Press Enter to exit...")
        return 1

if __name__ == "__main__":
    sys.exit(main())
