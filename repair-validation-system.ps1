#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Emergency Validation System Repair
.DESCRIPTION
    This script fixes the broken validation pipeline that was allowing syntax errors to persist
#>

param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "� EMERGENCY VALIDATION SYSTEM REPAIR �" -ForegroundColor Red
Write-Host "Fixing broken validation pipeline..." -ForegroundColor Yellow

$projectRoot = Split-Path -Parent $PSScriptRoot
$issues = @()

# 1. Fix PSScriptAnalyzer usage
Write-Host "`n1. CHECKING POWERSHELL SYNTAX VALIDATION..." -ForegroundColor Cyan

# Test PSScriptAnalyzer on known bad file
$testFile = Join-Path $projectRoot "tests\PathUtils.Tests.ps1"
Write-Host "Testing PSScriptAnalyzer on: $testFile"

try {
    if (Get-Module -ListAvailable PSScriptAnalyzer) {
        $results = Invoke-ScriptAnalyzer -Path $testFile -Severity Error -ErrorAction Stop
        Write-Host "[PASS] PSScriptAnalyzer found $($results.Count) errors" -ForegroundColor Green
        if ($results.Count -gt 0) {
            $results | ForEach-Object { 
                Write-Host "  ERROR: $($_.Message)" -ForegroundColor Red 
                $issues += "PSScriptAnalyzer: $($_.Message) in $($_.ScriptName)"
            }
        }
    } else {
        Write-Host "[FAIL] PSScriptAnalyzer not installed!" -ForegroundColor Red
        $issues += "PSScriptAnalyzer module not installed"
    }
} catch {
    Write-Host "[FAIL] PSScriptAnalyzer failed: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "PSScriptAnalyzer execution failed: $($_.Exception.Message)"
}

# 2. Test PowerShell parser directly
Write-Host "`n2. TESTING POWERSHELL PARSER..." -ForegroundColor Cyan

try {
    $errors = @()
    $tokens = @()
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($testFile, [ref]$tokens, [ref]$errors)
    
    Write-Host "[PASS] Parser found $($errors.Count) errors" -ForegroundColor Green
    if ($errors.Count -gt 0) {
        $errors | ForEach-Object { 
            Write-Host "  PARSE ERROR: $($_.Message)" -ForegroundColor Red 
            $issues += "Parser: $($_.Message) at line $($_.Extent.StartLineNumber)"
        }
    }
} catch {
    Write-Host "[FAIL] Parser failed: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "PowerShell parser failed: $($_.Exception.Message)"
}

# 3. Test YAML validation
Write-Host "`n3. TESTING YAML VALIDATION..." -ForegroundColor Cyan

try {
    $yamlScript = Join-Path $projectRoot "scripts\validation\Invoke-YamlValidation.ps1"
    if (Test-Path $yamlScript) {
        # Test the YAML validation script itself
        $errors = @()
        $tokens = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($yamlScript, [ref]$tokens, [ref]$errors)
        
        if ($errors.Count -eq 0) {
            Write-Host "[PASS] YAML validation script syntax is valid" -ForegroundColor Green
            
            # Test YAML validation on a workflow file
            $testYaml = Get-ChildItem -Path ".github\workflows" -Filter "*.yml" | Select-Object -First 1
            if ($testYaml) {
                Write-Host "Testing YAML validation on: $($testYaml.Name)"
                
                $result = & $yamlScript -Mode "Check" -Path ".github\workflows" -Verbose 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[PASS] YAML validation working" -ForegroundColor Green
                } else {
                    Write-Host "[FAIL] YAML validation failed" -ForegroundColor Red
                    $issues += "YAML validation execution failed"
                }
            }
        } else {
            Write-Host "[FAIL] YAML validation script has syntax errors" -ForegroundColor Red
            $errors | ForEach-Object { 
                $issues += "YAML validation script: $($_.Message)"
            }
        }
    } else {
        Write-Host "[FAIL] YAML validation script not found" -ForegroundColor Red
        $issues += "YAML validation script missing"
    }
} catch {
    Write-Host "[FAIL] YAML validation test failed: $($_.Exception.Message)" -ForegroundColor Red
    $issues += "YAML validation test failed: $($_.Exception.Message)"
}

