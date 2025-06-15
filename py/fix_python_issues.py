#!/usr/bin/env python3
"""
Python Code Quality Auto-Fixer for OpenTofu Lab Automation

This script automatically fixes common Python issues including:
- Indentation errors (tabs to spaces, inconsistent indentation)
- Import statement organization
- Unused imports removal
- Basic PEP 8 compliance
- Debug code removal
"""

import ast
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Set, Tuple

import click


class PythonAutoFixer:
    """Automatic Python code quality fixer."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.fixed_files: List[Path] = []
        self.errors_found: List[str] = []
        
    def find_python_files(self) -> List[Path]:
        """Find all Python files in the project."""
        python_files = []
        
        for pattern in ["py/**/*.py", "scripts/**/*.py", "tools/**/*.py"]:
            python_files.extend(self.project_root.glob(pattern))
        
        # Filter out __pycache__ and other generated files
        return [f for f in python_files 
                if "__pycache__" not in str(f) and ".pytest_cache" not in str(f)]
    
    def fix_indentation(self, file_path: Path) -> bool:
        """Fix indentation issues in a Python file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Convert tabs to 4 spaces
            content = content.expandtabs(4)
            
            # Fix inconsistent indentation by re-parsing with AST
            try:
                tree = ast.parse(content)
                # If AST parsing succeeds, the indentation is probably correct now
            except IndentationError as e:
                # Try to fix common indentation patterns
                lines = content.split('\n')
                fixed_lines = []
                
                for line_num, line in enumerate(lines):
                    # Skip empty lines
                    if not line.strip():
                        fixed_lines.append(line)
                        continue
                    
                    # Get leading whitespace
                    leading_spaces = len(line) - len(line.lstrip())
                    
                    # If indentation is not a multiple of 4, try to fix it
                    if leading_spaces > 0 and leading_spaces % 4 != 0:
                        # Round to nearest multiple of 4
                        new_indent = ((leading_spaces + 2) // 4) * 4
                        fixed_line = ' ' * new_indent + line.lstrip()
                        fixed_lines.append(fixed_line)
                    else:
                        fixed_lines.append(line)
                
                content = '\n'.join(fixed_lines)
            
            # Only write if content changed
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.fixed_files.append(file_path)
                return True
                
        except Exception as e:
            self.errors_found.append(f"Failed to fix indentation in {file_path}: {e}")
            return False
        
        return False
    
    def remove_unused_imports(self, file_path: Path) -> bool:
        """Remove unused import statements."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            try:
                tree = ast.parse(content)
            except SyntaxError:
                # Skip files with syntax errors
                return False
            
            # Collect all imported names
            imported_names = set()
            import_nodes = []
            
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    import_nodes.append(node)
                    for alias in node.names:
                        name = alias.asname if alias.asname else alias.name
                        imported_names.add(name)
                elif isinstance(node, ast.ImportFrom):
                    import_nodes.append(node)
                    if node.names:
                        for alias in node.names:
                            if alias.name != '*':
                                name = alias.asname if alias.asname else alias.name
                                imported_names.add(name)
            
            # Find used names (simplified analysis)
            used_names = set()
            for node in ast.walk(tree):
                if isinstance(node, ast.Name) and not isinstance(node.ctx, ast.Store):
                    used_names.add(node.id)
                elif isinstance(node, ast.Attribute):
                    # For module.function calls
                    if isinstance(node.value, ast.Name):
                        used_names.add(node.value.id)
            
            # Identify unused imports (conservative approach)
            unused_imports = imported_names - used_names
            
            # Remove obvious unused imports (be conservative)
            lines = content.split('\n')
            new_lines = []
            
            for line_num, line in enumerate(lines):
                line_stripped = line.strip()
                
                # Check if this is an import line with unused imports
                is_unused_import = False                if (line_stripped.startswith('import ') or 
                    line_stripped.startswith('from ')) and not line_stripped.startswith('#'):
                    
                    # Very conservative: only remove imports that are clearly unused
                    # and don't appear in strings or comments
                    for unused in unused_imports:
                        if (f"import {unused}" in line_stripped or 
                            f"from {unused}" in line_stripped):
                            # Check if it appears elsewhere in the file (very conservative)
                            if unused not in content.replace(line, ''):
                                is_unused_import = True
                                break
                
                if not is_unused_import:
                    new_lines.append(line)
            
            new_content = '\n'.join(new_lines)
            
            if new_content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                return True
                
        except Exception as e:
            self.errors_found.append(f"Failed to remove unused imports in {file_path}: {e}")
            return False
        
        return False
    
    def remove_debug_code(self, file_path: Path) -> bool:
        """Remove debug print statements and similar debug code."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            lines = content.split('\n')
            new_lines = []
            
            for line in lines:
                line_stripped = line.strip()
                
                # Skip debug print statements (be conservative)
                if (line_stripped.startswith('print(') and 
                    ('debug' in line_stripped.lower() or 
                     'DEBUG' in line_stripped or
                     'test' in line_stripped.lower())):
                    # Comment out instead of removing completely
                    new_lines.append('# ' + line if not line.startswith('#') else line)
                    continue
                
                # Remove pdb imports and calls
                if any(debug_pattern in line_stripped for debug_pattern in [
                    'import pdb', 'from pdb', 'pdb.set_trace()', 
                    'import ipdb', 'ipdb.set_trace()'
                ]):
                    new_lines.append('# ' + line if not line.startswith('#') else line)
                    continue
                
                new_lines.append(line)
            
            new_content = '\n'.join(new_lines)
            
            if new_content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                return True
                
        except Exception as e:
            self.errors_found.append(f"Failed to remove debug code in {file_path}: {e}")
            return False
        
        return False
    
    def fix_import_order(self, file_path: Path) -> bool:
        """Fix import statement ordering according to PEP 8."""
        try:
            # Use isort if available
            result = subprocess.run([
                sys.executable, '-m', 'isort', 
                '--profile=black',
                '--line-length=88',
                str(file_path)
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                return True
                
        except FileNotFoundError:
            # isort not available, do basic sorting
            pass
        except Exception as e:
            self.errors_found.append(f"Failed to fix import order in {file_path}: {e}")
        
        return False
    
    def run_black_formatter(self, file_path: Path) -> bool:
        """Run black formatter on the file."""
        try:
            result = subprocess.run([
                sys.executable, '-m', 'black',
                '--line-length=88',
                '--target-version=py38',
                str(file_path)
            ], capture_output=True, text=True)
            
            return result.returncode == 0
            
        except FileNotFoundError:
            # black not available
            return False
        except Exception as e:
            self.errors_found.append(f"Failed to run black formatter on {file_path}: {e}")
            return False
    
    def fix_file(self, file_path: Path, 
                 fix_indentation: bool = True,
                 remove_unused: bool = True,
                 remove_debug: bool = True,
                 format_code: bool = True) -> bool:
        """Fix all issues in a single file."""
        fixed = False
        
        click.echo(f"Fixing {file_path}...")
        
        if fix_indentation:
            if self.fix_indentation(file_path):
                click.echo(f"  ✓ Fixed indentation")
                fixed = True
        
        if remove_debug:
            if self.remove_debug_code(file_path):
                click.echo(f"  ✓ Removed debug code")
                fixed = True
        
        if remove_unused:
            if self.remove_unused_imports(file_path):
                click.echo(f"  ✓ Removed unused imports")
                fixed = True
        
        if format_code:
            if self.fix_import_order(file_path):
                click.echo(f"  ✓ Fixed import order")
                fixed = True
            
            if self.run_black_formatter(file_path):
                click.echo(f"  ✓ Applied code formatting")
                fixed = True
        
        return fixed
    
    def fix_all_files(self, **kwargs) -> Tuple[int, int]:
        """Fix all Python files in the project."""
        python_files = self.find_python_files()
        fixed_count = 0
        
        click.echo(f"Found {len(python_files)} Python files to check")
        
        for file_path in python_files:
            if self.fix_file(file_path, **kwargs):
                fixed_count += 1
        
        return fixed_count, len(python_files)


@click.command()
@click.option('--project-root', '-p', 
              type=click.Path(exists=True, path_type=Path),
              default=Path.cwd(),
              help='Project root directory')
@click.option('--no-indentation', is_flag=True, 
              help='Skip indentation fixes')
@click.option('--no-unused-imports', is_flag=True,
              help='Skip unused import removal')
@click.option('--no-debug', is_flag=True,
              help='Skip debug code removal')
@click.option('--no-format', is_flag=True,
              help='Skip code formatting')
@click.option('--dry-run', '-n', is_flag=True,
              help='Show what would be fixed without making changes')
def main(project_root: Path, no_indentation: bool, no_unused_imports: bool,
         no_debug: bool, no_format: bool, dry_run: bool):
    """Auto-fix Python code quality issues in OpenTofu Lab Automation project."""
    
    if dry_run:
        click.echo("DRY RUN MODE - No changes will be made")
    
    fixer = PythonAutoFixer(project_root)
    
    # Configure what to fix
    fix_options = {
        'fix_indentation': not no_indentation,
        'remove_unused': not no_unused_imports,
        'remove_debug': not no_debug,
        'format_code': not no_format
    }
    
    if dry_run:
        python_files = fixer.find_python_files()
        click.echo(f"Would check {len(python_files)} Python files:")
        for file_path in python_files:
            click.echo(f"  - {file_path}")
        return
    
    try:
        fixed_count, total_count = fixer.fix_all_files(**fix_options)
        
        click.echo(f"\n📊 Results:")
        click.echo(f"   Files checked: {total_count}")
        click.echo(f"   Files fixed: {fixed_count}")
        click.echo(f"   Errors: {len(fixer.errors_found)}")
        
        if fixer.errors_found:
            click.echo(f"\n❌ Errors encountered:")
            for error in fixer.errors_found:
                click.echo(f"   {error}")
        
        if fixed_count > 0:
            click.echo(f"\n✅ Successfully fixed {fixed_count} files!")
            click.echo(f"Run 'python -m pytest py/tests/test_python_syntax_validation.py' to verify fixes")
        else:
            click.echo(f"\n✅ All files are already compliant!")
            
    except Exception as e:
        click.echo(f"❌ Error during fixing: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
