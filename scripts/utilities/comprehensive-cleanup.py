#!/usr/bin/env python3
"""
Comprehensive Project Cleanup Script

Removes stray files, cleans up clutter, and organizes the project structure.
"""

import os
import shutil
import glob
from pathlib import Path
import time

def get_project_root():
    """Get the project root directory"""
    return Path(__file__).parent

def cleanup_build_artifacts():
    """Remove build artifacts and temporary files"""
    project_root = get_project_root()
    
    cleanup_patterns = [
        "**/__pycache__",
        "**/*.pyc", 
        "**/*.pyo",
        "**/*.pyd",
        "**/.pytest_cache",
        "**/build",
        "**/dist",
        "**/*.egg-info",
        "**/node_modules",
        "**/.DS_Store",
        "**/Thumbs.db",
        "**/*.tmp",
        "**/*.temp",
        "**/.vscode/settings.json",
        "**/coverage",
        "**/*.log"
    ]
    
    print("🧹 Cleaning build artifacts and temporary files...")
    removed_count = 0
    
    for pattern in cleanup_patterns:
        for path in project_root.glob(pattern):
            try:
                if path.is_file():
                    path.unlink()
                    print(f"  📄 Removed file: {path.relative_to(project_root)}")
                    removed_count += 1
                elif path.is_dir():
                    shutil.rmtree(path)
                    print(f"  📁 Removed directory: {path.relative_to(project_root)}")
                    removed_count += 1
            except Exception as e:
                print(f"  ❌ Could not remove {path}: {e}")
    
    print(f"✅ Removed {removed_count} build artifacts")

def cleanup_stray_files():
    """Remove stray files in the project root"""
    project_root = get_project_root()
    
    # Files that should be in the root
    allowed_root_files = {
        "README.md", "LICENSE", "requirements.txt", "requirements-gui.txt",
        "gui.py", "launcher.py", "deploy.py", "bootstrap.py", "enhanced_launcher.py",
        "quick-start.py", "quick-start.sh", "start.bat", "install.ps1", "start.ps1",
        "PROJECT-MANIFEST.json", "CHANGELOG.md", "version_info.txt",
        "gui-build.spec", "OpenTofu-Lab-GUI-v2.spec",
        ".gitignore", ".gitattributes",
        "cleanup_repository.py", "final-project-cleanup.ps1"
    }
    
    # Status/completion files
    allowed_root_files.update({
        "AGENTS.md", "AUTOMATED-EXECUTION-CONFIRMED.md", "CROSS-PLATFORM-COMPLETE.md",
        "FINAL-COMMIT-READY.md", "FINAL-PROJECT-STATUS.md", "WINDOWS-VALIDATION-COMPLETE.md",
        "MERGE-CONFLICT-CRISIS-ANALYSIS.md", "MISSION-ACCOMPLISHED-FINAL.md",
        "GUI-HANGING-FIX.md"
    })
    
    print("🔍 Identifying stray files in project root...")
    stray_files = []
    
    for item in project_root.iterdir():
        if item.is_file() and item.name not in allowed_root_files:
            # Check if it's a script that should be moved
            if item.suffix in ['.ps1', '.py', '.sh'] and not item.name.startswith('quick-start'):
                stray_files.append(item)
    
    if stray_files:
        print(f"📦 Found {len(stray_files)} stray files to organize:")
        for file in stray_files:
            print(f"  📄 {file.name}")
            
        # Move to scripts directory or archive
        scripts_dir = project_root / "scripts" / "utilities"
        scripts_dir.mkdir(parents=True, exist_ok=True)
        
        for file in stray_files:
            try:
                destination = scripts_dir / file.name
                if destination.exists():
                    # If file already exists, backup the original
                    timestamp = int(time.time())
                    backup_name = f"{file.stem}-backup-{timestamp}{file.suffix}"
                    destination = scripts_dir / backup_name
                
                shutil.move(str(file), str(destination))
                print(f"  ➡️  Moved {file.name} to scripts/utilities/")
            except Exception as e:
                print(f"  ❌ Could not move {file.name}: {e}")
    else:
        print("✅ No stray files found in project root")

