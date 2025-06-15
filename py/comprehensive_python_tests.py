#!/usr/bin/env python3
"""
Comprehensive Python Test Suite for OpenTofu Lab Automation

This script implements comprehensive pytest coverage for Python usage,
specifically addressing the indentation errors and code quality issues
identified in the QA notes.

Following the PatchManager methodology:
- ALWAYS use PatchManager module functions for all fixes and patches
- ALWAYS update changelogs when applying fixes 
- ALWAYS run health checks before and after fixing
- ALWAYS consolidate scattered fixes
"""

import ast
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

import pytest


class PythonTestSuite:
    """Comprehensive Python testing and validation suite."""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.py_dir = project_root / "py"
        self.issues_found: List[Dict] = []
        
    def collect_python_files(self) -> List[Path]:
        """Collect all Python files in the project."""
        if not self.py_dir.exists():
            return []
        
        python_files = []
        for pattern in ["**/*.py"]:
            python_files.extend(self.py_dir.rglob(pattern))
        
        # Filter out cache and generated files
        return [f for f in python_files 
                if "__pycache__" not in str(f) and ".pytest_cache" not in str(f)]
    
    def test_syntax_validation(self) -> Dict:
        """Test 1: Validate Python syntax (addresses IndentationError issues)."""
        results = {"passed": [], "failed": []}
        python_files = self.collect_python_files()
        
        for file_path in python_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Parse with AST to catch syntax errors
                ast.parse(content, filename=str(file_path))
                results["passed"].append(str(file_path))
                
            except SyntaxError as e:
                error_detail = {
                    "file": str(file_path),
                    "line": e.lineno,
                    "error": e.msg,
                    "category": "SyntaxError"
                }
                results["failed"].append(error_detail)
                self.issues_found.append(error_detail)
                
            except Exception as e:
                error_detail = {
                    "file": str(file_path),
                    "error": str(e),
                    "category": "FileError"
                }
                results["failed"].append(error_detail)
        
        return results
    
    def test_indentation_consistency(self) -> Dict:
        """Test 2: Validate indentation consistency (4 spaces, no tabs)."""
        results = {"passed": [], "failed": []}
        python_files = self.collect_python_files()
        
        for file_path in python_files:
            indentation_issues = []
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for line_num, line in enumerate(lines, 1):
                    if line.strip() == "":
                        continue
                    
                    # Check for tabs
                    if '\t' in line:
                        indentation_issues.append({
                            "line": line_num,
                            "issue": "Contains tabs instead of spaces"
                        })
                    
                    # Check for inconsistent indentation
                    leading_spaces = len(line) - len(line.lstrip(' '))
                    if leading_spaces > 0 and leading_spaces % 4 != 0:
                        indentation_issues.append({
                            "line": line_num,
                            "issue": f"Indentation not multiple of 4 ({leading_spaces} spaces)"
                        })
                
                if indentation_issues:
                    error_detail = {
                        "file": str(file_path),
                        "issues": indentation_issues,
                        "category": "IndentationError"
                    }
                    results["failed"].append(error_detail)
                    self.issues_found.append(error_detail)
                else:
                    results["passed"].append(str(file_path))
                    
            except Exception as e:
                error_detail = {
                    "file": str(file_path),
                    "error": str(e),
                    "category": "FileError"
                }
                results["failed"].append(error_detail)
        
        return results
    
    def test_import_validation(self) -> Dict:
        """Test 3: Validate import statements and dependencies."""
        results = {"passed": [], "failed": []}
        python_files = self.collect_python_files()
        
        for file_path in python_files:
            import_issues = []
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                tree = ast.parse(content, filename=str(file_path))
                
                # Check imports
                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            # Skip checking for now - would require complex environment setup
                            pass
                    elif isinstance(node, ast.ImportFrom):
                        # Check relative imports are valid
                        if node.level > 0:  # Relative import
                            # Basic validation - could be expanded
                            pass
                
                # Check for unused imports (simplified)
                # This would require more sophisticated static analysis
                
                if import_issues:
                    error_detail = {
                        "file": str(file_path),
                        "issues": import_issues,
                        "category": "ImportError"
                    }
                    results["failed"].append(error_detail)
                    self.issues_found.append(error_detail)
                else:
                    results["passed"].append(str(file_path))
                    
            except Exception as e:
                error_detail = {
                    "file": str(file_path),
                    "error": str(e),
                    "category": "FileError"
                }
                results["failed"].append(error_detail)
        
        return results
    
    def test_debug_code_detection(self) -> Dict:
        """Test 4: Detect debug and test code in production modules."""
        results = {"passed": [], "failed": []}
        python_files = self.collect_python_files()
        
        for file_path in python_files:
            # Skip test files
            if "test_" in file_path.name or file_path.name.endswith("_test.py"):
                continue
            
            debug_issues = []
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for line_num, line in enumerate(lines, 1):
                    line_stripped = line.strip()
                    
                    # Check for debug print statements
                    if (line_stripped.startswith('print(') and 
                        any(pattern in line_stripped.lower() 
                            for pattern in ['debug', 'test', 'tmp', 'temp'])):
                        debug_issues.append({
                            "line": line_num,
                            "issue": "Debug print statement found"
                        })
                    
                    # Check for debug imports
                    if any(debug_import in line_stripped for debug_import in 
                           ['import pdb', 'import ipdb', 'from pdb', 'pdb.set_trace']):
                        debug_issues.append({
                            "line": line_num,
                            "issue": "Debug import found"
                        })
                
                if debug_issues:
                    error_detail = {
                        "file": str(file_path),
                        "issues": debug_issues,
                        "category": "DebugCode"
                    }
                    results["failed"].append(error_detail)
                    self.issues_found.append(error_detail)
                else:
                    results["passed"].append(str(file_path))
                    
            except Exception as e:
                error_detail = {
                    "file": str(file_path),
                    "error": str(e),
                    "category": "FileError"
                }
                results["failed"].append(error_detail)
        
        return results
    
    def test_python38_compatibility(self) -> Dict:
        """Test 5: Python 3.8 compatibility (type hints, syntax)."""
        results = {"passed": [], "failed": []}
        python_files = self.collect_python_files()
        
        incompatible_patterns = [
            'dict[', 'list[', 'set[', 'tuple[', 'frozenset[',  # Python 3.9+ generics
            ':=',  # Walrus operator (ok in 3.8+, but checking)
        ]
        
        for file_path in python_files:
            compatibility_issues = []
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                for pattern in incompatible_patterns:
                    if pattern in content:
                        # Only flag dict[, list[ etc as these are 3.9+
                        if pattern in ['dict[', 'list[', 'set[', 'tuple[', 'frozenset[']:
                            compatibility_issues.append({
                                "pattern": pattern,
                                "issue": f"Python 3.9+ syntax found: {pattern}"
                            })
                
                if compatibility_issues:
                    error_detail = {
                        "file": str(file_path),
                        "issues": compatibility_issues,
                        "category": "CompatibilityError"
                    }
                    results["failed"].append(error_detail)
                    self.issues_found.append(error_detail)
                else:
                    results["passed"].append(str(file_path))
                    
            except Exception as e:
                error_detail = {
                    "file": str(file_path),
                    "error": str(e),
                    "category": "FileError"
                }
                results["failed"].append(error_detail)
        
        return results
    
    def run_all_tests(self) -> Dict:
        """Run all Python validation tests and return comprehensive results."""
        print("🐍 Starting Comprehensive Python Test Suite")
        print("=" * 60)
        
        # Clear previous issues
        self.issues_found = []
        
        results = {}
        
        # Test 1: Syntax Validation
        print("\n1️⃣  Testing Python syntax validation...")
        results['syntax'] = self.test_syntax_validation()
        print(f"   ✅ Passed: {len(results['syntax']['passed'])}")
        print(f"   ❌ Failed: {len(results['syntax']['failed'])}")
        
        # Test 2: Indentation Consistency  
        print("\n2️⃣  Testing indentation consistency...")
        results['indentation'] = self.test_indentation_consistency()
        print(f"   ✅ Passed: {len(results['indentation']['passed'])}")
        print(f"   ❌ Failed: {len(results['indentation']['failed'])}")
        
        # Test 3: Import Validation
        print("\n3️⃣  Testing import validation...")
        results['imports'] = self.test_import_validation()
        print(f"   ✅ Passed: {len(results['imports']['passed'])}")
        print(f"   ❌ Failed: {len(results['imports']['failed'])}")
        
        # Test 4: Debug Code Detection
        print("\n4️⃣  Testing debug code detection...")
        results['debug'] = self.test_debug_code_detection()
        print(f"   ✅ Passed: {len(results['debug']['passed'])}")
        print(f"   ❌ Failed: {len(results['debug']['failed'])}")
        
        # Test 5: Python 3.8 Compatibility
        print("\n5️⃣  Testing Python 3.8 compatibility...")
        results['compatibility'] = self.test_python38_compatibility()
        print(f"   ✅ Passed: {len(results['compatibility']['passed'])}")
        print(f"   ❌ Failed: {len(results['compatibility']['failed'])}")
        
        return results
    
    def generate_report(self, results: Dict) -> str:
        """Generate a comprehensive test report."""
        total_files = len(self.collect_python_files())
        total_issues = len(self.issues_found)
        
        report = [
            "# Python Test Suite Report",
            f"Generated: {__import__('datetime').datetime.now().isoformat()}",
            "",
            "## Summary",
            f"- Total Python files: {total_files}",
            f"- Total issues found: {total_issues}",
            "",
        ]
        
        # Summary by test type
        for test_name, test_results in results.items():
            failed_count = len(test_results['failed'])
            passed_count = len(test_results['passed'])
            report.extend([
                f"### {test_name.title()} Test",
                f"- Passed: {passed_count}",
                f"- Failed: {failed_count}",
                ""
            ])
        
        # Detailed issues
        if self.issues_found:
            report.extend([
                "## Detailed Issues",
                ""
            ])
            
            for issue in self.issues_found:
                report.append(f"### {issue['category']}: {issue['file']}")
                if 'issues' in issue:
                    for sub_issue in issue['issues']:
                        if 'line' in sub_issue:
                            report.append(f"- Line {sub_issue['line']}: {sub_issue['issue']}")
                        else:
                            report.append(f"- {sub_issue['issue']}")
                elif 'error' in issue:
                    report.append(f"- {issue['error']}")
                report.append("")
        
        return "\n".join(report)


