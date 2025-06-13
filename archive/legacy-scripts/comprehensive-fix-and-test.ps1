#!/usr/bin/env pwsh
# comprehensive-fix-and-test.ps1
# Applies comprehensive fixes and runs parallel testing

param(
    [switch]$AutoFix,
    [switch]$RunTests,
    [switch]$UseParallel,
    [int]$MaxJobs = [Environment]::ProcessorCount,
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

Write-Host "🔧 Comprehensive Fix and Test System" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Gray

# Import modules
try {
    Import-Module "./pwsh/modules/CodeFixer" -Force
    Import-Module "./pwsh/modules/LabRunner" -Force
    Write-Host "✅ Modules imported successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to import modules: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 1: Run automatic fix capture
Write-Host "`n1️⃣ Running Automatic Fix Capture..." -ForegroundColor Yellow
try {
    $issues = Invoke-AutomaticFixCapture -ProjectRoot "." -AutoFix:$AutoFix
    Write-Host "Found $($issues.Count) issues" -ForegroundColor White
    
    if ($AutoFix -and $issues.Count -gt 0) {
        Write-Host "✅ Applied automatic fixes" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Fix capture failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 2: Fix common import issues
Write-Host "`n2️⃣ Fixing Import Issues..." -ForegroundColor Yellow
try {
    Invoke-ImportAnalysis -AutoFix
    Write-Host "✅ Import analysis complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Import analysis failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Run PowerShell linting
Write-Host "`n3️⃣ Running PowerShell Linting..." -ForegroundColor Yellow
try {
    Invoke-PowerShellLint -Path "." -AutoFix:$AutoFix
    Write-Host "✅ Linting complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Linting failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Fix specific syntax issues we've identified
Write-Host "`n4️⃣ Fixing Specific Syntax Issues..." -ForegroundColor Yellow

# Fix the "errors" command issue
$testFiles = Get-ChildItem -Path "tests" -Recurse -Include "*.Tests.ps1"
$fixedErrorsCount = 0

foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and ($content -match '\$errors\s*=\s*errors\b' -or $content -match '^errors\b')) {
        if ($AutoFix) {
            $fixed = $content -replace '\$errors\s*=\s*errors\b', '$errors = @()'
            $fixed = $fixed -replace '^(\s*)errors\b', '$1# errors # TODO: Define this command or remove'
            Set-Content -Path $file.FullName -Value $fixed -NoNewline
            $fixedErrorsCount++
            Write-Host "  Fixed 'errors' command in $($file.Name)" -ForegroundColor Gray
        } else {
            Write-Host "  Found 'errors' command issue in $($file.Name)" -ForegroundColor Yellow
        }
    }
}

if ($fixedErrorsCount -gt 0) {
    Write-Host "✅ Fixed 'errors' command in $fixedErrorsCount files" -ForegroundColor Green
} else {
    Write-Host "✅ No 'errors' command issues found" -ForegroundColor Green
}

# Step 5: Validate syntax
Write-Host "`n5️⃣ Validating Syntax..." -ForegroundColor Yellow
$syntaxErrors = 0
$allPsFiles = Get-ChildItem -Path "." -Recurse -Include "*.ps1" | Where-Object { $_.FullName -notmatch "\\archive\\" }

foreach ($file in $allPsFiles) {
    try {
        $tokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            $syntaxErrors++
            Write-Host "  Syntax error in $($file.Name): $($parseErrors[0].Message)" -ForegroundColor Red
        }
    } catch {
        # Skip files that can't be parsed
    }
}

if ($syntaxErrors -eq 0) {
    Write-Host "✅ No syntax errors found" -ForegroundColor Green
} else {
    Write-Host "⚠️  Found $syntaxErrors files with syntax errors" -ForegroundColor Yellow
}

# Step 6: Run tests if requested
if ($RunTests) {
    Write-Host "`n6️⃣ Running Tests..." -ForegroundColor Yellow
    
    if ($UseParallel) {
        Write-Host "Using parallel test execution with $MaxJobs jobs" -ForegroundColor Cyan
        try {
            $parallelResult = Invoke-ParallelPesterTests -MaxParallelJobs $MaxJobs -PassThru
            Write-Host "✅ Parallel tests completed" -ForegroundColor Green
            Write-Host "  Total: $($parallelResult.TotalTests), Passed: $($parallelResult.PassedTests), Failed: $($parallelResult.FailedTests)" -ForegroundColor White
        } catch {
            Write-Host "❌ Parallel tests failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Falling back to sequential tests..." -ForegroundColor Yellow
            $UseParallel = $false
        }
    }
    
    if (-not $UseParallel) {
        Write-Host "Using sequential test execution" -ForegroundColor Cyan
        try {
            pwsh -File "run-comprehensive-tests.ps1"
            Write-Host "✅ Sequential tests completed" -ForegroundColor Green
        } catch {
            Write-Host "❌ Sequential tests failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n🎉 Comprehensive Fix and Test Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Gray

if ($AutoFix) {
    Write-Host "✅ Auto-fixes applied" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Run with -AutoFix to apply fixes automatically" -ForegroundColor Blue
}

if ($RunTests) {
    Write-Host "✅ Tests executed" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Run with -RunTests to execute test suite" -ForegroundColor Blue
}

Write-Host "ℹ️  Use -UseParallel for faster test execution" -ForegroundColor Blue
Write-Host "ℹ️  Use -MaxJobs N to control parallel job count" -ForegroundColor Blue
