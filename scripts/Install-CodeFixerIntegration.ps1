# Install-CodeFixerIntegration.ps1
# Script to integrate the CodeFixer module into the CI/CD pipeline and fix scripts
CmdletBinding()
param(
    switch$Force,
    switch$SkipBackup,
    switch$UpdateWorkflows
)








$ErrorActionPreference = 'Stop'

function Backup-File {
    param(
        string$FilePath
    )

    






if ($SkipBackup) {
        return
    }

    $backupDir = Join-Path $PSScriptRoot ".." "backups" (Get-Date -Format "yyyyMMdd-HHmmss")
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null}

    $fileName = Split-Path -Path $FilePath -Leaf
    $backupPath = Join-Path $backupDir $fileName

    try {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Backed up $FilePath to $backupPath" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Failed to back up $FilePath`: $_"
    }
}

function Update-RunnerScript {
    param(
        string$ScriptPath
    )

    






if (-not (Test-Path $ScriptPath)) {
        Write-Warning "Script $ScriptPath does not exist. Skipping."
        return
    }

    Backup-File -FilePath $ScriptPath

    $content = Get-Content -Path $ScriptPath -Raw
    $moduleImport = 'Import-Module (Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1") -Force'

    # Check if the module import is already present
    if ($content -notmatch 'Import-Module.*CodeFixer') {
        # Find where to insert the module import
        if ($content -match '(?m)^Import-Module') {
            # Add after existing Import-Module statements
            $content = $content -replace '(?m)(^Import-Module.*$)', "`$1`n$moduleImport"
        }
        elseif ($content -match '(?m)^# Import modules') {
            # Add after the import modules comment
            $content = $content -replace '(?m)(^# Import modules.*$)', "`$1`n$moduleImport"
        }
        elseif ($content -match '(?m)^\CmdletBinding\(\)\') {
            # Add after CmdletBinding()
            $content = $content -replace '(?m)(^\CmdletBinding\(\)\.*$)', "`$1`n`n$moduleImport"
        }
        else {
            # Add at the beginning after any comments and param blocks
            $content = $content -replace '(?ms)^((\s*#.*\s*\CmdletBinding.*\\s*param\s*\(.*?\)\s*)*)(.+)', "`$1`n$moduleImport`n`$3"
        }

        Set-Content -Path $ScriptPath -Value $content -Force
        Write-Host "Updated $ScriptPath with CodeFixer module import" -ForegroundColor Green
    }
    else {
        Write-Host "CodeFixer module import already present in $ScriptPath" -ForegroundColor Yellow
    }
}

function Update-WorkflowFile {
    param(
        string$FilePath
    )

    






if (-not (Test-Path $FilePath)) {
        Write-Warning "Workflow file $FilePath does not exist. Skipping."
        return
    }

    Backup-File -FilePath $FilePath

    $content = Get-Content -Path $FilePath -Raw

    # Update the workflow to use the CodeFixer module
    if ($content -notmatch 'modules/CodeFixer') {
        # For the unified-ci.yml file
        if ($FilePath -like '*unified-ci.yml') {
            # Add module import to Pester tests step
            $content = $content -replace '(?m)(shell: pwsh\s+run: \\s+\$config = New-PesterConfiguration)', @"
shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
          
          # Run any necessary fixes before tests
          Invoke-AutoFix -ApplyFixes -Quiet
          
          `$config = New-PesterConfiguration
"@

            # Update the lint job to use the CodeFixer module
            $content = $content -replace '(?m)(name: Run comprehensive linting\s+shell: pwsh\s+run: \\s+\./comprehensive-lint.ps1)', @"
name: Run comprehensive linting
        shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
          
          # Run PowerShell linting using the module
          Invoke-PowerShellLint -OutputFormat CI -FixErrors
"@
        }
        # For the auto-test-generation-execution.yml file
        elseif ($FilePath -like '*auto-test-generation-execution.yml') {
            # Update the test generation step
            $content = $content -replace '(?m)(name: Generate Tests\s+shell: pwsh\s+run: \)', @"
name: Generate Tests
        shell: pwsh
        run: 
          # Import the CodeFixer module
          Import-Module .//pwsh/modules/CodeFixer/CodeFixer.psd1 -Force
"@

            # Add the new test generator call
            if ($content -notmatch 'New-AutoTest') {
                $content = $content -replace '(?m)(# Process each changed script\s+\$changedScripts)', @"
# Use the CodeFixer module to generate tests
foreach (`$scriptPath in `$changedScripts) {
    Write-Host "Generating tests for `$scriptPath using CodeFixer module..."
    New-AutoTest -ScriptPath `$scriptPath -Force
}

# Fallback to the legacy method if needed
# Process each changed script
`$changedScripts
"@
            }
        }

        Set-Content -Path $FilePath -Value $content -Force
        Write-Host "Updated workflow file $FilePath with CodeFixer module integration" -ForegroundColor Green
    }
    else {
        Write-Host "CodeFixer module references already present in $FilePath" -ForegroundColor Yellow
    }
}

