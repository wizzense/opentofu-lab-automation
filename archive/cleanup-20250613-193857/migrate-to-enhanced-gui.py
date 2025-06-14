#!/usr/bin/env python3
"""
Migration script to switch to enhanced GUI
This script backs up the old GUI and promotes gui_enhanced.py to be the default GUI
"""

import shutil
from pathlib import Path
import sys

def main():
    """Migrate to enhanced GUI"""
    project_root = Path(__file__).parent
    
    gui_old = project_root / "gui.py"
    gui_enhanced = project_root / "gui_enhanced.py"
    gui_backup = project_root / "gui_legacy_backup.py"
    
    print("🔄 Migrating to Enhanced GUI...")
    
    # Check if enhanced GUI exists
    if not gui_enhanced.exists():
        print("❌ Enhanced GUI not found!")
        return 1
    
    # Backup old GUI if it exists
    if gui_old.exists():
        print(f"📦 Backing up old GUI to {gui_backup}")
        shutil.copy2(gui_old, gui_backup)
        gui_old.unlink()
    
    # Copy enhanced GUI to be the default
    print(f"✅ Promoting enhanced GUI to default GUI")
    shutil.copy2(gui_enhanced, gui_old)
    
    print("🎉 Migration completed!")
    print("   - Old GUI backed up as gui_legacy_backup.py")
    print("   - Enhanced GUI is now the default gui.py")
    print("   - Original enhanced GUI remains as gui_enhanced.py")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
