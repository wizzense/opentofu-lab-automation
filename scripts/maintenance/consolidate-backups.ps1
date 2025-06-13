# /workspaces/opentofu-lab-automation/scripts/maintenance/consolidate-backups.ps1

<#
.SYNOPSIS
    Consolidates all backup files into a single organized directory structure
    and cleans up duplicate/legacy module directories.

.DESCRIPTION
    This script performs comprehensive backup consolidation and cleanup:
    - Moves all *.backup* files to /backups/consolidated-backups/
    - Organizes by date and source directory
    - Removes duplicate LabRunner directory (keeps /pwsh/modules/LabRunner)
    - Archives legacy module structures
    - Creates cleanup report

.PARAMETER DryRun
    Show what would be done without making changes

.PARAMETER AutoArchive
    Automatically archive instead of delete legacy directories

.EXAMPLE
    ./scripts/maintenance/consolidate-backups.ps1 -DryRun
    ./scripts/maintenance/consolidate-backups.ps1 -AutoArchive
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$AutoArchive
)








# Initialize logging
$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = "/workspaces/opentofu-lab-automation/docs/reports/project-status"
$reportFile = "$reportPath/$timestamp-backup-consolidation.md"

# Ensure report directory exists
if (-not (Test-Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param($Message, $Level = "INFO")
    






$logMessage = "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Write-Host $logMessage
    Add-Content -Path $reportFile -Value $logMessage
}

function Initialize-Report {
    $reportContent = @"
# Backup Consolidation Report
**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Mode**: $$(if (DryRun) { "Dry Run" } else { "Live Execution" })

## Summary
This report documents the consolidation of backup files and cleanup of duplicate directories.

## Actions Performed

"@
    Set-Content -Path $reportFile -Value $reportContent
}

function Get-BackupFiles {
    Write-Log "Scanning for backup files..."
    $backupFiles = Get-ChildItem -Path "/workspaces/opentofu-lab-automation" -Recurse -Filter "*.backup*" -File
    Write-Log "Found $($backupFiles.Count) backup files"
    return $backupFiles
}

function Get-BackupDestination {
    param($SourceFile)
    
    






$relativePath = $SourceFile.FullName.Replace("/workspaces/opentofu-lab-automation/", "")
    $pathParts = $relativePath.Split("/")
    
    # Extract date from filename if present
    if ($SourceFile.Name -match "(\d{8})-(\d{6})") {
        $dateStr = $matches[1]
    } elseif ($SourceFile.Name -match "(\d{4})(\d{2})(\d{2})") {
        $dateStr = $matches[0]
    } else {
        $dateStr = "undated"
    }
    
    # Organize by source directory and date
    $sourceDir = $pathParts[0]
    $destDir = "/workspaces/opentofu-lab-automation/backups/consolidated-backups/$dateStr/$sourceDir"
    
    return $destDir
}

function Move-BackupFiles {
    param($BackupFiles)
    
    






Write-Log "Starting backup file consolidation..."
    $moved = 0
    $errors = 0
    
    foreach ($file in $BackupFiles) {
        try {
            $destDir = Get-BackupDestination -SourceFile $file
            $destPath = Join-Path $destDir $file.Name
            
            Write-Log "Moving: $($file.FullName) -> $destPath"
            
            if (-not $DryRun) {
                if (-not (Test-Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }
                Move-Item -Path $file.FullName -Destination $destPath -Force
            }
            $moved++
        }
        catch {
            Write-Log "ERROR moving $($file.FullName): $_" -Level "ERROR"
            $errors++
        }
    }
    
    Write-Log "Backup consolidation complete: $moved moved, $errors errors"
    return @{ Moved = $moved; Errors = $errors }
}

function Test-DirectoryEmpty {
    param($Path)
    
    






if (-not (Test-Path $Path)) { return $true }
    $items = Get-ChildItem -Path $Path -Force
    return $items.Count -eq 0
}

function Remove-EmptyDirectories {
    Write-Log "Cleaning up empty directories..."
    
    $searchPaths = @(
        "/workspaces/opentofu-lab-automation/pwsh",
        "/workspaces/opentofu-lab-automation/archive"
    )
    
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {
            Get-ChildItem -Path $searchPath -Recurse -Directory | 
                Sort-Object FullName -Descending |
                Where-Object { Test-DirectoryEmpty $_.FullName } |
                ForEach-Object {
                    Write-Log "Removing empty directory: $($_.FullName)"
                    if (-not $DryRun) {
                        Remove-Item -Path $_.FullName -Force
                    }
                }
        }
    }
}

function Cleanup-LegacyLabRunner {
    Write-Log "Analyzing LabRunner directories..."
    
    $legacyLabRunner = "/workspaces/opentofu-lab-automation/LabRunner"
    $modernLabRunner = "/workspaces/opentofu-lab-automation/pwsh/modules/LabRunner"
    
    if (Test-Path $legacyLabRunner) {
        Write-Log "Found legacy LabRunner directory at root level"
        
        if (Test-Path $modernLabRunner) {
            Write-Log "Modern LabRunner module exists - safe to archive legacy version"
            
            $archivePath = "/workspaces/opentofu-lab-automation/archive/legacy-modules/LabRunner-root-$timestamp"
            
            if ($AutoArchive) {
                Write-Log "Archiving legacy LabRunner: $legacyLabRunner -> $archivePath"
                if (-not $DryRun) {
                    if (-not (Test-Path (Split-Path $archivePath))) {
                        New-Item -Path (Split-Path $archivePath) -ItemType Directory -Force | Out-Null
                    }
                    Move-Item -Path $legacyLabRunner -Destination $archivePath -Force
                }
            } else {
                Write-Log "Legacy LabRunner found but AutoArchive not specified. Use -AutoArchive to move to archive."
            }
        } else {
            Write-Log "WARNING: Legacy LabRunner exists but modern version not found!" -Level "WARNING"
        }
    } else {
        Write-Log "No legacy LabRunner directory found"
    }
}

function Update-GitIgnore {
    Write-Log "Updating .gitignore for backup directories..."
    
    $gitignorePath = "/workspaces/opentofu-lab-automation/.gitignore"
    $backupEntries = @(
        "# Backup directories",
        "backups/",
        "*.backup*",
        "archive/legacy-modules/",
        ""
    )
    
    if (Test-Path $gitignorePath) {
        $content = Get-Content $gitignorePath -Raw
        $needsUpdate = $false
        
        foreach ($entry in $backupEntries) {
            if ($entry -and $content -notmatch [regex]::Escape($entry)) {
                $needsUpdate = $true
                break
            }
        }
        
        if ($needsUpdate -and -not $DryRun) {
            Write-Log "Adding backup entries to .gitignore"
            Add-Content -Path $gitignorePath -Value "`n$($backupEntries -join "`n")"
        }
    }
}

function Finalize-Report {
    $finalContent = @"

## Final Status
- **Backup files processed**: $$(if (script:backupStats) { $script:backupStats.Moved } else { "N/A" })
- **Errors encountered**: $$(if (script:backupStats) { $script:backupStats.Errors } else { "N/A" })
- **Empty directories cleaned**: Multiple
- **Legacy LabRunner**: $$(if (AutoArchive) { "Archived" } else { "Detected but not archived" })

## Recommendations
1. Verify backup consolidation in `/backups/consolidated-backups/`
2. Update build scripts to use new module locations
3. Consider hiding backup directories from main project views
4. Run validation to ensure no broken references

## Next Steps
- Run comprehensive validation: `./run-final-validation.ps1`
- Update documentation with new structure
- Consider implementing backup retention policies

---
**Report completed**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    Add-Content -Path $reportFile -Value $finalContent
    Write-Log "Report saved to: $reportFile"
}

# Main execution
try {
    Initialize-Report
    Write-Log "Starting backup consolidation process"
    
    # Get all backup files
    $backupFiles = Get-BackupFiles
    
    if ($backupFiles.Count -eq 0) {
        Write-Log "No backup files found to consolidate"
    } else {
        # Move backup files
        $script:backupStats = Move-BackupFiles -BackupFiles $backupFiles
    }
    
    # Clean up empty directories
    Remove-EmptyDirectories
    
    # Handle legacy LabRunner
    Cleanup-LegacyLabRunner
    
    # Update gitignore
    Update-GitIgnore
    
    Write-Log "Backup consolidation completed successfully"
    
} catch {
    Write-Log "FATAL ERROR: $_" -Level "ERROR"
    throw
} finally {
    Finalize-Report
}