function Update-MainScripts {
    # Update comprehensive lint script
    $lintScript = Join-Path $PSScriptRoot ".." "comprehensive-lint.ps1"
    if (Test-Path $lintScript) {
        Backup-File -FilePath $lintScript
        $lintContent = @'
# comprehensive-lint.ps1
# This script is a wrapper around the CodeFixer module's Invoke-PowerShellLint function
CmdletBinding()
param(
    switch$FixErrors,
    ValidateSet('Default', 'CI', 'JSON', 'Detailed')







    string$OutputFormat = 'Default',
    string$OutputPath,
    switch$IncludeArchive
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $modulePath = Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Run the linting using the module
try {
    $params = @{
        OutputFormat = $OutputFormat
    }
    
    if ($FixErrors) {
        $params.FixErrors = $true
    }
    
    if ($OutputPath) {
        $params.OutputPath = $OutputPath
    }
    
    if ($IncludeArchive) {
        $params.IncludeArchive = $true
    }
    
    Invoke-PowerShellLint @params
} catch {
    Write-Host "Linting failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}
'@
        Set-Content -Path $lintScript -Value $lintContent -Force
        Write-Host "Updated comprehensive-lint.ps1 to use CodeFixer module" -ForegroundColor Green
    }

    # Update comprehensive health check script
    $healthScript = Join-Path $PSScriptRoot ".." "comprehensive-health-check.ps1"
    if (Test-Path $healthScript) {
        Backup-File -FilePath $healthScript
        $healthContent = @'
# comprehensive-health-check.ps1
# This script is a wrapper around the CodeFixer module's health check capabilities
CmdletBinding()
param(
    switch$CI,
    switch$Detailed,
    ValidateSet('JSON','Text')







    string$OutputFormat = 'Text',
    string$OutputPath
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $modulePath = Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Run comprehensive validation using the module
try {
    $params = @{
        OutputFormat = $OutputFormat
    }
    
    if ($CI) {
        $params.CI = $true
    }
    
    if ($Detailed) {
        $params.Detailed = $true
    }
    
    if ($OutputPath) {
        $params.OutputPath = $OutputPath
    }
    
    Invoke-ComprehensiveValidation @params
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}
'@
        Set-Content -Path $healthScript -Value $healthContent -Force
        Write-Host "Updated comprehensive-health-check.ps1 to use CodeFixer module" -ForegroundColor Green
    }

    # Create a new comprehensive validation script
    $validationScript = Join-Path $PSScriptRoot ".." "invoke-comprehensive-validation.ps1"
    $validationContent = @'
# invoke-comprehensive-validation.ps1
# This script runs a full system validation using the CodeFixer module
CmdletBinding()
param(
    switch$Fix,
    switch$GenerateTests,
    switch$SaveResults,
    ValidateSet('JSON','Text','CI')







    string$OutputFormat = 'Text',
    string$OutputDirectory = "reports/validation"
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $modulePath = Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Create timestamp for reports
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Create output directory if it doesn't exist
if ($SaveResults -and -not string::IsNullOrEmpty($OutputDirectory)) {
    $reportPath = Join-Path $PSScriptRoot $OutputDirectory
    if (-not (Test-Path $reportPath)) {
        New-Item -Path $reportPath -ItemType Directory -Force | Out-NullWrite-Host "Created report directory: $reportPath" -ForegroundColor Cyan
    }
}

try {
    # Run comprehensive validation
    $params = @{
        OutputFormat = $OutputFormat
        OutputComprehensiveReport = $true
    }
    
    if ($Fix) {
        $params.ApplyFixes = $true
        Write-Host "Running validation with automatic fixes enabled..." -ForegroundColor Cyan
    } else {
        Write-Host "Running validation in report-only mode..." -ForegroundColor Cyan
    }
    
    if ($GenerateTests) {
        $params.GenerateTests = $true
        Write-Host "Test generation is enabled..." -ForegroundColor Cyan
    }
    
    if ($SaveResults) {
        if (-not string::IsNullOrEmpty($OutputDirectory)) {
            $params.OutputPath = Join-Path $PSScriptRoot $OutputDirectory "validation-report-$timestamp.json"
            Write-Host "Results will be saved to: $($params.OutputPath)" -ForegroundColor Cyan
        }
    }
    
    $results = Invoke-ComprehensiveValidation @params
    
    if ($results.OverallStatus -eq 'Success') {
        Write-Host "`nVALIDATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "- Total scripts checked: $($results.SummaryStats.TotalScripts)" -ForegroundColor Green
        Write-Host "- Syntax fixes applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor Green
        Write-Host "- Tests generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor Green
    } else {
        Write-Host "`nVALIDATION COMPLETED WITH ISSUES!" -ForegroundColor Yellow
        Write-Host "- Total scripts checked: $($results.SummaryStats.TotalScripts)" -ForegroundColor Yellow
        Write-Host "- Scripts with issues: $($results.SummaryStats.ScriptsWithIssues)" -ForegroundColor Yellow
        Write-Host "- Syntax fixes applied: $($results.SummaryStats.SyntaxFixesApplied)" -ForegroundColor Yellow
        Write-Host "- Tests generated: $($results.SummaryStats.TestsGenerated)" -ForegroundColor Yellow
        
        if (-not $Fix -and $results.SummaryStats.ScriptsWithIssues -gt 0) {
            Write-Host "`nRun again with -Fix to automatically address issues" -ForegroundColor Cyan
        }
    }
    
} catch {
    Write-Host "Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}
'@
    Set-Content -Path $validationScript -Value $validationContent -Force
    Write-Host "Created new invoke-comprehensive-validation.ps1 script" -ForegroundColor Green

    # Create a simple wrapper for the Invoke-AutoFix function
    $autoFixScript = Join-Path $PSScriptRoot ".." "auto-fix.ps1"
    $autoFixContent = @'
# auto-fix.ps1 
# A simple wrapper around the CodeFixer module's Invoke-AutoFix function
CmdletBinding()
param(
    switch$Apply,
    switch$Quiet,
    switch$Force,
    string$ScriptPaths,
    ValidateSet('All', 'Syntax', 'Ternary', 'ScriptOrder', 'ImportModule')







    string$FixTypes = 'All'
)

$ErrorActionPreference = 'Stop'

# Import the CodeFixer module
try {
    $modulePath = Join-Path $PSScriptRoot "/pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "CodeFixer module not found at path: $modulePath"
        exit 1
    }
} catch {
    Write-Error "Failed to import CodeFixer module: $_"
    exit 1
}

# Run the auto-fix process using the module
try {
    $params = @{
        FixTypes = $FixTypes
    }
    
    if ($Apply) {
        $params.ApplyFixes = $true
    }
    
    if ($Quiet) {
        $params.Quiet = $true
    }
    
    if ($Force) {
        $params.Force = $true
    }
    
    if ($ScriptPaths -and $ScriptPaths.Count -gt 0) {
        $params.ScriptPaths = $ScriptPaths
    }
    
    Invoke-AutoFix @params
} catch {
    Write-Host "Auto-fix process failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}
'@
    Set-Content -Path $autoFixScript -Value $autoFixContent -Force
    Write-Host "Created new auto-fix.ps1 script" -ForegroundColor Green
}

function Update-Documentation {
    # Create a TESTING.md file with comprehensive documentation
    $testingDocsPath = Join-Path $PSScriptRoot ".." "docs" "TESTING.md"
    if (-not (Test-Path (Split-Path -Path $testingDocsPath -Parent))) {
        New-Item -Path (Split-Path -Path $testingDocsPath -Parent) -ItemType Directory -Force | Out-Null}

    $testingDocsContent = @'
# OpenTofu Lab Automation Testing Framework

This document describes the automated testing framework used in the OpenTofu Lab Automation project.

## Overview

The OpenTofu Lab Automation project uses a comprehensive testing and validation framework based on:

1. **CodeFixer PowerShell Module** - Core module that handles syntax fixes, test generation, and validation
2. **Pester Tests** - Automated tests for PowerShell modules and scripts
3. **PyTest** - Automated tests for Python components
4. **Automated CI/CD** - GitHub Actions workflows for continuous integration

## CodeFixer Module

The CodeFixer module (`/pwsh/modules/CodeFixer/`) provides automated tools for:

- Fixing common syntax errors in PowerShell scripts
- Auto-generating Pester tests for PowerShell scripts
- Running linting and validation checks
- Analyzing and reporting on test results
- Watching for file changes and triggering test generation

### Key Functions

 Function  Description 
-----------------------
 `Invoke-TestSyntaxFix`  Fixes common syntax errors in test files 
 `Invoke-TernarySyntaxFix`  Fixes ternary operator issues in scripts 
 `Invoke-ScriptOrderFix`  Fixes Import-Module/Param order in scripts 
 `Invoke-PowerShellLint`  Runs and reports on PowerShell linting 
 `New-AutoTest`  Generates tests for scripts 
 `Watch-ScriptDirectory`  Watches for script changes and generates tests 
 `Invoke-ResultsAnalysis`  Parses test results and applies fixes 
 `Invoke-ComprehensiveValidation`  Runs full validation suite 
 `Invoke-AutoFix`  Runs all available fixers in sequence 

## Using the Framework

### Running Comprehensive Validation

To run a full validation of the codebase:

```powershell
./invoke-comprehensive-validation.ps1 -OutputFormat CI
```

To validate and apply automatic fixes:

```powershell
./invoke-comprehensive-validation.ps1 -Fix -OutputFormat CI
```

### Running Linting

To run PowerShell linting:

```powershell
./comprehensive-lint.ps1
```

To run linting and apply fixes for detected errors:

```powershell
./comprehensive-lint.ps1 -FixErrors
```

### Running Health Checks

To perform a health check of the codebase:

```powershell
./comprehensive-health-check.ps1
```

For CI environments with JSON output:

```powershell
./comprehensive-health-check.ps1 -CI -OutputFormat JSON
```

### Automatic Fixing

To automatically fix common issues:

```powershell
./auto-fix.ps1 -Apply
```

To fix specific types of issues:

```powershell
./auto-fix.ps1 -Apply -FixTypes Syntax,Ternary,ScriptOrder
```

## Continuous Integration

The project uses GitHub Actions for CI/CD, with workflows that:

1. Validate changes to workflow files
2. Run linting on PowerShell code
3. Run Python tests
4. Run Pester tests on different platforms
5. Perform health checks
6. Monitor workflow health
7. Auto-generate tests for new or modified scripts

## Test Generation

When a PowerShell script is added or modified, the auto-test-generation workflow automatically creates or updates corresponding Pester tests. This ensures that all scripts have proper test coverage.

The test generator creates tests based on script metadata, function definitions, and parameter sets to provide meaningful test coverage.

## Manual Test Development

While many tests are auto-generated, you can also create manual tests:

1. Place tests in the appropriate directory under `tests/`
2. Follow the Pester testing conventions
3. Use existing test templates as a guide

## Best Practices

1. **Run validation before pushing** - Use `./invoke-comprehensive-validation.ps1` before pushing changes
2. **Keep tests up to date** - Update tests when changing script functionality  
3. **Check CI results** - Review GitHub Actions workflow results after pushing
4. **Fix reported issues** - Address any issues reported by the validation framework

## Troubleshooting

If you encounter issues with the testing framework:

1. Check that you have PowerShell 7+ installed
2. Ensure PSScriptAnalyzer module is installed (`Install-Module -Name PSScriptAnalyzer`)
3. Verify that Pester 5+ is installed (`Install-Module -Name Pester -RequiredVersion 5.7.1`)
4. Review test output in the TestResults.xml file
5. Use the `-Verbose` parameter with validation scripts for more detailed output

For more information, consult the project documentation(README.md).
'@
    Set-Content -Path $testingDocsPath -Value $testingDocsContent -Force
    Write-Host "Created new documentation at $testingDocsPath" -ForegroundColor Green
}

Write-Host "Starting CodeFixer module integration..." -ForegroundColor Cyan

# Main integration process
try {
    # Update main runner scripts in the root directory
    Update-MainScripts

    # Update documentation
    Update-Documentation

    # Update specific runner scripts with module import
    $scriptsToUpdate = @(
        "fix-bootstrap-script.ps1",
        "fix-powershell-syntax.ps1",
        "fix-runner-execution.ps1",
        "fix-runtime-execution-simple.ps1",
        "fix-test-syntax-errors.ps1",
        "test-all-syntax.ps1",
        "test-cross-platform-executor.ps1",
        "test-param-issue.ps1"
    )

    foreach ($script in $scriptsToUpdate) {
        $scriptPath = Join-Path $PSScriptRoot ".." $script
        Update-RunnerScript -ScriptPath $scriptPath
    }

    # Update workflow files if requested
    if ($UpdateWorkflows) {
        Write-Host "Updating workflow files..." -ForegroundColor Cyan
        $workflows = @(
            ".github/workflows/unified-ci.yml",
            ".github/workflows/auto-test-generation-execution.yml"
        )

        foreach ($workflow in $workflows) {
            $workflowPath = Join-Path $PSScriptRoot ".." $workflow
            Update-WorkflowFile -FilePath $workflowPath
        }
    }

    Write-Host "`nCodeFixer module integration completed successfully!" -ForegroundColor Green
    Write-Host "You can now use the following scripts:" -ForegroundColor Cyan
    Write-Host "- ./invoke-comprehensive-validation.ps1" -ForegroundColor White
    Write-Host "- ./auto-fix.ps1" -ForegroundColor White
    Write-Host "- ./comprehensive-lint.ps1" -ForegroundColor White
    Write-Host "- ./comprehensive-health-check.ps1" -ForegroundColor White
    Write-Host "`nSee docs/TESTING.md for detailed documentation." -ForegroundColor Cyan

}
catch {
    Write-Host "Integration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}




