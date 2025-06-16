# Cleanup-DeprecatedFiles.ps1
# Script to clean up deprecated files after CodeFixer module integration
CmdletBinding()
param(
    switch$Force,
    switch$SkipBackup,
    switch$WhatIf
)








$ErrorActionPreference = 'Stop'

# Helper function to backup files before removing them
function Backup-Files {
    param(
        string$FilePaths
    )

    






if ($SkipBackup) {
        return
    }

    $backupDir = Join-Path $PSScriptRoot ".." "backups" "deprecated" (Get-Date -Format "yyyyMMdd-HHmmss")
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null}

    foreach ($filePath in $FilePaths) {
        if (Test-Path $filePath) {
            $fileName = Split-Path -Path $filePath -Leaf
            $backupPath = Join-Path $backupDir $fileName

            try {
                Copy-Item -Path $filePath -Destination $backupPath -Force
                Write-Host "Backed up $filePath to $backupPath" -ForegroundColor Cyan
            }
            catch {
                Write-Warning "Failed to back up $filePath`: $_"
            }
        }
    }
}

function Remove-DeprecatedFiles {
    param(
        string$FilePaths,
        switch$WhatIf
    )

    






# Backup files before removing
    if (-not $WhatIf) {
        Backup-Files -FilePaths $FilePaths
    }

    foreach ($filePath in $FilePaths) {
        if (Test-Path $filePath) {
            if ($WhatIf) {
                Write-Host "What if: Would remove file $filePath" -ForegroundColor Yellow
            }
            else {
                Remove-Item -Path $filePath -Force
                Write-Host "Removed deprecated file: $filePath" -ForegroundColor Green
            }
        }
        else {
            Write-Host "File already removed or does not exist: $filePath" -ForegroundColor Gray
        }
    }
}

function Move-ToArchive {
    param(
        string$FilePaths,
        switch$WhatIf
    )

    






$archiveDir = Join-Path $PSScriptRoot ".." "archive" "deprecated"
    if (-not (Test-Path $archiveDir)) {
        if ($WhatIf) {
            Write-Host "What if: Would create archive directory: $archiveDir" -ForegroundColor Yellow
        }
        else {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
Write-Host "Created archive directory: $archiveDir" -ForegroundColor Cyan
        }
    }

    foreach ($filePath in $FilePaths) {
        if (Test-Path $filePath) {
            $fileName = Split-Path -Path $filePath -Leaf
            $archivePath = Join-Path $archiveDir $fileName

            if ($WhatIf) {
                Write-Host "What if: Would move $filePath to $archivePath" -ForegroundColor Yellow
            }
            else {
                Move-Item -Path $filePath -Destination $archivePath -Force
                Write-Host "Moved file to archive: $filePath -> $archivePath" -ForegroundColor Green
            }
        }
        else {
            Write-Host "File not found for archiving: $filePath" -ForegroundColor Gray
        }
    }
}

function Update-ReadmeFile {
    param(
        string$FilePath,
        switch$WhatIf
    )

    






if (-not (Test-Path $FilePath)) {
        Write-Warning "README file not found at $FilePath"
        return
    }

    $content = Get-Content -Path $FilePath -Raw
    
    $updateSection = @'

## Testing Framework

The OpenTofu Lab Automation project includes a comprehensive testing and validation framework based on the CodeFixer PowerShell module.

### Key Components

- **CodeFixer Module** - Located in `pwsh/modules/CodeFixer/`, provides automated tools for:
  - Fixing common syntax errors in PowerShell scripts
  - Auto-generating tests for PowerShell scripts
  - Running linting and validation checks
  - Analyzing and reporting on test results

### Available Scripts

- `invoke-comprehensive-validation.ps1` - Runs full validation suite with optional fixes
- `auto-fix.ps1` - Runs all available fixers in sequence
- `comprehensive-lint.ps1` - Runs and reports on PowerShell linting
- `comprehensive-health-check.ps1` - Performs system health checks

For more information, see TESTING.md(docs/TESTING.md)
'@

    if ($content -notmatch 'CodeFixer Module') {
        # Find a good place to add the testing framework section
        if ($content -match '## Project Structure') {
            $content = $content -replace '(## Project Structure.*?)(\n+##\n*$)', "`$1$updateSection`$2"
        }
        elseif ($content -match '## Getting Started') {
            $content = $content -replace '(## Getting Started.*?)(\n+##\n*$)', "`$1$updateSection`$2"
        }
        else {
            # Append to the end
            $content = "$content`n$updateSection"
        }

        if ($WhatIf) {
            Write-Host "What if: Would update README file with testing framework information" -ForegroundColor Yellow
        }
        else {
            Set-Content -Path $FilePath -Value $content -Force
            Write-Host "Updated README file with testing framework information" -ForegroundColor Green
        }
    }
    else {
        Write-Host "README file already contains testing framework information" -ForegroundColor Yellow
    }
}

# Main script execution
try {
    $rootDir = Join-Path $PSScriptRoot ".."
    $readmePath = Join-Path $rootDir "README.md"

    # Files to remove (fully replaced by CodeFixer module)
    $filesToRemove = @(
        "fix-ternary-syntax.ps1",
        "fix-test-formatting.ps1"
    ) | ForEach-Object{ Join-Path $rootDir $_ }

    # Files to move to archive (deprecated but kept for reference)
    $filesToArchive = @(
        "fix-bootstrap-script.ps1",
        "fix-runtime-execution-simple.ps1",
        "fix-test-syntax-errors.ps1",
        "test-bootstrap-fixes.py",
        "test-bootstrap-syntax.py",
        "validate-syntax.py"
    ) | ForEach-Object{ Join-Path $rootDir $_ }

    Write-Host "Starting cleanup of deprecated files..." -ForegroundColor Cyan

    # Remove fully deprecated files
    Write-Host "`nRemaining following files (fully replaced by CodeFixer module):" -ForegroundColor Magenta
    Remove-DeprecatedFiles -FilePaths $filesToRemove -WhatIf:$WhatIf

    # Move deprecated files to archive
    Write-Host "`nArchiving following files (deprecated but kept for reference):" -ForegroundColor Magenta
    Move-ToArchive -FilePaths $filesToArchive -WhatIf:$WhatIf

    # Update README with testing framework information
    Write-Host "`nUpdating README file with testing framework information..." -ForegroundColor Cyan
    Update-ReadmeFile -FilePath $readmePath -WhatIf:$WhatIf

    if ($WhatIf) {
        Write-Host "`nThis was a dry run. To actually perform these operations, run without -WhatIf parameter." -ForegroundColor Yellow
    }
    else {
        Write-Host "`nCleanup completed successfully!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "Cleanup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
    exit 1
}





