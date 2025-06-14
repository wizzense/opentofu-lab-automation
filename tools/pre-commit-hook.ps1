# tools/Pre-Commit-Hook.ps1
<#
.SYNOPSIS
    Pre-commit hook to validate PowerShell scripts before commits
.DESCRIPTION
    Runs validation on PowerShell scripts being committed to prevent
    syntax errors and parameter/import-module ordering issues from
    entering the repository.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Install,
    
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall,
    
    [Parameter(Mandatory = $false)]
    [switch]$Test
)

$ErrorActionPreference = "Stop"

function Install-PreCommitHook {
    $gitHooksDir = ".git/hooks"
    $preCommitPath = "$gitHooksDir/pre-commit"
    
    if (-not (Test-Path $gitHooksDir)) {
        throw "Not in a git repository root directory"
    }
    
    $hookContent = @"
#!/usr/bin/env pwsh
#Requires -Version 5.1
# PowerShell Script Validation Pre-Commit Hook with Batch Processing

`$ErrorActionPreference = 'Stop'

# Check if we're in a git repository
if (-not (Test-Path '.git')) {
    Write-Host "❌ Not in a git repository" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Pre-commit PowerShell validation..." -ForegroundColor Cyan

# Get staged PowerShell files
`$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { `$_ -match '\.ps1`$' }

if (`$stagedFiles.Count -eq 0) {
    Write-Host "✅ No PowerShell files to validate" -ForegroundColor Green
    exit 0
}

Write-Host "📝 Validating `$(`$stagedFiles.Count) PowerShell files with batch processing..." -ForegroundColor Yellow

# Load our new batch processing linting functions
try {
    . "./pwsh/modules/CodeFixer/Public/Invoke-PowerShellLint.ps1"
    . "./pwsh/modules/CodeFixer/Public/Invoke-ParallelScriptAnalyzer.ps1"
    
    # Convert file paths to FileInfo objects
    `$fileObjects = @()
    foreach (`$file in `$stagedFiles) {
        if (Test-Path `$file) {
            `$fileObjects += Get-Item `$file
        }
    }
    
    if (`$fileObjects.Count -eq 0) {
        Write-Host "✅ No valid PowerShell files to validate" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "🚀 Using batch processing for `$(`$fileObjects.Count) files..." -ForegroundColor Cyan
    
    # Run the new batch linting with optimal batch processing parameters
    # Dynamically adjust based on file count and available CPU cores
    `$processorCount = [Environment]::ProcessorCount
    
    if (`$fileObjects.Count -lt 20) {
        # Small file count: fewer, larger batches
        `$batchSize = [Math]::Max(3, [Math]::Ceiling(`$fileObjects.Count / 4))
        `$maxJobs = [Math]::Min(4, `$processorCount)
    } elseif (`$fileObjects.Count -lt 100) {
        # Medium file count: balanced approach
        `$batchSize = 5
        `$maxJobs = [Math]::Min(6, `$processorCount)
    } else {
        # Large file count: optimize for maximum throughput
        `$batchSize = 4
        # Scale jobs based on CPU cores, but cap for system stability
        `$maxJobs = [Math]::Min([Math]::Max(4, `$processorCount), 12)
    }
    
    Write-Host "⚙️ Using `$maxJobs concurrent jobs with batch size of `$batchSize files" -ForegroundColor Gray
    `$lintResults = Invoke-PowerShellLint -Files `$fileObjects -Parallel -OutputFormat 'CI' -PassThru -BatchSize `$batchSize -MaxJobs `$maxJobs
    
    # Check for errors (syntax errors are critical for commits)
    `$syntaxErrors = `$lintResults | Where-Object { `$_.Severity -eq 'Error' }
    
    if (`$syntaxErrors.Count -gt 0) {
        Write-Host "`n❌ CRITICAL SYNTAX ERRORS found:" -ForegroundColor Red
        foreach (`$error in `$syntaxErrors) {
            Write-Host "  `$(`$error.ScriptName):`$(`$error.Line) - `$(`$error.Message)" -ForegroundColor Red
        }
        `$hasErrors = `$true
    } else {
        Write-Host "✅ No critical syntax errors found" -ForegroundColor Green
        `$hasErrors = `$false
    }
    
} catch {
    Write-Host "⚠️ Could not load batch processing, falling back to basic validation..." -ForegroundColor Yellow
    Write-Host "Error: `$(`$_.Exception.Message)" -ForegroundColor Gray
    
    # Fallback to basic syntax checking only
    `$hasErrors = `$false
    foreach (`$file in `$stagedFiles) {
        if (-not (Test-Path `$file)) {
            continue  # File might be deleted
        }
        
        Write-Host "Checking: `$file" -ForegroundColor Gray
        
        # Test: Basic syntax
        try {
            `$content = Get-Content `$file -Raw -ErrorAction Stop
            [System.Management.Automation.PSParser]::Tokenize(`$content, [ref]`$null) | Out-Null
            Write-Host "  ✅ Valid syntax" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ SYNTAX ERROR: `$(`$_.Exception.Message)" -ForegroundColor Red
            `$hasErrors = `$true
            continue
        }
    }
}

if (`$hasErrors) {
    Write-Host "`n❌ Pre-commit validation FAILED!" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Fix the errors above before committing." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All PowerShell files are valid!" -ForegroundColor Green -BackgroundColor Black
    
    # Re-stage any files that were auto-fixed
    foreach (`$file in `$stagedFiles) {
        if (Test-Path `$file) {
            git add `$file
        }
    }
    
    exit 0
}
"@

    Set-Content -Path $preCommitPath -Value $hookContent -NoNewline
    
    # Make executable on Unix systems
    if ($IsLinux -or $IsMacOS) {
        chmod +x $preCommitPath
    }
    
    Write-Host "✅ Pre-commit hook installed successfully" -ForegroundColor Green
    Write-Host "Location: $preCommitPath" -ForegroundColor Gray
}

function Remove-PreCommitHook {
    $preCommitPath = ".git/hooks/pre-commit"
    
    if (Test-Path $preCommitPath) {
        Remove-Item $preCommitPath -Force
        Write-Host "✅ Pre-commit hook removed" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No pre-commit hook found" -ForegroundColor Yellow
    }
}

function Test-PreCommitHook {
    Write-Host "Testing pre-commit hook..." -ForegroundColor Cyan
    
    # Create a test file with syntax error
    $testFile = "temp/test-precommit.ps1"
    $testContent = @"
# Test file with syntax error
Param([string]`$TestParam

Write-Host "Test script"
"@
    
    New-Item -Path "temp" -ItemType Directory -Force | Out-Null
    Set-Content -Path $testFile -Value $testContent
    
    try {
        # Stage the test file
        git add $testFile
        
        # Try to commit (this should fail)
        $commitResult = git commit -m "Test commit (should fail)" 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -ne 0) {
            Write-Host "✅ Pre-commit hook correctly blocked invalid PowerShell script" -ForegroundColor Green
        } else {
            Write-Host "❌ Pre-commit hook failed to block invalid script" -ForegroundColor Red
        }
        
        # Clean up
        git reset HEAD~1 --soft 2>/dev/null
        git reset HEAD $testFile 2>/dev/null
        
    } finally {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        Remove-Item "temp" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

# Main execution
if ($Install) {
    Install-PreCommitHook
} elseif ($Uninstall) {
    Remove-PreCommitHook
} elseif ($Test) {
    Test-PreCommitHook
} else {
    Write-Host "PowerShell Pre-Commit Hook Manager" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  Install:   .\Pre-Commit-Hook.ps1 -Install" -ForegroundColor Gray
    Write-Host "  Uninstall: .\Pre-Commit-Hook.ps1 -Uninstall" -ForegroundColor Gray
    Write-Host "  Test:      .\Pre-Commit-Hook.ps1 -Test" -ForegroundColor Gray
}


