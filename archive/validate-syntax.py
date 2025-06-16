#!/usr/bin/env python3
"""
Basic PowerShell syntax validation script.
Checks for common syntax issues that would cause parsing errors.
"""

import os
import re
import sys
from pathlib import Path

def validate_powershell_file(file_path):
    """Validate a PowerShell file for common syntax issues."""
    print(f"Validating: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for specific unescaped variable interpolation issues
    # Look for variables followed by colon in string contexts, but exclude valid scope qualifiers
    lines = content.split('\n')
    for i, line in enumerate(lines, 1):
        # Skip comments and here-strings
        if line.strip().startswith('#') or '@"' in line or '"@' in line:
            continue
            
        # Look for problematic patterns like "$variableName:" in strings
        # but exclude valid scope qualifiers like $env:, $script:, $global:, etc.
        if re.search(r'\$a-zA-Z_a-zA-Z0-9_*:', line):
            # Check if it's not a valid scope qualifier
            if not re.search(r'\$(envscriptgloballocalprivateusingworkflow):', line, re.IGNORECASE):
                # Check if it's in a string context that could cause parsing issues
                if '"' in line and re.search(r'"\s*^"*\$a-zA-Z_a-zA-Z0-9_*:^"*"', line):
                    print(f"ERROR: Line {i} has potentially problematic variable interpolation: {line.strip()}")
                    return False
    
    # Check for basic PowerShell syntax patterns
    common_issues = 
        (r'@\s*"^"*\n^"*"@\s*-\w+', 'Here-string followed by parameter without proper separation'),
    
    
    for pattern, description in common_issues:
        if re.search(pattern, content, re.MULTILINE):
            print(f"WARNING: Potential syntax issue - {description}")
    
    print(f" {file_path} passed basic syntax validation")
    return True

def main():
    """Main validation function."""
    script_dir = Path(__file__).parent
    pwsh_dir = script_dir / 'pwsh'
    
    if not pwsh_dir.exists():
        print(f"ERROR: PowerShell directory not found: {pwsh_dir}")
        return 1
    
    # Find all PowerShell files
    ps_files = list(pwsh_dir.glob('**/*.ps1'))
    
    if not ps_files:
        print("No PowerShell files found")
        return 0
    
    all_valid = True
    
    for ps_file in ps_files:
        if not validate_powershell_file(ps_file):
            all_valid = False
    
    if all_valid:
        print(f"\n All {len(ps_files)} PowerShell files passed basic syntax validation")
        return 0
    else:
        print(f"\n Some PowerShell files failed validation")
        return 1

if __name__ == '__main__':
    sys.exit(main())
