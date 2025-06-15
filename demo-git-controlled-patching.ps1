#Requires -Version 7.0
<#
.SYNOPSIS
    Demonstration of Git-Controlled Patch System
    
.DESCRIPTION
    This script demonstrates the new mandatory Git-based change control workflow
    by fixing critical Python and PowerShell syntax errors using the enhanced
    PatchManager system.
    
.EXAMPLE
    .\demo-git-controlled-patching.ps1
    
.NOTES
    This replaces the old direct-fix approach with mandatory human validation
#>

[CmdletBinding()]
param()

# Import the enhanced PatchManager module
Import-Module "$PSScriptRoot/pwsh/modules/PatchManager" -Force

Write-Host "🚀 Demonstrating Git-Controlled Patch System" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Example 1: Fix Python syntax errors using Git workflow
Write-Host "`n📝 Example 1: Fixing Python Syntax Errors" -ForegroundColor Yellow

$pythonPatchResult = Invoke-GitControlledPatch -PatchDescription "Fix critical Python indentation and syntax errors" -PatchOperation {
    
    Write-Host "🔧 Applying Python syntax fixes..." -ForegroundColor Blue
    
    # Fix the empty validate-syntax.py file
    $validateSyntaxContent = @'
#!/usr/bin/env python3
"""
Python Syntax Validation Script

Validates Python files for syntax errors and provides detailed reporting.
"""

import ast
import sys
from pathlib import Path
from typing import List, Tuple


def validate_python_file(file_path: Path) -> Tuple[bool, str]:
    """Validate a single Python file for syntax errors."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            source = f.read()
        
        # Try to parse the file
        ast.parse(source, filename=str(file_path))
        return True, "Syntax OK"
    
    except SyntaxError as e:
        return False, f"Syntax Error: {e.msg} at line {e.lineno}"
    except Exception as e:
        return False, f"Error reading file: {str(e)}"


def validate_python_files(directory: Path) -> List[Tuple[Path, bool, str]]:
    """Validate all Python files in a directory."""
    results = []
    
    for py_file in directory.rglob("*.py"):
        is_valid, message = validate_python_file(py_file)
        results.append((py_file, is_valid, message))
    
    return results


def main():
    """Main validation function."""
    if len(sys.argv) > 1:
        target_path = Path(sys.argv[1])
    else:
        target_path = Path(".")
    
    print(f"🐍 Validating Python files in: {target_path}")
    
    results = validate_python_files(target_path)
    
    valid_count = sum(1 for _, is_valid, _ in results if is_valid)
    total_count = len(results)
    
    print(f"\n📊 Validation Results:")
    print(f"  Total files: {total_count}")
    print(f"  Valid files: {valid_count}")
    print(f"  Invalid files: {total_count - valid_count}")
    
    if total_count > valid_count:
        print(f"\n❌ Files with syntax errors:")
        for file_path, is_valid, message in results:
            if not is_valid:
                print(f"  - {file_path}: {message}")
        sys.exit(1)
    else:
        print(f"\n✅ All Python files have valid syntax!")


if __name__ == "__main__":
    main()
'@
    
    Set-Content -Path "./py/validate-syntax.py" -Value $validateSyntaxContent -Encoding UTF8
    Write-Host "✅ Fixed py/validate-syntax.py" -ForegroundColor Green
    
    # Fix any other critical Python files found during error analysis
    $criticalPyFiles = @(
        "./py/test_components.py",
        "./py/tests/test_ui.py"
    )
    
    foreach ($pyFile in $criticalPyFiles) {
        if (Test-Path $pyFile) {
            Write-Host "🔍 Checking $pyFile for syntax errors..." -ForegroundColor Blue
            
            # Use Python to validate syntax
            $validationResult = python -m py_compile $pyFile 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "⚠️ Syntax errors found in $pyFile, applying fixes..." -ForegroundColor Yellow
                
                # Apply basic indentation fixes
                $content = Get-Content $pyFile -Raw
                $fixedContent = $content -replace '(?m)^ ', '    '  # Replace single spaces with 4 spaces
                $fixedContent = $fixedContent -replace '(?m)^  ', '    '  # Replace double spaces with 4 spaces
                $fixedContent = $fixedContent -replace '(?m)^   ', '    '  # Replace triple spaces with 4 spaces
                
                Set-Content -Path $pyFile -Value $fixedContent -Encoding UTF8
                Write-Host "✅ Applied indentation fixes to $pyFile" -ForegroundColor Green
            } else {
                Write-Host "✅ $pyFile syntax is valid" -ForegroundColor Green
            }
        }
    }
    
} -AffectedFiles @("./py/validate-syntax.py", "./py/test_components.py", "./py/tests/test_ui.py") -CreatePullRequest

# Display results
if ($pythonPatchResult.Success) {
    Write-Host "`n✅ Python patch created successfully!" -ForegroundColor Green
    Write-Host "🔗 Pull Request: $($pythonPatchResult.PullRequest.Url)" -ForegroundColor Cyan
    Write-Host "📂 Branch: $($pythonPatchResult.Branch)" -ForegroundColor Cyan
    Write-Host "💾 Backup: $($pythonPatchResult.Backup)" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ Python patch failed: $($pythonPatchResult.Message)" -ForegroundColor Red
}

# Example 2: Fix PowerShell test files using Git workflow
Write-Host "`n📝 Example 2: Fixing PowerShell Test Files" -ForegroundColor Yellow

$powershellPatchResult = Invoke-GitControlledPatch -PatchDescription "Fix PowerShell test syntax and import path errors" -PatchOperation {
    
    Write-Host "🔧 Applying PowerShell test fixes..." -ForegroundColor Blue
    
    # Find test files with common syntax issues
    $testFiles = Get-ChildItem -Path "./tests" -Filter "*.Tests.ps1" -ErrorAction SilentlyContinue
    
    if ($testFiles) {
        foreach ($testFile in $testFiles) {
            Write-Host "🔍 Checking $($testFile.Name)..." -ForegroundColor Blue
            
            $content = Get-Content $testFile.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $modified = $false
                
                # Fix common import path issues
                if ($content -match 'lab_utils') {
                    $content = $content -replace 'lab_utils', 'pwsh/modules/LabRunner'
                    $modified = $true
                    Write-Host "  ✅ Fixed import paths" -ForegroundColor Green
                }
                
                # Fix missing module imports
                if ($content -match 'Describe|It|Should' -and $content -notmatch 'Import-Module.*Pester') {
                    $importStatement = "`n# Auto-added Pester import`nImport-Module Pester -Force`n"
                    $content = $importStatement + $content
                    $modified = $true
                    Write-Host "  ✅ Added Pester import" -ForegroundColor Green
                }
                
                # Apply fixes if content was modified
                if ($modified) {
                    Set-Content -Path $testFile.FullName -Value $content -Encoding UTF8
                    Write-Host "  💾 Applied fixes to $($testFile.Name)" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "ℹ️ No test files found in ./tests directory" -ForegroundColor Blue
    }
    
} -AffectedFiles @("./tests/*.Tests.ps1") -CreatePullRequest

# Display results
if ($powershellPatchResult.Success) {
    Write-Host "`n✅ PowerShell patch created successfully!" -ForegroundColor Green
    Write-Host "🔗 Pull Request: $($powershellPatchResult.PullRequest.Url)" -ForegroundColor Cyan
    Write-Host "📂 Branch: $($powershellPatchResult.Branch)" -ForegroundColor Cyan
    Write-Host "💾 Backup: $($powershellPatchResult.Backup)" -ForegroundColor Cyan
} else {
    Write-Host "`n❌ PowerShell patch failed: $($powershellPatchResult.Message)" -ForegroundColor Red
}

# Example 3: Emergency patch demonstration (for critical issues only)
Write-Host "`n📝 Example 3: Emergency Patch Protocol" -ForegroundColor Yellow
Write-Host "⚠️ This would only be used for critical system-breaking issues" -ForegroundColor Red

# Commented out to avoid creating unnecessary emergency PRs
<#
$emergencyResult = Invoke-EmergencyPatch -PatchDescription "Critical deployment blocker fix" -PatchOperation {
    # Emergency fix operations would go here
    Write-Host "🚨 Applying emergency fix..." -ForegroundColor Red
} -Justification "System completely broken, blocking all development and deployment" -AffectedFiles @("critical/files")
#>

Write-Host "`n🎯 Summary: Git-Controlled Patch System" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "✅ All fixes now require human validation" -ForegroundColor Green
Write-Host "✅ Every patch creates a dedicated branch" -ForegroundColor Green  
Write-Host "✅ Pull requests required for all changes" -ForegroundColor Green
Write-Host "✅ Comprehensive validation before merge" -ForegroundColor Green
Write-Host "✅ Complete audit trail through Git" -ForegroundColor Green
Write-Host "✅ Automatic backup before applying changes" -ForegroundColor Green

Write-Host "`n🔍 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the created pull requests manually" -ForegroundColor White
Write-Host "2. Test changes in isolated environment" -ForegroundColor White  
Write-Host "3. Approve and merge only after validation" -ForegroundColor White
Write-Host "4. Monitor for issues after merge" -ForegroundColor White

Write-Host "`n🚀 Git-Controlled Patch System demonstration completed!" -ForegroundColor Cyan
