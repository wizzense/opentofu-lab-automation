#!/usr/bin/env python3
"""
Comprehensive Python syntax and indentation validation tests for OpenTofu Lab Automation.
This test suite ensures all Python files in the codebase meet quality standards.
"""

import ast
import os
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

import pytest


class TestPythonSyntaxValidation:
    """Test suite for Python syntax and code quality validation."""

    @pytest.fixture(scope="class")
    def project_root(self) -> Path:
        """Get the project root directory."""
        return Path(__file__).resolve().parents[2]

    @pytest.fixture(scope="class")
    def python_files(self, project_root: Path) -> List[Path]:
        """Get all Python files in the project."""
        python_files = []
        
        # Search in py/ directory
        py_dir = project_root / "py"
        if py_dir.exists():
            python_files.extend(py_dir.rglob("*.py"))
        
        # Search in scripts/ directory for Python files
        scripts_dir = project_root / "scripts"
        if scripts_dir.exists():
            python_files.extend(scripts_dir.rglob("*.py"))
        
        # Search in other common directories
        for directory in ["tools", "utilities", "automation"]:
            dir_path = project_root / directory
            if dir_path.exists():
                python_files.extend(dir_path.rglob("*.py"))
        
        return python_files

    def test_python_files_exist(self, python_files: List[Path]):
        """Ensure we found Python files to test."""
        assert len(python_files) > 0, "No Python files found in the project"

    def test_python_syntax_valid(self, python_files: List[Path]):
        """Test that all Python files have valid syntax."""
        syntax_errors = []
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Try to parse the file
                ast.parse(content, filename=str(file_path))
                
            except SyntaxError as e:
                syntax_errors.append(f"{file_path}: Line {e.lineno}: {e.msg}")
            except UnicodeDecodeError as e:
                syntax_errors.append(f"{file_path}: Encoding error: {e}")
            except Exception as e:
                syntax_errors.append(f"{file_path}: Unexpected error: {e}")
        
        if syntax_errors:
            error_msg = "\n".join([
                "Python syntax errors found:",
                *syntax_errors
            ])
            pytest.fail(error_msg)

    def test_indentation_consistency(self, python_files: List[Path]):
        """Test that Python files have consistent indentation (4 spaces, no tabs)."""
        indentation_errors = []
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for line_num, line in enumerate(lines, 1):
                    # Skip empty lines and lines with only whitespace
                    if line.strip() == "":
                        continue
                    
                    # Check for tabs
                    if '\t' in line:
                        indentation_errors.append(
                            f"{file_path}:{line_num}: Contains tabs instead of spaces"
                        )
                    
                    # Check for inconsistent indentation (not multiple of 4)
                    leading_spaces = len(line) - len(line.lstrip(' '))
                    if leading_spaces > 0 and leading_spaces % 4 != 0:
                        indentation_errors.append(
                            f"{file_path}:{line_num}: Indentation not multiple of 4 "
                            f"(found {leading_spaces} spaces)"
                        )
                        
            except Exception as e:
                indentation_errors.append(f"{file_path}: Error reading file: {e}")
        
        if indentation_errors:
            error_msg = "\n".join([
                "Python indentation errors found:",
                *indentation_errors
            ])
            pytest.fail(error_msg)

    def test_import_statements_valid(self, python_files: List[Path]):
        """Test that all import statements are valid and accessible."""
        import_errors = []
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                tree = ast.parse(content, filename=str(file_path))
                
                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            try:
                                __import__(alias.name)
                            except ImportError:
                                # Skip certain expected missing imports for test files
                                if not self._is_expected_missing_import(alias.name, file_path):
                                    import_errors.append(
                                        f"{file_path}:{node.lineno}: "
                                        f"Cannot import '{alias.name}'"
                                    )
                    
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            try:
                                __import__(node.module)
                            except ImportError:
                                if not self._is_expected_missing_import(node.module, file_path):
                                    import_errors.append(
                                        f"{file_path}:{node.lineno}: "
                                        f"Cannot import from '{node.module}'"
                                    )                                    
            except Exception as e:
                import_errors.append(f"{file_path}: Error parsing imports: {e}")
        
        if import_errors:
            error_msg = "\n".join([
                "Python import errors found:",
                *import_errors[:10],  # Limit to first 10 to avoid spam
            ] + (["..."] if len(import_errors) > 10 else []))
            pytest.fail(error_msg)

    def test_no_debug_code(self, python_files: List[Path]):
        """Test that Python files don't contain debug print statements or test code."""
        debug_issues = []
        
        for file_path in python_files:
            # Skip test files for this check
            if "test_" in file_path.name or file_path.name.endswith("_test.py"):
                continue
                
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for line_num, line in enumerate(lines, 1):
                    line_stripped = line.strip()
                    
                    # Check for debug print statements
                    if (line_stripped.startswith('print(') and 
                        'debug' in line_stripped.lower()):
                        debug_issues.append(
                            f"{file_path}:{line_num}: Debug print statement found"
                        )
                    
                    # Check for pdb or other debug imports
                    if any(debug_import in line_stripped for debug_import in 
                           ['import pdb', 'import ipdb', 'from pdb', 'pdb.set_trace']):
                        debug_issues.append(
                            f"{file_path}:{line_num}: Debug import found"
                        )
                        
            except Exception as e:
                debug_issues.append(f"{file_path}: Error checking for debug code: {e}")
        
        if debug_issues:
            error_msg = "\n".join([
                "Python debug code found:",
                *debug_issues
            ])
            pytest.fail(error_msg)

    def test_code_quality_with_flake8(self, project_root: Path):
        """Test code quality using flake8 linter."""
        try:
            result = subprocess.run(
                [
                    sys.executable, "-m", "flake8", 
                    str(project_root / "py"),
                    "--count",
                    "--max-line-length=88",  # Allow slightly longer lines
                    "--ignore=E203,W503",  # Ignore conflicts with Black
                    "--statistics"
                ],
                capture_output=True,
                text=True,
                cwd=project_root
            )
            
            if result.returncode != 0:
                pytest.fail(f"Flake8 quality check failed:\n{result.stdout}")
                
        except FileNotFoundError:
            pytest.skip("flake8 not available")

    def test_type_hints_compatibility(self, python_files: List[Path]):
        """Test that type hints are compatible with Python 3.8+."""
        type_hint_errors = []
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check for Python 3.9+ generic syntax (dict[str, str] instead of Dict[str, str])
                if any(pattern in content for pattern in [
                    'dict[', 'list[', 'set[', 'tuple[', 'frozenset['
                ]):
                    type_hint_errors.append(
                        f"{file_path}: Uses Python 3.9+ generic syntax "
                        "(use typing.Dict, typing.List, etc. for Python 3.8 compatibility)"
                    )
                    
            except Exception as e:
                type_hint_errors.append(f"{file_path}: Error checking type hints: {e}")
        
        if type_hint_errors:
            error_msg = "\n".join([
                "Python 3.8 compatibility errors found:",
                *type_hint_errors
            ])
            pytest.fail(error_msg)

    def _is_expected_missing_import(self, module_name: str, file_path: Path) -> bool:
        """Check if an import is expected to be missing (e.g., test doubles, optional deps)."""
        expected_missing = [
            'config_schema',           # Project-specific modules that may not be installed
            'enhanced_powershell_executor',
            'textual',                 # Optional UI dependency
            'tkinter-tooltip'          # Optional GUI dependency
        ]
        
        # Skip import validation for test files with test-specific imports
        if "test_" in file_path.name:
            expected_missing.extend([
                'pytest',
                'monkeypatch',
                'tmp_path'
            ])
        
        return any(expected in module_name for expected in expected_missing)