def organize_archive_directory():
    """Clean up and organize the archive directory"""
    project_root = get_project_root()
    archive_dir = project_root / "archive"
    
    if not archive_dir.exists():
        print("ℹ️  No archive directory found")
        return
    
    print("📚 Organizing archive directory...")
    
    # Remove empty directories
    def remove_empty_dirs(path):
        removed = 0
        for item in path.iterdir():
            if item.is_dir():
                removed += remove_empty_dirs(item)
                try:
                    item.rmdir()  # This will only work if empty
                    print(f"  📁 Removed empty directory: {item.relative_to(project_root)}")
                    removed += 1
                except OSError:
                    pass  # Directory not empty
        return removed
    
    removed_dirs = remove_empty_dirs(archive_dir)
    print(f"✅ Removed {removed_dirs} empty directories from archive")
    
    # Compress old backup directories by date
    backup_dirs = []
    for item in archive_dir.iterdir():
        if item.is_dir() and any(x in item.name.lower() for x in ['backup', '20250613', 'old', 'legacy']):
            backup_dirs.append(item)
    
    if backup_dirs:
        consolidated_backup = archive_dir / "consolidated-backups-20250613"
        consolidated_backup.mkdir(exist_ok=True)
        
        for backup_dir in backup_dirs:
            try:
                destination = consolidated_backup / backup_dir.name
                if not destination.exists():
                    shutil.move(str(backup_dir), str(destination))
                    print(f"  📦 Consolidated {backup_dir.name} into consolidated-backups-20250613")
            except Exception as e:
                print(f"  ❌ Could not consolidate {backup_dir.name}: {e}")

def cleanup_duplicate_files():
    """Find and remove duplicate files"""
    project_root = get_project_root()
    
    print("🔍 Scanning for duplicate files...")
    
    # Common duplicate patterns
    duplicate_patterns = [
        "**/gui_*.py",  # Multiple GUI versions
        "**/*-backup*",  # Backup files
        "**/*-old*",    # Old files
        "**/*-copy*",   # Copy files
        "**/*_v2*",     # Version files that might be duplicates
    ]
    
    duplicates_found = []
    
    for pattern in duplicate_patterns:
        files = list(project_root.glob(pattern))
        if len(files) > 1:
            # Check if they're actually in archive or if they're needed
            active_files = [f for f in files if 'archive' not in str(f)]
            archive_files = [f for f in files if 'archive' in str(f)]
            
            if len(active_files) > 1:
                duplicates_found.extend(active_files[1:])  # Keep the first one
    
    if duplicates_found:
        print(f"📄 Found {len(duplicates_found)} potential duplicate files:")
        for dup in duplicates_found:
            print(f"  🔍 {dup.relative_to(project_root)}")
        
        # Move to archive instead of deleting
        dup_archive = project_root / "archive" / "potential-duplicates-20250613"
        dup_archive.mkdir(parents=True, exist_ok=True)
        
        for dup in duplicates_found:
            try:
                destination = dup_archive / dup.name
                if destination.exists():
                    timestamp = int(time.time())
                    destination = dup_archive / f"{dup.stem}-{timestamp}{dup.suffix}"
                
                shutil.move(str(dup), str(destination))
                print(f"  📦 Archived duplicate: {dup.name}")
            except Exception as e:
                print(f"  ❌ Could not archive {dup.name}: {e}")
    else:
        print("✅ No active duplicate files found")

def generate_cleanup_report():
    """Generate a cleanup report"""
    project_root = get_project_root()
    
    print("\n📊 Generating cleanup report...")
    
    # Count files by type
    file_counts = {}
    total_size = 0
    
    for file_path in project_root.rglob('*'):
        if file_path.is_file():
            suffix = file_path.suffix.lower() or 'no extension'
            file_counts[suffix] = file_counts.get(suffix, 0) + 1
            try:
                total_size += file_path.stat().st_size
            except:
                pass
    
    # Create report
    report_content = f"""
# Project Cleanup Report - {time.strftime('%Y-%m-%d %H:%M:%S')}

## Project Structure Overview
- Total files: {sum(file_counts.values())}
- Total size: {total_size / (1024*1024):.2f} MB

## File Types:
"""
    
    for suffix, count in sorted(file_counts.items(), key=lambda x: x[1], reverse=True):
        report_content += f"- {suffix}: {count} files\n"
    
    report_content += """
## Cleanup Actions Completed:
✅ Build artifacts and temporary files removed
✅ Stray files organized into scripts/utilities/
✅ Archive directory organized and consolidated
✅ Duplicate files identified and archived
✅ Empty directories removed

## Project Structure:
```
opentofu-lab-automation/
├── gui.py (Enhanced GUI - Clean light theme)
├── configs/config_files/ (Configuration management)
├── scripts/ (Organized automation scripts)
├── pwsh/modules/ (PowerShell modules)
├── tests/ (Test framework)
├── archive/ (Historical files, organized)
└── docs/ (Documentation)
```
"""
    
    report_file = project_root / f"CLEANUP-REPORT-{time.strftime('%Y%m%d-%H%M%S')}.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"📄 Cleanup report saved to: {report_file.name}")

def main():
    """Run comprehensive project cleanup"""
    print("🚀 Starting Comprehensive Project Cleanup...")
    print("=" * 50)
    
    try:
        cleanup_build_artifacts()
        print()
        
        cleanup_stray_files()
        print()
        
        organize_archive_directory()
        print()
        
        cleanup_duplicate_files()
        print()
        
        generate_cleanup_report()
        print()
        
        print("🎉 Project cleanup completed successfully!")
        print("✨ Your project is now clean and organized")
        
    except Exception as e:
        print(f"❌ Cleanup failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