# 4. Check if validation is being called properly
Write-Host "`n4. CHECKING VALIDATION INTEGRATION..." -ForegroundColor Cyan

$maintenanceScript = Join-Path $projectRoot "scripts\maintenance\unified-maintenance.ps1"
if (Test-Path $maintenanceScript) {
    $content = Get-Content $maintenanceScript -Raw
    
    if ($content -match "PSScriptAnalyzer" -or $content -match "Invoke-ScriptAnalyzer") {
        Write-Host "[PASS] Maintenance script includes PSScriptAnalyzer" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Maintenance script missing PSScriptAnalyzer" -ForegroundColor Red
        $issues += "Maintenance script doesn't use PSScriptAnalyzer"
    }
    
    if ($content -match "YAML.*[Vv]alidation" -or $content -match "Invoke-YamlValidation") {
        Write-Host "[PASS] Maintenance script includes YAML validation" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Maintenance script missing YAML validation" -ForegroundColor Red
        $issues += "Maintenance script doesn't include YAML validation"
    }
} else {
    Write-Host "[FAIL] Maintenance script not found" -ForegroundColor Red
    $issues += "Maintenance script missing"
}

# 5. Create emergency validation script
Write-Host "`n5. CREATING EMERGENCY VALIDATION SCRIPT..." -ForegroundColor Cyan

$emergencyValidator = @'
#!/usr/bin/env pwsh
# Emergency PowerShell Syntax Validator
param([string]$Path = ".")

$errors = @()
Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
        $parseErrors = @()
        $tokens = @()
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors)
        
        if ($parseErrors.Count -gt 0) {
            Write-Host "[FAIL] SYNTAX ERRORS in $($_.Name):" -ForegroundColor Red
            $parseErrors | ForEach-Object {
                Write-Host "   Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red
                $errors += "$($_.FullName):$($_.Extent.StartLineNumber): $($_.Message)"
            }
        } else {
            Write-Host "[PASS] $($_.Name)" -ForegroundColor Green
        }
    } catch {
        Write-Host "[FAIL] FAILED to parse $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
        $errors += "$($_.FullName): Parse failed - $($_.Exception.Message)"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "`n� FOUND $($errors.Count) SYNTAX ERRORS!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n[PASS] All PowerShell files have valid syntax" -ForegroundColor Green
    exit 0
}
'@

$emergencyValidatorPath = Join-Path $projectRoot "emergency-syntax-check.ps1"
Set-Content -Path $emergencyValidatorPath -Value $emergencyValidator
Write-Host "[PASS] Created emergency validator: emergency-syntax-check.ps1" -ForegroundColor Green

# 6. Summary and recommendations
Write-Host "`n" + "="*60 -ForegroundColor Red
Write-Host "� VALIDATION SYSTEM DIAGNOSIS COMPLETE �" -ForegroundColor Red
Write-Host "="*60 -ForegroundColor Red

if ($issues.Count -gt 0) {
    Write-Host "`nCRITICAL ISSUES FOUND:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    
    Write-Host "`nIMMEDIATE ACTIONS NEEDED:" -ForegroundColor Red
    Write-Host "1. Run emergency syntax check: .\emergency-syntax-check.ps1" -ForegroundColor Yellow
    Write-Host "2. Fix all syntax errors found" -ForegroundColor Yellow
    Write-Host "3. Add PSScriptAnalyzer to CI/CD pipeline" -ForegroundColor Yellow
    Write-Host "4. Fix YAML validation Python indentation" -ForegroundColor Yellow
    Write-Host "5. Add pre-commit hooks for validation" -ForegroundColor Yellow
    
    if ($Force) {
        Write-Host "`nRunning emergency syntax check now..." -ForegroundColor Yellow
        & $emergencyValidatorPath
    }
} else {
    Write-Host "`n[PASS] Validation system appears to be working correctly" -ForegroundColor Green
}

Write-Host "`nTo prevent future issues:" -ForegroundColor Cyan
Write-Host "• Always run validation before committing changes" -ForegroundColor White
Write-Host "• Use 'emergency-syntax-check.ps1' for quick syntax verification" -ForegroundColor White
Write-Host "• Ensure maintenance scripts actually catch and report errors" -ForegroundColor White
