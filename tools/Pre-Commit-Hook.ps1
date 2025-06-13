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
    [Parameter(Mandatory = $false)



]
    [switch]$Install,
    
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Install-PreCommitHook {
    $gitHooksDir = ".git/hooks"
    $preCommitPath = "$gitHooksDir/pre-commit"
    
    if (-not (Test-Path $gitHooksDir)) {
        throw "Not in a git repository root directory"
    }
    
    $hookContent = @"
#!/bin/sh
# PowerShell Script Validation Pre-Commit Hook

# Check if PowerShell is available
if ! command -v pwsh >/dev/null 2>&1; then
    echo "PowerShell not found. Skipping PowerShell validation."
    exit 0
fi

# Get list of PowerShell files being committed
PS_FILES=`$(git diff --cached --name-only --diff-filter=ACM | grep '\.ps1$')

if [ -z "`$PS_FILES" ]; then
    echo "No PowerShell files to validate."
    exit 0
fi

echo "Validating PowerShell files..."

echo "Running auto-fix and validation on PowerShell files..."

# First run auto-fix on all staged PowerShell files
if [ -f "auto-fix.ps1" ]; then
    echo "Using comprehensive auto-fix..."
    pwsh -File "auto-fix.ps1" -Path "."
else
    echo "Using fallback auto-fix..."
    for file in `$PS_FILES; do
        if [ -f "`$file" ]; then
            echo "Auto-fixing: `$file"
            pwsh -File "tools/Validate-PowerShellScripts.ps1" -Path "`$file" -AutoFix -CI
        fi
    done
fi

# Then validate all files
for file in `$PS_FILES; do
    if [ -f "`$file" ]; then
        echo "Validating: `$file"
        pwsh -File "tools/Validate-PowerShellScripts.ps1" -Path "`$file" -CI
        if [ `$? -ne 0 ]; then
            echo "❌ Validation failed for: `$file"
            echo "Please fix the issues and try again."
            echo "Note: Auto-fix was already attempted."
            exit 1
        fi
    fi
done

# Re-stage any auto-fixed files
git add `$PS_FILES

echo "✅ All PowerShell files passed validation."
exit 0
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
    
    # Create a test file with parameter ordering issue
    $testFile = "temp/test-precommit.ps1"
    $testContent = @"
ram([string]`$TestParam)

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
        
Import-Module "SomeModule"
Pa

        # Clean up
        git reset HEAD~1 --soft 2>/dev/null
        git reset HEAD $testFile 2>/dev/null
        
    } finally {
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    }
}

# Main execution
if ($Install) {
    Install-PreCommitHook
} elseif ($Uninstall) {
    Remove-PreCommitHook
} else {
    Write-Host "PowerShell Pre-Commit Hook Manager" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  Install:   .\Pre-Commit-Hook.ps1 -Install" -ForegroundColor Gray
    Write-Host "  Uninstall: .\Pre-Commit-Hook.ps1 -Uninstall" -ForegroundColor Gray
    Write-Host "  Test:      .\Pre-Commit-Hook.ps1 -Test" -ForegroundColor Gray
}