class TestPythonProjectStructure:
    """Test suite for Python project structure and organization."""

    @pytest.fixture(scope="class")
    def project_root(self) -> Path:
        """Get the project root directory."""
        return Path(__file__).resolve().parents[2]

    def test_python_package_structure(self, project_root: Path):
        """Test that Python packages have proper __init__.py files."""
        py_dir = project_root / "py"
        
        if not py_dir.exists():
            pytest.skip("No py/ directory found")
        
        missing_init_files = []
        
        for subdir in py_dir.iterdir():
            if subdir.is_dir() and not subdir.name.startswith('.'):
                # Check if directory contains Python files
                if any(subdir.glob("*.py")):
                    init_file = subdir / "__init__.py"
                    if not init_file.exists():
                        missing_init_files.append(str(subdir))
        
        if missing_init_files:
            error_msg = "\n".join([
                "Missing __init__.py files in:",
                *missing_init_files
            ])
            pytest.fail(error_msg)

    def test_dependencies_declared(self, project_root: Path):
        """Test that all Python dependencies are properly declared."""
        pyproject_file = project_root / "pyproject.toml"
        
        if not pyproject_file.exists():
            pytest.skip("No pyproject.toml found")
        
        # This is a basic check - in practice, you'd parse the TOML
        # and cross-reference with actual imports
        with open(pyproject_file, 'r') as f:
            content = f.read()
        
        # Check for basic required dependencies
        required_deps = ["pyyaml", "click"]
        missing_deps = []
        
        for dep in required_deps:
            if dep not in content.lower():
                missing_deps.append(dep)
        
        if missing_deps:
            error_msg = f"Missing dependencies in pyproject.toml: {missing_deps}"
            pytest.fail(error_msg)


class TestPythonSecurityAndBestPractices:
    """Test suite for Python security and best practices."""

    @pytest.fixture(scope="class")
    def python_files(self) -> List[Path]:
        """Get all Python files in the project."""
        project_root = Path(__file__).resolve().parents[2]
        return list(project_root.rglob("*.py"))

    def test_no_hardcoded_secrets(self, python_files: List[Path]):
        """Test that Python files don't contain hardcoded secrets."""
        security_issues = []
        
        suspicious_patterns = [
            'password =',
            'api_key =',
            'secret =',
            'token =',
            'amazonaws.com',
        ]
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read().lower()
                
                for pattern in suspicious_patterns:
                    if pattern in content:
                        security_issues.append(
                            f"{file_path}: Potential hardcoded secret: '{pattern}'"
                        )
                        
            except Exception as e:
                security_issues.append(f"{file_path}: Error checking for secrets: {e}")
        
        if security_issues:
            error_msg = "\n".join([
                "Potential security issues found:",
                *security_issues
            ])
            pytest.fail(error_msg)

    def test_safe_eval_usage(self, python_files: List[Path]):
        """Test that Python files don't use unsafe eval() statements."""
        eval_issues = []
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                tree = ast.parse(content, filename=str(file_path))
                
                for node in ast.walk(tree):
                    if isinstance(node, ast.Call):
                        if (isinstance(node.func, ast.Name) and 
                            node.func.id in ['eval', 'exec']):
                            eval_issues.append(
                                f"{file_path}:{node.lineno}: "
                                f"Unsafe {node.func.id}() usage found"
                            )
                            
            except Exception as e:
                eval_issues.append(f"{file_path}: Error checking for eval usage: {e}")
        
        if eval_issues:
            error_msg = "\n".join([
                "Unsafe eval/exec usage found:",
                *eval_issues
            ])
            pytest.fail(error_msg)


if __name__ == "__main__":
    # Allow running this test file directly
    pytest.main([__file__, "-v"])
