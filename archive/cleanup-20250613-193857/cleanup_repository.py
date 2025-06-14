#!/usr/bin/env python3
"""
OpenTofu Lab Automation - Cleanup Script

This script cleans up old and redundant files in the repository while preserving
the enhanced versions and critical project files.
"""

import os
import sys
import shutil
from pathlib import Path
import json
import time
import datetime

# Files to keep (core files and enhanced versions)
KEEP_FILES = [
    # Enhanced versions
    "enhanced_launcher.py",
    "gui_enhanced.py",
    "py/config_schema.py",
    "py/config_schema_simple.py",
    "py/enhanced_powershell_executor.py",
    "pwsh/CrossPlatformExecutor_Enhanced.ps1",
    
    # Core project files
    "README.md",
    "LICENSE",
    "PROJECT-MANIFEST.json",
    "CHANGELOG.md",
    "deploy.py",
    "launcher.py",
    "quick-start.py",
    "quick-start.sh",
    "quick-download.sh",
    "build_executables.py",
    
    # Core directories (will check separately)
    "configs/",
    "pwsh/",
    "py/",
    "scripts/",
    "docs/",
    "tests/",
    ".github/",
]

# Files to specifically remove (known redundant files)
REMOVE_FILES = [
    # Old launchers and duplicates
    "deploy.bat",
    "deploy.sh",
    "gui.py",
    "launch-gui.bat",
    "launch-gui.ps1",
    "launch-gui.py",
    "launch-gui.sh",
    
    # Old test scripts
    "test-powershell-quickstart.ps1",
    "fix-all-syntax-errors.ps1",
    "fix-here-strings-v2.ps1",
    "fix-here-strings.ps1",
    "fix-import-issues.ps1",
    "simple-import-cleanup.ps1",
    "windows-quick-test.ps1",
    "cleanup-root-fixes.ps1",
    "auto-fix.ps1",
    
    # Old summary reports (they should be in docs/reports)
    "AUTO-FIX-INTEGRATION-SUMMARY.md",
    "BRANCH-SOLUTION-SUMMARY.md",
    "CLEANUP-SUMMARY.md",
    "CODEFIXER-IMPROVEMENTS-SUMMARY.md",
    "DEPLOYMENT-WRAPPER-SUMMARY.md",
    "INTEGRATION-SUMMARY.md",
    "INLINE-WINDOWS-TEST.md",
    "MISSION-ACCOMPLISHED-FINAL.md",
    "MISSION-ACCOMPLISHED-INTEGRATION.md",
    "PROJECT-ORGANIZATION-COMPLETE.md",
    "TEST-ISSUES-SUMMARY-REPORT.md",
    "TESTING-DEPLOYMENT-WRAPPER.md",
    "TESTING.md",
    "WINDOWS-TESTING-GUIDE.md",
    "WORKFLOW-CONSOLIDATION-SUMMARY.md"
]

def should_keep_file(file_path):
    """Check if a file should be kept or archived"""
    rel_path = file_path.relative_to(Path.cwd())
    str_path = str(rel_path)
    
    # Keep files matching the keep list
    for keep_pattern in KEEP_FILES:
        if str_path == keep_pattern or str_path.startswith(keep_pattern):
            return True
    
    # Always keep .git directory
    if ".git" in str_path.split(os.sep):
        return True
        
    # Remove files in the remove list
    for remove_pattern in REMOVE_FILES:
        if str_path == remove_pattern:
            return False
    
    # Special handling for README variants
    if str_path in ["README-old.md", "README-new.md", "README-backup.md"]:
        return False
        
    # For other files, consider based on extension and location
    if file_path.suffix in ['.md', '.ps1', '.py', '.bat', '.sh'] and file_path.parent == Path.cwd():
        # Non-essential scripts in the root directory
        return False
        
    # By default, keep other files
    return True

def create_archive_directory():
    """Create an archive directory for backup"""
    timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    archive_dir = Path("archive") / f"cleanup-{timestamp}"
    archive_dir.mkdir(parents=True, exist_ok=True)
    return archive_dir

def cleanup_files():
    """Clean up redundant files"""
    archive_dir = create_archive_directory()
    print(f"Archive directory: {archive_dir}")
    
    files_archived = 0
    files_kept = 0
    
    for path in sorted(Path.cwd().rglob("*")):
        if path.is_file():
            if should_keep_file(path):
                files_kept += 1
            else:
                # Archive the file
                rel_path = path.relative_to(Path.cwd())
                archive_path = archive_dir / rel_path
                archive_path.parent.mkdir(parents=True, exist_ok=True)
                
                print(f"Archiving: {rel_path}")
                try:
                    shutil.copy2(path, archive_path)
                    path.unlink()
                    files_archived += 1
                except Exception as e:
                    print(f"Error archiving {rel_path}: {e}")
    
    print(f"\nSummary:")
    print(f"- Files kept: {files_kept}")
    print(f"- Files archived: {files_archived}")
    print(f"- Archive location: {archive_dir}")
    
    # Create summary file
    with open(archive_dir / "cleanup-summary.json", "w") as f:
        json.dump({
            "timestamp": datetime.datetime.now().isoformat(),
            "files_kept": files_kept,
            "files_archived": files_archived,
            "archived_files": [str(p.relative_to(archive_dir)) for p in archive_dir.rglob("*") if p.is_file() and "cleanup-summary.json" not in str(p)]
        }, f, indent=2)
    
    return files_archived

def main():
    """Main cleanup process"""
    print("=" * 60)
    print("OpenTofu Lab Automation - Cleanup Process")
    print("=" * 60)
    print("This will archive redundant files and clean up the repository.")
    print("Original files will be preserved in the archive directory.")
    
    if input("Continue? (y/n): ").lower() not in ["y", "yes"]:
        print("Cleanup cancelled.")
        return 0
    
    start_time = time.time()
    files_archived = cleanup_files()
    elapsed = time.time() - start_time
    
    print("\n" + "=" * 60)
    print(f"Cleanup completed in {elapsed:.2f} seconds")
    print(f"Archived {files_archived} redundant files")
    print("=" * 60)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
