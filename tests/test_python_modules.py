#!/usr/bin/env python3
"""
Intelligent Python Test Discovery and Execution

Complements the PowerShell testing system by providing Python-specific
test discovery and execution for the labctl package and other Python modules.
"""

import ast
import importlib.util
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Set, Any
import pytest


class PythonTestDiscovery:
    """Intelligent test discovery for Python modules."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.python_root = project_root / "src" / "python"
        self.test_results = []
        
    def discover_modules(self) -> List[Dict[str, Any]]:
        """Discover all Python modules in the project."""
        modules = []
        
        # Find labctl package
        labctl_path = self.python_root / "labctl"
        if labctl_path.exists():
            modules.append({
                'name': 'labctl',
                'path': labctl_path,
                'type': 'package',
                'files': list(labctl_path.glob("*.py")),
                'has_cli': (labctl_path / "cli.py").exists(),
                'has_init': (labctl_path / "__init__.py").exists()
            })
        
        # Find standalone Python files
        for py_file in self.python_root.glob("*.py"):
            if py_file.name != "__init__.py":
                modules.append({
                    'name': py_file.stem,
                    'path': py_file,
                    'type': 'module',
                    'files': [py_file],
                    'has_cli': self._has_cli_interface(py_file),
                    'has_init': False
                })
        
        return modules
    
    def _has_cli_interface(self, file_path: Path) -> bool:
        """Check if a Python file has CLI interface."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Check for common CLI patterns
            cli_patterns = [
                'if __name__ == "__main__"',
                'import argparse',
                'import click',
                'import typer',
                'ArgumentParser()',
                '@click.',
                '@app.',
            ]
            
            return any(pattern in content for pattern in cli_patterns)
        except:
            return False
    
    def analyze_module_structure(self, module: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze the structure of a Python module."""
        analysis = {
            'functions': [],
            'classes': [],
            'imports': set(),
            'has_tests': False,
            'has_docstrings': False,
            'syntax_valid': True,
            'syntax_errors': []
        }
        
        for file_path in module['files']:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Parse AST
                tree = ast.parse(content)
                
                for node in ast.walk(tree):
                    if isinstance(node, ast.FunctionDef):
                        analysis['functions'].append({
                            'name': node.name,
                            'has_docstring': ast.get_docstring(node) is not None,
                            'line_number': node.lineno
                        })
                        if ast.get_docstring(node):
                            analysis['has_docstrings'] = True
                    
                    elif isinstance(node, ast.ClassDef):
                        analysis['classes'].append({
                            'name': node.name,
                            'has_docstring': ast.get_docstring(node) is not None,
                            'line_number': node.lineno
                        })
                        if ast.get_docstring(node):
                            analysis['has_docstrings'] = True
                    
                    elif isinstance(node, ast.Import):
                        for alias in node.names:
                            analysis['imports'].add(alias.name)
                    
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            analysis['imports'].add(node.module)
                
                # Check for test patterns
                if any(func['name'].startswith('test_') for func in analysis['functions']):
                    analysis['has_tests'] = True
                
            except SyntaxError as e:
                analysis['syntax_valid'] = False
                analysis['syntax_errors'].append(f"{file_path.name}: {e}")
            except Exception as e:
                analysis['syntax_errors'].append(f"{file_path.name}: {e}")
        
        analysis['imports'] = list(analysis['imports'])
        return analysis
    
    def test_module_syntax(self, module: Dict[str, Any]) -> Dict[str, Any]:
        """Test Python module syntax."""
        results = {
            'module': module['name'],
            'passed': True,
            'errors': []
        }
        
        for file_path in module['files']:
            try:
                # Compile to check syntax
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                compile(content, str(file_path), 'exec')
                
            except SyntaxError as e:
                results['passed'] = False
                results['errors'].append(f"Syntax error in {file_path.name}: {e}")
            except Exception as e:
                results['passed'] = False
                results['errors'].append(f"Error in {file_path.name}: {e}")
        
        return results
    
    def test_module_imports(self, module: Dict[str, Any]) -> Dict[str, Any]:
        """Test that module imports work correctly."""
        results = {
            'module': module['name'],
            'passed': True,
            'errors': []
        }
        
        # For packages, try to import the package
        if module['type'] == 'package' and module['has_init']:
            try:
                spec = importlib.util.spec_from_file_location(
                    module['name'], 
                    module['path'] / "__init__.py"
                )
                if spec and spec.loader:
                    test_module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(test_module)
            except Exception as e:
                results['passed'] = False
                results['errors'].append(f"Import error for package {module['name']}: {e}")
        
        # For individual files
        for file_path in module['files']:
            if file_path.name == "__init__.py":
                continue
                
            try:
                spec = importlib.util.spec_from_file_location(
                    file_path.stem, 
                    file_path
                )
                if spec and spec.loader:
                    test_module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(test_module)
            except Exception as e:
                results['passed'] = False
                results['errors'].append(f"Import error for {file_path.name}: {e}")
        
        return results
    
    def test_cli_interfaces(self, module: Dict[str, Any]) -> Dict[str, Any]:
        """Test CLI interfaces."""
        results = {
            'module': module['name'],
            'passed': True,
            'errors': []
        }
        
        if not module['has_cli']:
            return results
        
        # Test help command for CLI modules
        for file_path in module['files']:
            if file_path.name == "cli.py" or module['has_cli']:
                try:
                    # Try to run with --help
                    result = subprocess.run(
                        [sys.executable, str(file_path), "--help"],
                        capture_output=True,
                        text=True,
                        timeout=10
                    )
                    
                    if result.returncode not in [0, 2]:  # 0 = success, 2 = argparse help
                        results['passed'] = False
                        results['errors'].append(f"CLI help failed for {file_path.name}: {result.stderr}")
                        
                except subprocess.TimeoutExpired:
                    results['passed'] = False
                    results['errors'].append(f"CLI help timeout for {file_path.name}")
                except Exception as e:
                    results['passed'] = False
                    results['errors'].append(f"CLI test error for {file_path.name}: {e}")
        
        return results
    
    def run_pytest_if_available(self) -> Optional[Dict[str, Any]]:
        """Run pytest if test files are found."""
        test_files = list(self.python_root.rglob("test_*.py")) + list(self.python_root.rglob("*_test.py"))
        
        if not test_files:
            return None
        
        try:
            # Run pytest with XML output
            test_output = self.project_root / "tests" / "results" / "pytest_results.xml"
            test_output.parent.mkdir(parents=True, exist_ok=True)
            
            result = subprocess.run([
                sys.executable, "-m", "pytest",
                str(self.python_root),
                f"--junit-xml={test_output}",
                "--tb=short"
            ], capture_output=True, text=True)
            
            return {
                'returncode': result.returncode,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'xml_output': test_output if test_output.exists() else None
            }
        except Exception as e:
            return {
                'returncode': -1,
                'error': str(e)
            }
    
    def generate_test_report(self, modules: List[Dict[str, Any]], test_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Generate a comprehensive test report."""
        report = {
            'timestamp': str(Path(__file__).stat().st_mtime),
            'project_root': str(self.project_root),
            'python_root': str(self.python_root),
            'summary': {
                'total_modules': len(modules),
                'total_files': sum(len(m['files']) for m in modules),
                'modules_with_cli': sum(1 for m in modules if m['has_cli']),
                'packages': sum(1 for m in modules if m['type'] == 'package'),
                'standalone_modules': sum(1 for m in modules if m['type'] == 'module')
            },
            'modules': modules,
            'test_results': test_results,
            'overall_status': 'PASSED' if all(r['passed'] for r in test_results) else 'FAILED'
        }
        
        return report


def main():
    """Main test execution."""
    project_root = Path(__file__).parent.parent
    discovery = PythonTestDiscovery(project_root)
    
    print("🐍 Python Module Test Discovery")
    print(f"Project Root: {project_root}")
    print(f"Python Root: {discovery.python_root}")
    
    # Discover modules
    modules = discovery.discover_modules()
    print(f"\nFound {len(modules)} Python modules:")
    for module in modules:
        print(f"  - {module['name']} ({module['type']}) - {len(module['files'])} files")
        if module['has_cli']:
            print(f"    ✓ Has CLI interface")
    
    # Run tests
    print("\n🧪 Running Python Tests...")
    test_results = []
    
    for module in modules:
        print(f"\nTesting module: {module['name']}")
        
        # Test syntax
        syntax_result = discovery.test_module_syntax(module)
        test_results.append(syntax_result)
        if syntax_result['passed']:
            print(f"  ✓ Syntax check passed")
        else:
            print(f"  ❌ Syntax check failed: {syntax_result['errors']}")
        
        # Test imports
        import_result = discovery.test_module_imports(module)
        test_results.append(import_result)
        if import_result['passed']:
            print(f"  ✓ Import check passed")
        else:
            print(f"  ❌ Import check failed: {import_result['errors']}")
        
        # Test CLI
        if module['has_cli']:
            cli_result = discovery.test_cli_interfaces(module)
            test_results.append(cli_result)
            if cli_result['passed']:
                print(f"  ✓ CLI check passed")
            else:
                print(f"  ❌ CLI check failed: {cli_result['errors']}")
    
    # Run pytest if available
    pytest_result = discovery.run_pytest_if_available()
    if pytest_result:
        print(f"\n🔬 Pytest Results: {'PASSED' if pytest_result['returncode'] == 0 else 'FAILED'}")
        if pytest_result.get('stdout'):
            print(pytest_result['stdout'])
    
    # Generate report
    report = discovery.generate_test_report(modules, test_results)
    
    # Save report
    report_path = project_root / "tests" / "results" / "python_test_report.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    print(f"\n📊 Test Summary:")
    print(f"  Overall Status: {report['overall_status']}")
    print(f"  Total Modules: {report['summary']['total_modules']}")
    print(f"  Total Files: {report['summary']['total_files']}")
    print(f"  Report saved to: {report_path}")
    
    # Return appropriate exit code
    return 0 if report['overall_status'] == 'PASSED' else 1


if __name__ == "__main__":
    sys.exit(main())
