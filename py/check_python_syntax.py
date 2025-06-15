#!/usr/bin/env python3
"""
Simple Python syntax validation for indentation errors.
"""

import ast
import sys
from pathlib import Path
from typing import List


def check_python_syntax(file_path: Path) -> bool:
    """Check if a Python file has valid syntax."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        ast.parse(content, filename=str(file_path))
        return True
    except SyntaxError as e:
        print(f"SYNTAX ERROR in {file_path}: Line {e.lineno}: {e.msg}")
        return False
    except Exception as e:
        print(f"ERROR reading {file_path}: {e}")
        return False


def check_indentation(file_path: Path) -> bool:
    """Check if a Python file has consistent indentation."""
    issues = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for line_num, line in enumerate(lines, 1):
            if line.strip() == "":
                continue
            
            if '\t' in line:
                issues.append(f"Line {line_num}: Contains tabs")
            
            leading_spaces = len(line) - len(line.lstrip(' '))
            if leading_spaces > 0 and leading_spaces % 4 != 0:
                issues.append(f"Line {line_num}: Indentation not multiple of 4 ({leading_spaces} spaces)")
        
        if issues:
            print(f"INDENTATION ISSUES in {file_path}:")
            for issue in issues:
                print(f"  {issue}")
            return False
        return True
        
    except Exception as e:
        print(f"ERROR checking indentation in {file_path}: {e}")
        return False


def main():
    """Main function to check all Python files."""
    project_root = Path(__file__).resolve().parents[1]
    py_dir = project_root / "py"
    
    if not py_dir.exists():
        print("No py/ directory found")
        return
    
    python_files = list(py_dir.rglob("*.py"))
    print(f"Checking {len(python_files)} Python files...")
    
    syntax_errors = 0
    indentation_errors = 0
    
    for file_path in python_files:
        if "__pycache__" in str(file_path):
            continue
            
        print(f"\nChecking {file_path}...")
        
        if not check_python_syntax(file_path):
            syntax_errors += 1
            
        if not check_indentation(file_path):
            indentation_errors += 1
    
    print(f"\n=== SUMMARY ===")
    print(f"Files checked: {len(python_files)}")
    print(f"Syntax errors: {syntax_errors}")
    print(f"Indentation errors: {indentation_errors}")
    
    if syntax_errors > 0 or indentation_errors > 0:
        print(f"\n❌ Found {syntax_errors + indentation_errors} issues total")
        return 1
    else:
        print(f"\n✅ All Python files are valid!")
        return 0


if __name__ == "__main__":
    sys.exit(main())
