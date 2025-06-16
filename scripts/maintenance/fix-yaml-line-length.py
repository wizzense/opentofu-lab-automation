#!/usr/bin/env python3
"""
Fix YAML line length issues while preserving syntax
"""
import os
import re
import yaml
from pathlib import Path

def fix_yaml_line_length(file_path, max_length=120):
    """Fix long lines in YAML files while preserving syntax"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = content.split('\n')
        fixed_lines = 
        
        for line in lines:
            if len(line) <= max_length:
                fixed_lines.append(line)
                continue
            
            # Handle long lines
            indent = len(line) - len(line.lstrip())
            indent_str = ' ' * indent
            
            # For run commands and other long strings
            if 'run: ' in line or 'run:' in line:
                fixed_lines.append(line)
            elif ' - ' in line and len(line) > max_length:
                # Handle long array items
                parts = line.split(' - ', 1)
                if len(parts) == 2:
                    prefix = parts0 + ' - '
                    content_part = parts1
                    if len(prefix + content_part) > max_length:
                        fixed_lines.append(prefix + '>')
                        fixed_lines.append(indent_str + '  ' + content_part)
                    else:
                        fixed_lines.append(line)
                else:
                    fixed_lines.append(line)
            elif ': ' in line and not line.strip().startswith('#'):
                # Handle long key-value pairs
                key_part, value_part = line.split(': ', 1)
                if len(line) > max_length:
                    fixed_lines.append(key_part + ': >')
                    fixed_lines.append(indent_str + '  ' + value_part)
                else:
                    fixed_lines.append(line)
            else:
                # Default: break at word boundaries
                words = line.split()
                current_line = words0 if words else ''
                
                for word in words1::
                    if len(current_line + ' ' + word) <= max_length:
                        current_line += ' ' + word
                    else:
                        fixed_lines.append(current_line)
                        current_line = indent_str + '  ' + word
                
                if current_line:
                    fixed_lines.append(current_line)
        
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(fixed_lines))
        
        print(f"Fixed line lengths in {file_path}")
        
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")

def main():
    """Fix all YAML files in .github/workflows"""
    workflow_dir = Path('.github/workflows')
    
    if not workflow_dir.exists():
        print("No .github/workflows directory found")
        return
    
    for yaml_file in workflow_dir.glob('*.yml'):
        fix_yaml_line_length(yaml_file)
    
    print("YAML line length fixes complete")

if __name__ == "__main__":
    main()