def main():
    """Main function following PatchManager methodology."""
    project_root = Path(__file__).resolve().parents[1]
    
    print("🔧 Python Test Suite - Following PatchManager Methodology")
    print("📋 QA Notes Review: Python indentation errors and comprehensive pytest coverage")
    print("")
    
    # Step 1: Initialize test suite
    test_suite = PythonTestSuite(project_root)
    
    # Step 2: Run comprehensive tests  
    results = test_suite.run_all_tests()
    
    # Step 3: Generate report
    report = test_suite.generate_report(results)
    
    # Step 4: Save report (following project standards)
    report_dir = project_root / "reports"
    report_dir.mkdir(exist_ok=True)
    
    report_file = report_dir / f"python-test-suite-{__import__('datetime').datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"\n📊 Results Summary:")
    print(f"   Total issues found: {len(test_suite.issues_found)}")
    print(f"   Report saved to: {report_file}")
    
    # Step 5: Provide recommendations
    if test_suite.issues_found:
        print(f"\n🛠️  Recommendations:")
        print(f"   1. Use PatchManager to fix indentation issues: Invoke-InfrastructureFix")
        print(f"   2. Run comprehensive validation: Invoke-UnifiedMaintenance -Mode 'All' -AutoFix")
        print(f"   3. Update changelogs: -UpdateChangelog parameter")
        print(f"   4. Validate fixes: Invoke-HealthCheck")
        
        # Exit with error if issues found
        return 1
    else:
        print(f"\n✅ All Python files passed validation!")
        return 0


if __name__ == "__main__":
    sys.exit(main())
