#!/usr/bin/env python3
"""
Emergency Python Indentation Fixer for OpenTofu Lab Automation

Fixes systematic indentation errors that have broken the entire Python codebase.
"""
import os
import re
import sys
from pathlib import Path
from typing import List, Set


def fix_indentation_errors(file_path: Path) -> bool:
    """Fix common indentation errors in a Python file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        lines = content.split('\n')
        fixed_lines = []
        
        i = 0
        while i < len(lines):
            line = lines[i]
            
            # Fix common patterns where indentation is wrong
            if re.match(r'^ [^#\s]', line):  # Single space instead of proper indentation
                # Check if this should be indented (after try:, if:, def:, class:, etc.)
                if i > 0:
                    prev_line = lines[i-1].strip()
                    if (prev_line.endswith(':') and 
                        any(prev_line.startswith(kw) for kw in ['try', 'if', 'def', 'class', 'for', 'while', 'with', 'elif', 'else', 'except', 'finally'])):
                        # This should be indented with 4 spaces
                        fixed_lines.append('    ' + line.lstrip())
                    elif prev_line.endswith(':'):
                        # Inside a block, should be indented
                        fixed_lines.append('    ' + line.lstrip())
                    else:
                        fixed_lines.append(line)
                else:
                    fixed_lines.append(line)
            else:
                fixed_lines.append(line)
            
            i += 1
        
        fixed_content = '\n'.join(fixed_lines)
        
        # Try to compile to check if syntax is valid
        try:
            compile(fixed_content, str(file_path), 'exec')
            if fixed_content != original_content:
                # Create backup
                backup_path = file_path.with_suffix('.py.backup-indentation')
                with open(backup_path, 'w', encoding='utf-8') as f:
                    f.write(original_content)
                
                # Write fixed content
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                
                print(f"✅ Fixed indentation: {file_path}")
                return True
            else:
                print(f"✓ No indentation issues: {file_path}")
                return False
        except SyntaxError as e:
            print(f"❌ Still has syntax errors after fix: {file_path}")
            print(f"   Error: {e}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False


def main():
    """Main function to fix Python indentation issues."""
    print("=== Emergency Python Indentation Fixer ===")
    
    # Find all Python files
    python_files = []
    for root, dirs, files in os.walk('.'):
        # Skip certain directories
        if any(skip in root for skip in ['.git', '__pycache__', '.pytest_cache', 'venv', 'env']):
            continue
            
        for file in files:
            if file.endswith('.py'):
                python_files.append(Path(root) / file)
    
    print(f"Found {len(python_files)} Python files to check")
    
    fixed_count = 0
    for file_path in python_files:
        if fix_indentation_errors(file_path):
            fixed_count += 1
    
    print(f"\n=== Summary ===")
    print(f"Files processed: {len(python_files)}")
    print(f"Files fixed: {fixed_count}")
    
    if fixed_count > 0:
        print(f"\n✅ Fixed {fixed_count} files with indentation issues")
        print("Backup files created with .backup-indentation extension")
    else:
        print("\n✓ No indentation issues found")


if __name__ == '__main__':
    main()
