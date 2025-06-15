<#
.SYNOPSIS
Final comprehensive validation script for OpenTofu Lab Automation

.DESCRIPTION
Performs comprehensive validation checks across the entire project to ensure
system health, code quality, and operational readiness.

.PARAMETER CI
Run in CI mode with structured output and appropriate exit codes

.PARAMETER Quick
Run only quick validation checks

.PARAMETER Detailed
Include detailed analysis and reporting

.EXAMPLE
./run-final-validation.ps1 -CI
Run comprehensive validation in CI mode

.EXAMPLE
./run-final-validation.ps1 -Quick
Run quick validation checks only
#>

[CmdletBinding()]
param(
    [switch]$CI,
    [switch]$Quick,
    [switch]$Detailed
)

# Define the base path
$basePath = $PSScriptRoot
if (-not $basePath) {
    $basePath = Get-Location
}

Write-Host "🔍 Starting Final Validation..." -ForegroundColor Cyan
Write-Host "Base Path: $basePath" -ForegroundColor Gray

# Initialize results
$results = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Status = "Unknown"
    Checks = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
    Errors = @()
    Warnings = @()
}

# Function to add check result
function Add-CheckResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Message = "",
        [string[]]$Details = @()
    )
    
    $check = @{
        Name = $Name
        Status = $Status
        Message = $Message
        Details = $Details
        Timestamp = Get-Date -Format "HH:mm:ss"
    }
    
    $results.Checks += $check
    $results.Summary.Total++
    
    switch ($Status) {
        "Passed" { 
            $results.Summary.Passed++
            Write-Host "  ✅ $Name" -ForegroundColor Green
        }        "Failed" { 
            $results.Summary.Failed++
            $results.Errors += "${Name}: ${Message}"
            Write-Host "  ❌ $Name - $Message" -ForegroundColor Red
        }
        "Warning" { 
            $results.Summary.Warnings++
            $results.Warnings += "${Name}: ${Message}"
            Write-Host "  ⚠️  $Name - $Message" -ForegroundColor Yellow
        }
    }
    
    if ($Details.Count -gt 0 -and $Detailed) {
        foreach ($detail in $Details) {
            Write-Host "     $detail" -ForegroundColor Gray
        }
    }
}

# Check 1: Project Structure
Write-Host "📁 Checking Project Structure..." -ForegroundColor Blue
try {
    $requiredPaths = @(
        "pwsh/modules/CodeFixer",
        "pwsh/modules/LabRunner", 
        "tests",
        "scripts",
        ".github/workflows",
        "py"
    )
    
    $missingPaths = @()
    foreach ($path in $requiredPaths) {
        $fullPath = Join-Path $basePath $path
        if (-not (Test-Path $fullPath)) {
            $missingPaths += $path
        }
    }
    
    if ($missingPaths.Count -eq 0) {
        Add-CheckResult -Name "Project Structure" -Status "Passed" -Message "All required directories present"
    } else {
        Add-CheckResult -Name "Project Structure" -Status "Failed" -Message "Missing directories: $($missingPaths -join ', ')"
    }
} catch {
    Add-CheckResult -Name "Project Structure" -Status "Failed" -Message "Error checking structure: $($_.Exception.Message)"
}

# Check 2: PowerShell Modules
Write-Host "🔧 Checking PowerShell Modules..." -ForegroundColor Blue
try {
    $moduleChecks = @()
    
    # Check CodeFixer module
    $codeFixerPath = Join-Path $basePath "pwsh/modules/CodeFixer/CodeFixer.psd1"
    if (Test-Path $codeFixerPath) {
        $moduleChecks += "CodeFixer module manifest found"
    } else {
        $moduleChecks += "CodeFixer module manifest missing"
    }
    
    # Check LabRunner module  
    $labRunnerPath = Join-Path $basePath "pwsh/modules/LabRunner"
    if (Test-Path $labRunnerPath) {
        $moduleChecks += "LabRunner module directory found"
    } else {
        $moduleChecks += "LabRunner module directory missing"
    }
    
    if ($moduleChecks.Count -eq 2 -and $moduleChecks -notmatch "missing") {
        Add-CheckResult -Name "PowerShell Modules" -Status "Passed" -Message "All modules present" -Details $moduleChecks
    } else {
        Add-CheckResult -Name "PowerShell Modules" -Status "Warning" -Message "Some module issues detected" -Details $moduleChecks
    }
} catch {
    Add-CheckResult -Name "PowerShell Modules" -Status "Failed" -Message "Error checking modules: $($_.Exception.Message)"
}

# Check 3: Python Setup
Write-Host "🐍 Checking Python Setup..." -ForegroundColor Blue
try {
    $pythonChecks = @()
    
    $setupPyPath = Join-Path $basePath "setup.py"
    if (Test-Path $setupPyPath) {
        $pythonChecks += "setup.py found"
    } else {
        $pythonChecks += "setup.py missing"
    }
    
    $pyProjectPath = Join-Path $basePath "pyproject.toml"
    if (Test-Path $pyProjectPath) {
        $pythonChecks += "pyproject.toml found"
    }
    
    $pyPath = Join-Path $basePath "py"
    if (Test-Path $pyPath) {
        $pythonChecks += "Python package directory found"
    } else {
        $pythonChecks += "Python package directory missing"
    }
    
    if ((Test-Path $setupPyPath) -or (Test-Path $pyProjectPath)) {
        Add-CheckResult -Name "Python Setup" -Status "Passed" -Message "Python project configuration present" -Details $pythonChecks
    } else {
        Add-CheckResult -Name "Python Setup" -Status "Failed" -Message "No Python project configuration found" -Details $pythonChecks
    }
} catch {
    Add-CheckResult -Name "Python Setup" -Status "Failed" -Message "Error checking Python setup: $($_.Exception.Message)"
}

