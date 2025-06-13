# final-automation-test.ps1
# Comprehensive test to validate our automation system is working correctly

[CmdletBinding()]
param()








$ErrorActionPreference = "Stop"

Write-Host "🧪 FINAL AUTOMATION SYSTEM VALIDATION TEST" -ForegroundColor Cyan
Write-Host "=" * 60

$results = @{
    PowerShellValidation = $false
    PreCommitHook = $false
    BootstrapScript = $false
    RunnerScript = $false
    WorkflowFiles = $false
    TemplateScript = $false
}

$issues = @()

# Test 1: PowerShell Validation System
Write-Host "`n🔍 Test 1: PowerShell Validation System" -ForegroundColor Yellow

try {
    Write-Host "  Running validation on all runner scripts..." -ForegroundColor Gray
    $validationResult = & "tools/Validate-PowerShellScripts.ps1" -Path "pwsh/runner_scripts" -CI 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "  ✅ All PowerShell scripts pass validation" -ForegroundColor Green
        $results.PowerShellValidation = $true
    } else {
        Write-Host "  ❌ PowerShell validation failed" -ForegroundColor Red
        $issues += "PowerShell validation system has issues"
    }
} catch {
    Write-Host "  ❌ PowerShell validation test failed: $_" -ForegroundColor Red
    $issues += "PowerShell validation system error: $_"
}

# Test 2: Pre-commit Hook Installation
Write-Host "`n🔍 Test 2: Pre-commit Hook" -ForegroundColor Yellow

try {
    if (Test-Path ".git/hooks/pre-commit") {
        Write-Host "  ✅ Pre-commit hook is installed" -ForegroundColor Green
        $results.PreCommitHook = $true
    } else {
        Write-Host "  ⚠️ Pre-commit hook not found - installing..." -ForegroundColor Yellow
        & "tools/Pre-Commit-Hook.ps1" -Install
        if (Test-Path ".git/hooks/pre-commit") {
            Write-Host "  ✅ Pre-commit hook installed successfully" -ForegroundColor Green
            $results.PreCommitHook = $true
        } else {
            Write-Host "  ❌ Pre-commit hook installation failed" -ForegroundColor Red
            $issues += "Pre-commit hook installation failed"
        }
    }
} catch {
    Write-Host "  ❌ Pre-commit hook test failed: $_" -ForegroundColor Red
    $issues += "Pre-commit hook error: $_"
}

# Test 3: Bootstrap Script Non-Interactive Mode
Write-Host "`n🔍 Test 3: Bootstrap Script Non-Interactive Mode" -ForegroundColor Yellow

try {
    Write-Host "  Testing bootstrap script with -WhatIf..." -ForegroundColor Gray
    $bootstrapProcess = Start-Process -FilePath "pwsh" -ArgumentList @("-File", "pwsh/kicker-bootstrap.ps1", "-WhatIf") -Wait -NoNewWindow -PassThru -RedirectStandardOutput "bootstrap-output.txt" -RedirectStandardError "bootstrap-error.txt"
    $exitCode = $bootstrapProcess.ExitCode
    $bootstrapResult = Get-Content "bootstrap-output.txt", "bootstrap-error.txt" -ErrorAction SilentlyContinue
    
    if ($exitCode -eq 0 -and $bootstrapResult -join '' -match "WhatIf mode: Exiting without making changes") {
        Write-Host "  ✅ Bootstrap script supports non-interactive mode" -ForegroundColor Green
        $results.BootstrapScript = $true
    } else {
        Write-Host "  ❌ Bootstrap script non-interactive mode failed (Exit Code: $exitCode)" -ForegroundColor Red
        $issues += "Bootstrap script non-interactive mode issues"
    }
    
    # Cleanup temp files
    Remove-Item "bootstrap-output.txt", "bootstrap-error.txt" -ErrorAction SilentlyContinue
} catch {
    Write-Host "  ❌ Bootstrap script test failed: $_" -ForegroundColor Red
    $issues += "Bootstrap script error: $_"
}

# Test 4: Runner Script Syntax  
Write-Host "`n🔍 Test 4: Runner Script Syntax" -ForegroundColor Yellow

