#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Pre-commit hook to validate PowerShell scripts

.DESCRIPTION
    This hook runs before each commit to ensure:
    - All PowerShell scripts have valid syntax
    - Uses batch processing for fast validation
    - Scripts follow project conventions

.NOTES
    Install: Copy to .git/hooks/pre-commit (remove .ps1 extension)
    Make executable: chmod +x .git/hooks/pre-commit
#>

$ErrorActionPreference = 'Stop'

# Check if we're in a git repository
if (-not (Test-Path '.git')) {
    Write-Host "❌ Not in a git repository" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Pre-commit PowerShell validation..." -ForegroundColor Cyan

# Get staged PowerShell files
$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -match '\.ps1$' }

if ($stagedFiles.Count -eq 0) {
    Write-Host "✅ No PowerShell files to validate" -ForegroundColor Green
    exit 0
}

Write-Host "� Validating $($stagedFiles.Count) PowerShell files with batch processing..." -ForegroundColor Yellow

# Load our new batch processing linting functions
try {
    . "./pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1"
    . "./pwsh/modules/CodeFixer/Public/Invoke-ParallelScriptAnalyzer.ps1"
    
    # Convert file paths to FileInfo objects
    $fileObjects = @()
    foreach ($file in $stagedFiles) {
        if (Test-Path $file) {
            $fileObjects += Get-Item $file
        }
    }
    
    if ($fileObjects.Count -eq 0) {
        Write-Host "✅ No valid PowerShell files to validate" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "🚀 Using batch processing for $($fileObjects.Count) files..." -ForegroundColor Cyan
    
    # Run the new batch linting with parallel processing and optimal batch size
    # For pre-commit hooks, use smaller batches for faster feedback
    $batchSize = 3  # Smaller batches for faster parallel processing
    $maxJobs = [Math]::Min(4, [Environment]::ProcessorCount)  # Limit concurrent jobs for pre-commit
    
    Write-Host "⚙️ Using $maxJobs concurrent jobs with batch size of $batchSize files" -ForegroundColor Gray
    $lintResults = Invoke-PowerShellLint -Files $fileObjects -Parallel -OutputFormat 'CI' -PassThru -BatchSize $batchSize -MaxJobs $maxJobs
    
    # Check for errors (syntax errors are critical for commits)
    $syntaxErrors = $lintResults | Where-Object { $_.Severity -eq 'Error' }
    
    if ($syntaxErrors.Count -gt 0) {
        Write-Host "`n❌ CRITICAL SYNTAX ERRORS found:" -ForegroundColor Red
        foreach ($error in $syntaxErrors) {
            Write-Host "  $($error.ScriptName):$($error.Line) - $($error.Message)" -ForegroundColor Red
        }
        $hasErrors = $true
    } else {
        Write-Host "✅ No critical syntax errors found" -ForegroundColor Green
        $hasErrors = $false
    }
    
} catch {
    Write-Host "⚠️ Could not load batch processing, falling back to basic validation..." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
    
    # Fallback to basic syntax checking only
    $hasErrors = $false
    foreach ($file in $stagedFiles) {
        if (-not (Test-Path $file)) {
            continue  # File might be deleted
        }
        
        Write-Host "Checking: $file" -ForegroundColor Gray
        
        # Test: Basic syntax
        try {
            $content = Get-Content $file -Raw -ErrorAction Stop
            [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null) | Out-Null
            Write-Host "  ✅ Valid syntax" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ SYNTAX ERROR: $($_.Exception.Message)" -ForegroundColor Red
            $hasErrors = $true
            continue
        }
    }
}

# Additional runner script specific checks (if needed)
$runnerFiles = $stagedFiles | Where-Object { $_ -like "*runner_scripts*" }
if ($runnerFiles.Count -gt 0) {
    Write-Host "📋 Running additional checks for $($runnerFiles.Count) runner scripts..." -ForegroundColor Cyan
    
    foreach ($file in $runnerFiles) {
        if (-not (Test-Path $file)) { continue }
        
        Write-Host "Checking runner script: $file" -ForegroundColor Gray
        
        $lines = Get-Content $file -ErrorAction Stop
        $firstExecutableLine = -1
        $paramLineIndex = -1
        $importLineIndex = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            
            # Skip comments and empty lines
            if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith('<#')) {
                continue
            }
            
            if ($firstExecutableLine -eq -1) {
                $firstExecutableLine = $i
            }
            
            if ($line.StartsWith('Param(')) {
                $paramLineIndex = $i
            }
            
            if ($line -match "^Import-Module.*LabRunner.*-Force") {
                $importLineIndex = $i
            }
        }
        
        # Check Param block is first
        if ($paramLineIndex -ne -1 -and $paramLineIndex -ne $firstExecutableLine) {
            Write-Host "  ❌ PARAM ERROR: Param block must be the first executable statement" -ForegroundColor Red
            $hasErrors = $true
        }
        
        # Check Import-Module comes after Param
        if ($importLineIndex -ne -1 -and $paramLineIndex -ne -1 -and $importLineIndex -lt $paramLineIndex) {
            Write-Host "  ❌ IMPORT ERROR: Import-Module must come after Param block" -ForegroundColor Red
            $hasErrors = $true
        }
        
        if (-not $hasErrors) {
            Write-Host "  ✅ Runner script structure valid" -ForegroundColor Green
        }
    }
}

if ($hasErrors) {
    Write-Host "`n❌ Pre-commit validation FAILED!" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Fix the errors above before committing." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All PowerShell files are valid!" -ForegroundColor Green -BackgroundColor Black
    
    # Re-stage any files that were auto-fixed (though we're not auto-fixing in pre-commit for safety)
    foreach ($file in $stagedFiles) {
        if (Test-Path $file) {
            git add $file
        }
    }
    
    exit 0
}


