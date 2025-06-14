---
description: Analyze and fix code issues using CodeFixer module with validation and cross-platform testing
mode: agent  
tools: ["codebase", "run_in_terminal"]
---

# Analyze and Fix Code Issues

You are tasked with analyzing and fixing code issues in the OpenTofu Lab Automation project using the CodeFixer module and comprehensive validation.

## Start General, Then Get Specific

### Step 1: General Code Analysis
Begin with a broad analysis to understand the scope of issues:

```powershell
# Import CodeFixer for comprehensive analysis
Import-Module "/pwsh/modules/CodeFixer/" -Force

# Run comprehensive validation to identify all issues
Invoke-ComprehensiveValidation -Path "." -OutputFormat "Detailed"
```

### Step 2: Drill Down Based on Findings
Based on the initial analysis, focus on specific problem areas:

**Syntax Issues Detected:**
```powershell
Invoke-PowerShellLint -Path "." -Parallel -OutputFormat "Detailed" -AutoFix
```

**Import/Module Issues Detected:**
```powershell
Invoke-ImportAnalysis -Path "." -AutoFix -Verbose
```

**Test Framework Issues Detected:**
```powershell
Invoke-TestSyntaxFix -Path "./tests/" -AutoFix -ValidateAfterFix
```

## Provide Examples of Expected Results

### Example 1: Successful Analysis and Fixes
```
Code Analysis Results:
- Files Analyzed: 147 PowerShell files
- Syntax Errors: 23 errors in 8 files (ALL FIXED)
- Import Issues: 12 deprecated paths (ALL UPDATED)
- Style Issues: 45 formatting issues (ALL CORRECTED)
- Test Issues: 3 test syntax errors (ALL RESOLVED)
- Cross-Platform: VALIDATED on Windows, Linux, macOS
```

### Example 2: Issues Found with Specific Details
```
Code Analysis Results:
- Critical: 5 syntax errors preventing script execution
- Warning: 15 deprecated module import paths
- Info: 32 code style improvements available
- Test Issues: 2 test files with missing mock functions
- Performance: 3 scripts using inefficient patterns
```

## Break Down Complex Analysis into Simpler Tasks

### Task 1: Syntax and Import Analysis
Focus on fundamental code correctness:
- PowerShell syntax validation
- Module import path analysis  
- Dependency resolution
- Cross-reference validation

### Task 2: Style and Convention Analysis
Ensure code follows project standards:
- PSScriptAnalyzer rule compliance
- Coding convention adherence
- Documentation completeness
- Function parameter validation

### Task 3: Test Framework Analysis
Validate testing infrastructure:
- Test syntax correctness
- Mock function availability
- Test helper integration
- Cross-platform test compatibility

### Task 4: Performance Analysis
Identify optimization opportunities:
- Inefficient code patterns
- Resource usage optimization
- Parallel processing opportunities
- Caching and efficiency improvements

### Task 5: Security Analysis
Check for security best practices:
- Input validation patterns
- Credential handling
- File permission usage
- External dependency security

## Provide Context Using the Codebase

Use #codebase to understand:
- Current project structure and conventions
- Existing patterns and standards
- Related files that might be affected
- Recent changes that might have introduced issues

## Give Examples of What You Want

### Example Input Request:
"Analyze PowerShell files in the #codebase for syntax errors and deprecated import patterns. Focus on files in /pwsh/modules/ and /scripts/ directories."

### Example Expected Output:
```
Analysis Results for /pwsh/modules/ and /scripts/:

Syntax Issues Found:
- /pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1: Line 45 - Missing closing brace
- /scripts/validation/test-syntax.ps1: Line 12 - Invalid parameter syntax

Import Issues Found:  
- /scripts/maintenance/health-check.ps1: Line 3 - Using deprecated path 'pwsh/lab_utils/LabRunner'
- /pwsh/modules/CodeFixer/Private/helper.ps1: Line 8 - Relative import should be absolute

Fixes Applied:
- ALL syntax errors corrected automatically
- ALL import paths updated to current standards
- Validation passed on all fixed files
```

## Iterate and Refine Analysis

Use follow-up prompts to improve analysis quality:

1. **Initial Scan**: "Run comprehensive code analysis and identify top 5 priority issues"
2. **Targeted Fixes**: "Fix the PowerShell syntax errors found, but validate each fix doesn't break functionality"  
3. **Style Improvements**: "Apply code style fixes but only if they don't change functionality"
4. **Validation**: "Run cross-platform tests to ensure fixes work on all target operating systems"

## Safety Requirements - Always Validate Fixes

CRITICAL: Use the fix-with-validation pattern for all code changes:

```powershell
# Safe fix application process:
1. Create backup before any changes
2. Apply fix using Invoke-SafeFixApplication  
3. Validate fix syntax and functionality
4. Run comprehensive project validation
5. Test on multiple platforms if possible
6. Revert automatically if validation fails
```

### Example Safe Fix Application:
```powershell
$result = Invoke-SafeFixApplication -FixOperation {
    Invoke-PowerShellLint -Path "problematic-script.ps1" -AutoFix
} -ValidationOperation {
    # Test the fixed script works
    . "problematic-script.ps1"
    Test-ScriptFunctionality
} -FixDescription "Fix PowerShell syntax errors" -AffectedFiles @("problematic-script.ps1")

if (-not $result.Success) {
    Write-Host "Fix was automatically reverted due to validation failure"
}
```

## Tools and Context Usage

### Use the Right Tools:
- **codebase**: For understanding project structure and finding related files
- **run_in_terminal**: For executing CodeFixer commands and validations
- Include current file selections and problem context
- Reference terminal output when debugging issues

### Provide Rich Context:
- Include error messages and stack traces
- Reference related files that might be affected
- Consider recent changes that might have caused issues
- Include performance metrics when relevant

## Expected Deliverables

### 1. Comprehensive Analysis Report
- Total files analyzed by type and location
- Issues found categorized by severity
- Root cause analysis for recurring patterns
- Dependencies and relationships identified

### 2. Fix Application Results
- List of all fixes attempted
- Success/failure status for each fix
- Validation results for applied fixes
- Any fixes that were reverted and why

### 3. Code Quality Metrics
- Before/after comparison of code quality scores
- PSScriptAnalyzer compliance improvements
- Test coverage impact
- Performance benchmark changes

### 4. Cross-Platform Validation
- Validation results on Windows, Linux, macOS
- Platform-specific issues identified
- Compatibility improvements achieved
- GitHub Actions workflow status

### 5. Recommendations
- Preventive measures to avoid similar issues
- Code pattern improvements suggested
- Tooling enhancements recommended
- Best practices to implement

## Keep Chat History Relevant

Focus on the current analysis session. Remove or summarize previous analysis results that aren't directly relevant to the current code issues being addressed.