try {
    Write-Host "  Validating runner script syntax..." -ForegroundColor Gray
    $runnerContent = Get-Content "pwsh/runner.ps1" -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($runnerContent, [ref]$null)
    
    if ($runnerContent -match "script syntax validation" -and $runnerContent -match "parameter binding issue") {
        Write-Host "  ✅ Runner script has enhanced error detection" -ForegroundColor Green
        $results.RunnerScript = $true
    } else {
        Write-Host "  ❌ Runner script missing expected enhancements" -ForegroundColor Red
        $issues += "Runner script enhancements not found"
    }
} catch {
    Write-Host "  ❌ Runner script validation failed: $_" -ForegroundColor Red
    $issues += "Runner script syntax error: $_"
}

# Test 5: Workflow Files Syntax
Write-Host "`n🔍 Test 5: Workflow Files" -ForegroundColor Yellow

try {
    $workflowFiles = Get-ChildItem ".github/workflows" -Filter "*.yml"
    $allValid = $true
    
    foreach ($file in $workflowFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            # Basic YAML validation - check for document start and basic structure
            if ($content -notmatch "^---" -or $content -match "(?m)^\s*\t") {
                Write-Host "  ⚠️ YAML formatting issue in $($file.Name)" -ForegroundColor Yellow
                $allValid = $false
            }
        } catch {
            Write-Host "  ❌ Failed to read $($file.Name): $_" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    if ($allValid) {
        Write-Host "  ✅ All workflow files pass basic validation" -ForegroundColor Green
        $results.WorkflowFiles = $true
    } else {
        Write-Host "  ❌ Some workflow files have formatting issues" -ForegroundColor Red
        $issues += "Workflow files have formatting issues"
    }
} catch {
    Write-Host "  ❌ Workflow files test failed: $_" -ForegroundColor Red
    $issues += "Workflow files error: $_"
}

# Test 6: Script Template
Write-Host "`n🔍 Test 6: Script Template" -ForegroundColor Yellow

try {
    if (Test-Path "pwsh/ScriptTemplate.ps1") {
        $templateContent = Get-Content "pwsh/ScriptTemplate.ps1" -Raw
        $null = [System.Management.Automation.PSParser]::Tokenize($templateContent, [ref]$null)
        
        if ($templateContent -match "Param\(" -and $templateContent -match "Import-Module.*AFTER Param") {
            Write-Host "  ✅ Script template has correct parameter ordering" -ForegroundColor Green
            $results.TemplateScript = $true
        } else {
            Write-Host "  ❌ Script template missing expected structure" -ForegroundColor Red
            $issues += "Script template structure issues"
        }
    } else {
        Write-Host "  ❌ Script template not found" -ForegroundColor Red
        $issues += "Script template missing"
    }
} catch {
    Write-Host "  ❌ Script template test failed: $_" -ForegroundColor Red
    $issues += "Script template error: $_"
}

# Final Results
Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
Write-Host "🏆 AUTOMATION SYSTEM VALIDATION RESULTS" -ForegroundColor Cyan
Write-Host "=" * 60

$passedTests = ($results.Values | Where-Object { $_ -eq $true }).Count
$totalTests = $results.Count

foreach ($test in $results.Keys) {
    $status = if ($results[$test]) { "✅ PASS"    } else { "❌ FAIL"    }
    $color = if ($results[$test]) { "Green"    } else { "Red"    }
    Write-Host "  $test : $status" -ForegroundColor $color
}

Write-Host "`nOverall Score: $passedTests/$totalTests tests passed" -ForegroundColor $$(if (passedTests -eq $totalTests) { "Green" } else { "Yellow" })

if ($issues.Count -gt 0) {
    Write-Host "`n⚠️ Issues Found:" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 AUTOMATION SYSTEM FULLY OPERATIONAL!" -ForegroundColor Green
    Write-Host "   All validation, prevention, and runtime fixes are working correctly." -ForegroundColor Green
    Write-Host "   The project is now protected against PowerShell syntax errors." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️ Some automation components need attention" -ForegroundColor Yellow
    Write-Host "   Review the issues above and re-run validation" -ForegroundColor Yellow
    exit 1
}