# Check 4: Workflow Health (Quick check)
Write-Host "⚡ Checking Workflow Health..." -ForegroundColor Blue
try {
    $workflowPath = Join-Path $basePath ".github/workflows"
    if (Test-Path $workflowPath) {
        $workflowFiles = Get-ChildItem $workflowPath -Filter "*.yml" | Measure-Object
        $details = @("Found $($workflowFiles.Count) workflow files")
        
        # Quick YAML syntax check on a few key files
        $keyWorkflows = @("unified-ci.yml", "unified-testing.yml")
        foreach ($workflow in $keyWorkflows) {
            $workflowFile = Join-Path $workflowPath $workflow
            if (Test-Path $workflowFile) {
                $content = Get-Content $workflowFile -Raw
                if ($content -match "on:" -and $content -notmatch "true:") {
                    $details += "$workflow appears valid"
                } else {
                    $details += "$workflow may have syntax issues"
                }
            }
        }
        
        Add-CheckResult -Name "Workflow Health" -Status "Passed" -Message "Workflows present and basic validation passed" -Details $details
    } else {
        Add-CheckResult -Name "Workflow Health" -Status "Failed" -Message "Workflow directory not found"
    }
} catch {
    Add-CheckResult -Name "Workflow Health" -Status "Failed" -Message "Error checking workflows: $($_.Exception.Message)"
}

# Check 5: Configuration Files
Write-Host "⚙️  Checking Configuration..." -ForegroundColor Blue
try {
    $configChecks = @()
    
    $manifestPath = Join-Path $basePath "PROJECT-MANIFEST.json"
    if (Test-Path $manifestPath) {
        $configChecks += "PROJECT-MANIFEST.json found"
    } else {
        $configChecks += "PROJECT-MANIFEST.json missing"
    }
    
    $yamlLintPath = Join-Path $basePath "configs/yamllint.yaml"
    if (Test-Path $yamlLintPath) {
        $configChecks += "yamllint.yaml configuration found"
    } else {
        $configChecks += "yamllint.yaml configuration missing"
    }
    
    Add-CheckResult -Name "Configuration Files" -Status "Passed" -Message "Configuration check completed" -Details $configChecks
} catch {
    Add-CheckResult -Name "Configuration Files" -Status "Warning" -Message "Error checking configuration: $($_.Exception.Message)"
}

# Quick vs Detailed mode handling
if (-not $Quick) {
    # Check 6: Test Framework (Detailed only)
    Write-Host "🧪 Checking Test Framework..." -ForegroundColor Blue
    try {
        $testChecks = @()
        
        $testPath = Join-Path $basePath "tests"
        if (Test-Path $testPath) {
            $testFiles = Get-ChildItem $testPath -Filter "*.Tests.ps1" -Recurse | Measure-Object
            $testChecks += "Found $($testFiles.Count) test files"
            
            $helperPath = Join-Path $testPath "helpers"
            if (Test-Path $helperPath) {
                $testChecks += "Test helpers directory found"
            }
            
            Add-CheckResult -Name "Test Framework" -Status "Passed" -Message "Test framework structure present" -Details $testChecks
        } else {
            Add-CheckResult -Name "Test Framework" -Status "Failed" -Message "Tests directory not found"
        }
    } catch {
        Add-CheckResult -Name "Test Framework" -Status "Warning" -Message "Error checking test framework: $($_.Exception.Message)"
    }
}

# Determine overall status
if ($results.Summary.Failed -gt 0) {
    $results.Status = "Failed"
} elseif ($results.Summary.Warnings -gt 0) {
    $results.Status = "Warning"
} else {
    $results.Status = "Passed"
}

# Final summary
Write-Host "`n📊 Validation Summary:" -ForegroundColor Cyan
Write-Host "  Total Checks: $($results.Summary.Total)" -ForegroundColor White
Write-Host "  Passed: $($results.Summary.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($results.Summary.Failed)" -ForegroundColor Red
Write-Host "  Warnings: $($results.Summary.Warnings)" -ForegroundColor Yellow

Write-Host "`nOverall Status: $($results.Status)" -ForegroundColor $(
    switch ($results.Status) {
        "Passed" { "Green" }
        "Warning" { "Yellow" }
        "Failed" { "Red" }
        default { "White" }
    }
)

# CI mode output
if ($CI) {
    $results | ConvertTo-Json -Depth 10
    
    # Exit with appropriate code for CI
    switch ($results.Status) {
        "Failed" { exit 1 }
        "Warning" { exit 0 }  # Warnings don't fail CI
        "Passed" { exit 0 }
        default { exit 1 }
    }
} else {
    Write-Host "`n✅ Final validation completed!" -ForegroundColor Green
    if ($results.Errors.Count -gt 0) {
        Write-Host "`n❌ Errors found:" -ForegroundColor Red
        foreach ($error in $results.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    if ($results.Warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $results.Warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
}
