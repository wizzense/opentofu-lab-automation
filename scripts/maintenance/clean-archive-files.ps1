#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/scripts/maintenance/clean-archive-files.ps1

<#
.SYNOPSIS
Clean up broken or unnecessary archive and backup files.

.DESCRIPTION
This script efficiently cleans up broken, redundant, or unnecessary files in the archive and backup directories
to prevent false positives in health checks and validation. It can be run as a standalone utility or
as part of the unified maintenance process.

.PARAMETER Force
Force cleanup without confirmation

.PARAMETER QuietMode
Minimize output to only critical information

.EXAMPLE
./scripts/maintenance/clean-archive-files.ps1 -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$QuietMode
)

$ErrorActionPreference = "Stop"

# Detect the correct project root based on the current environment
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else {
    $ProjectRoot = "/workspaces/opentofu-lab-automation"
}

# Import centralized logging module
try {
    # First try to import the proper logging module
    Import-Module "/pwsh/modules/Logging" -ErrorAction Stop
} catch {
    try {
        # Next try the LabRunner logger
        Import-Module "/pwsh/modules/LabRunner/" -ErrorAction Stop
    } catch {
        # Fallback implementation if module import fails
        function Write-CustomLog {
            param([string]$Message, [string]$Level = "INFO")
            
            if ($QuietMode -and $Level -notin @("ERROR", "SUCCESS", "CRITICAL")) {
                return
            }
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $color = switch ($Level) {
                "INFO" { "Cyan" }
                "SUCCESS" { "Green" }
                "WARNING" { "Yellow" }
                "ERROR" { "Red" }
                "CRITICAL" { "Red" }
                default { "White" }
            }
            Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
        }
    }
}

function Write-CleanupLog {
    param([string]$Message, [string]$Level = "INFO")
    
    # Use standardized logging with fallback already defined
    Write-CustomLog -Message $Message -Level $Level -NoFileOutput:$QuietMode
}

function Initialize-Cleanup {
    Write-CleanupLog "Starting archive cleanup process..." "INFO"
    
    # Create a backup of what we'll clean up
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = "$ProjectRoot/backups/cleanup-$timestamp"
    
    if (-not (Test-Path "$ProjectRoot/backups")) {
        New-Item -ItemType Directory -Path "$ProjectRoot/backups" -Force | Out-Null
    }
    
    return $backupDir
}

function Remove-ArchiveDirectory {
    param(
        [string]$backupDir
    )
    
    $archiveDir = "$ProjectRoot/archive"
    if (-not (Test-Path $archiveDir)) {
        Write-CleanupLog "Archive directory not found, nothing to clean" "INFO"
        return 0
    }
    
    # Patterns of problematic directories/files
    $patterns = @(
        "broken-syntax-files-backup-*",
        "emergency-*",
        "cleanup-*", 
        "comprehensive-*",
        "*-deprecated-*",
        "*-broken-*",
        "*-corrupted-*",
        "*-excess-*",
        "*-20*" # Date-stamped backup directories
    )
    
    $removedCount = 0
    
    foreach ($pattern in $patterns) {
        Write-CleanupLog "Checking for pattern: $pattern" "INFO"
        
        # Find matching directories
        $dirs = Get-ChildItem -Path $archiveDir -Directory -Filter $pattern -ErrorAction SilentlyContinue
        
        # Find matching files
        $files = Get-ChildItem -Path $archiveDir -File -Filter $pattern -ErrorAction SilentlyContinue
        
        # Process directories
        foreach ($dir in $dirs) {
            Write-CleanupLog "Found broken archive directory: $($dir.Name)" "INFO"
            
            try {
                # Create backup if needed
                if (-not $Force) {
                    $backupPath = Join-Path $backupDir $dir.Name
                    Write-CleanupLog "Backing up to $backupPath before removal" "INFO"
                    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
                    Copy-Item -Path "$($dir.FullName)/*" -Destination $backupPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                
                # Delete the directory
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
                Write-CleanupLog "Removed directory: $($dir.Name)" "SUCCESS"
                $removedCount++
            }
            catch {
                Write-CleanupLog "Failed to remove $($dir.Name): $_" "ERROR"
            }
        }
        
        # Process files
        foreach ($file in $files) {
            Write-CleanupLog "Found broken archive file: $($file.Name)" "INFO"
            
            try {
                # Create backup if needed
                if (-not $Force) {
                    $backupFilePath = Join-Path $backupDir $file.Name
                    Copy-Item -Path $file.FullName -Destination $backupFilePath -Force -ErrorAction SilentlyContinue
                }
                
                # Delete the file
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-CleanupLog "Removed file: $($file.Name)" "SUCCESS"
                $removedCount++
            }
            catch {
                Write-CleanupLog "Failed to remove $($file.Name): $_" "ERROR"
            }
        }
    }
    
    return $removedCount
}

function Remove-BackupsDirectory {
    param(
        [string]$backupDir
    )
    
    $backupsMainDir = "$ProjectRoot/backups"
    if (-not (Test-Path $backupsMainDir)) {
        Write-CleanupLog "Backups directory not found, nothing to clean" "INFO"
        return 0
    }
    
    # Keep only the 5 most recent backup directories
    $oldBackups = Get-ChildItem -Path $backupsMainDir -Directory |
        Where-Object { $_.Name -match '^(cleanup|backup)-\d{8}-\d{6}$' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -Skip 5
    
    $removedCount = 0
    
    foreach ($oldBackup in $oldBackups) {
        Write-CleanupLog "Removing old backup: $($oldBackup.Name)" "INFO"
        
        try {
            Remove-Item -Path $oldBackup.FullName -Recurse -Force -ErrorAction Stop
            Write-CleanupLog "Removed old backup: $($oldBackup.Name)" "SUCCESS"
            $removedCount++
        }
        catch {
            Write-CleanupLog "Failed to remove $($oldBackup.Name): $_" "ERROR"
        }
    }
    
    return $removedCount
}

# Main execution flow
try {
    $backupDir = Initialize-Cleanup
      $archiveCount = Remove-ArchiveDirectory -backupDir $backupDir
    $backupsCount = Remove-BackupsDirectory -backupDir $backupDir
    
    # Remove empty backup directory if nothing was backed up
    if ((Get-ChildItem $backupDir -Recurse).Count -eq 0) {
        Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    $totalRemoved = $archiveCount + $backupsCount
    Write-CleanupLog "Archive cleanup completed. Removed $totalRemoved problematic items." "SUCCESS"
    
    # Return the count for calling scripts
    return $totalRemoved
}
catch {
    Write-CleanupLog "Archive cleanup failed: $_" "ERROR"
    return 0
}
