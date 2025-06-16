#!/usr/bin/env python3
"""
Test the specific kicker-bootstrap.ps1 file for the syntax issue we fixed.
"""

import re

def check_bootstrap_syntax():
    file_path = '/workspaces/opentofu-lab-automation/pwsh/kicker-bootstrap.ps1'
    
    print(f"Checking: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Look for the specific issue we fixed: $repoPath: in strings
    problematic_patterns = [
        r'"\s*[^"]*\$repoPath:[^"]*"',  # $repoPath: in double quotes
        r"'\s*[^']*\$repoPath:[^']*'",  # $repoPath: in single quotes
    ]
    
    issues_found = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines, 1):
        for pattern in problematic_patterns:
            if re.search(pattern, line):
                issues_found.append((i, line.strip()))
    
    if issues_found:
        print("ERROR: Found problematic variable interpolation patterns:")
        for line_num, line_content in issues_found:
            print(f"  Line {line_num}: {line_content}")
        return False
    
    # Check that we have proper escaping where needed
    escaped_patterns = [
        r'\$\{repoPath\}',  # Should find ${repoPath}
    ]
    
    found_escaping = False
    for pattern in escaped_patterns:
        if re.search(pattern, content):
            found_escaping = True
            break
    
    if found_escaping:
        print(" Found proper variable escaping with ${}")
    
    print(" Bootstrap script syntax looks good!")
    return True

if __name__ == '__main__':
    success = check_bootstrap_syntax()
    exit(0 if success else 1)
