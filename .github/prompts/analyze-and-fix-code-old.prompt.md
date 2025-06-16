---
description: Analyze and fix code issues using the CodeFixer module and project standards
mode: agent
tools: "filesystem", "powershell", "codefixer"
---

# Code Analysis and Fixing

Analyze PowerShell code for issues and apply automated fixes using the OpenTofu Lab Automation CodeFixer module and established patterns.

## Analysis Scope

Perform comprehensive code analysis including:

1. **Syntax Analysis**:
   - PowerShell syntax errors
   - Ternary operator issues
   - Parameter block problems
   - Import statement errors

2. **Style and Quality**:
   - PSScriptAnalyzer rule compliance
   - Coding standard adherence
   - Documentation completeness
   - Performance optimization opportunities

3. **Module Integration**:
   - Correct module import paths
   - LabRunner pattern compliance
   - CodeFixer integration
   - Dependency validation

4. **Security Review**:
   - Input validation
   - Privilege requirements
   - External dependency safety
   - Credential handling

## CodeFixer Integration

Use the CodeFixer module for automated analysis and fixing:

```powershell
# Import CodeFixer module
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Comprehensive analysis
Invoke-ComprehensiveValidation -Path "${selection}" -OutputFormat "Detailed"

# PowerShell linting with parallel processing
Invoke-PowerShellLint -Path "${selection}" -Parallel -OutputFormat "JSON"

# Import analysis and fixing
Invoke-ImportAnalysis -Path "${selection}" -AutoFix

# Auto-fix capture and application
Invoke-AutoFixCapture -FilePath "${file}"

# Specific syntax fixes
Invoke-TernarySyntaxFix -Path "${selection}"
Invoke-TestSyntaxFix -Path "${selection}"
Invoke-ScriptOrderFix -Path "${selection}"
```

## Analysis Patterns

### 1. Module Import Issues
```powershell
#  Deprecated patterns to fix:
Import-Module "pwsh/modules/LabRunner/LabRunner"
. "$PSScriptRoot/../lab_utils/LabRunner.ps1"

#  Correct patterns:
Import-Module "/pwsh/modules/LabRunner/" -Force
Import-Module "/pwsh/modules/CodeFixer/" -Force
```

### 2. Script Structure Issues
```powershell
#  Missing standard structure:
param($config)
# some code

#  Proper structure:
Param(
    Parameter(Mandatory=$true)
    pscustomobject$Config
)

$ErrorActionPreference = "Stop"
Import-Module "/pwsh/modules/LabRunner/" -Force

Invoke-LabStep -Config $Config -Body {
    # Implementation
}
```

### 3. Error Handling Issues
```powershell
#  Poor error handling:
try { SomeOperation } catch { Write-Host "Error" }

#  Proper error handling:
try {
    $result = SomeOperation
    Write-CustomLog "Operation successful: $result" "INFO"
} catch {
    Write-CustomLog "Operation failed: $($_.Exception.Message)" "ERROR"
    throw
}
```

## Fix Categories

### Automatic Fixes (Applied by CodeFixer)
- Ternary operator syntax corrections
- Import path updates (lab_utils  modules)
- Parameter block formatting
- Here-string syntax fixes
- Unicode character removal
- Missing closing braces/parentheses

### Manual Review Required
- Complex logic errors
- Security vulnerabilities
- Performance bottlenecks
- Architecture improvements
- Custom business logic issues

### Style Improvements
- Function documentation
- Variable naming consistency
- Code organization
- Comment quality
- Performance optimizations

## Analysis Output Format

```markdown
## Code Analysis Results

### File: ${file}

#### Issues Found: X
#### Auto-fixable: Y
#### Manual review: Z

### Critical Issues
- **Line X**: Issue description
  - **Severity**: Critical
  - **Type**: Syntax/Security/Performance
  - **Fix**: Automatic/Manual
  - **Recommendation**: Specific fix description

### Warnings
- **Line X**: Issue description
  - **Severity**: Warning
  - **Type**: Style/Performance/Best Practice
  - **Recommendation**: Improvement suggestion

### Suggestions
- **Line X**: Suggestion description
  - **Type**: Optimization/Enhancement
  - **Benefit**: Expected improvement

### Auto-fixes Applied
-  Updated import paths (lab_utils  modules)
-  Fixed ternary operator syntax
-  Corrected parameter block formatting
-  Added missing error handling

### Summary
- **Overall Quality Score**: X/10
- **Compliance**: Y% with project standards
- **Next Steps**: Prioritized recommendations
```

## Validation Commands

After fixing, validate the results:

```powershell
# Syntax validation
$errors = $null
$null = System.Management.Automation.Language.Parser::ParseFile($FilePath, ref$null, ref$errors)
if ($errors.Count -eq 0) { 
    Write-Host " Syntax valid" -ForegroundColor Green 
}

# PSScriptAnalyzer validation
$issues = Invoke-ScriptAnalyzer -Path $FilePath -Severity Error,Warning
Write-Host "PSScriptAnalyzer issues: $($issues.Count)"

# Module import test
try {
    & $FilePath -Config (pscustomobject@{}) -WhatIf
    Write-Host " Script executes without errors"
} catch {
    Write-Host " Execution error: $_"
}
```

## Integration with Project Tools

```powershell
# Use project maintenance scripts
./scripts/maintenance/unified-maintenance.ps1 -Mode "Quick" -AutoFix

# Run comprehensive validation
Invoke-ComprehensiveValidation -Path "${selection}" -SkipFixes:$false

# Generate tests for fixed code
New-AutoTest -ScriptPath "${file}" -OutputPath "./tests/"
```

## Input Variables

- `${selection}`: Selected code or files to analyze
- `${file}`: Current file being analyzed
- `${input:fixLevel}`: Level of fixes to apply (syntax, style, all)
- `${input:outputFormat}`: Output format (markdown, json, text)

Please specify:
1. Files or code to analyze
2. Type of analysis needed (syntax, style, security, performance)
3. Fix level preference (automatic only, or include manual recommendations)
4. Output format preference

## Reference Instructions

This prompt references:
- PowerShell Standards(../instructions/powershell-standards.instructions.md)
- Testing Standards(../instructions/testing-standards.instructions.md)

