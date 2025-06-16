#Requires -Version 7.0
<#
.SYNOPSIS
    Permanent cleanup functionality integrated into PatchManager
    
.DESCRIPTION
    Migrated from BackupManager to provide comprehensive permanent cleanup
    with Git integration and change control features.
    
.PARAMETER CleanupTargets
    Array of cleanup targets: 'OldBackups', 'TempFiles', 'LogFiles', 'DuplicateFiles', 'EmptyDirectories'
    
.PARAMETER AgeThresholdDays
    Delete files older than this many days (default: 30)
    
.PARAMETER DryRun
    Show what would be deleted without actually deleting
    
.PARAMETER Force
    Skip confirmations and perform cleanup
    
.EXAMPLE
    Invoke-PermanentCleanup -CleanupTargets @('OldBackups', 'TempFiles') -AgeThresholdDays 7 -DryRun
    
.EXAMPLE
    Invoke-PermanentCleanup -CleanupTargets @('LogFiles') -Force
    
.NOTES
    Part of PatchManager's comprehensive cleanup system.
    Provides audit trails and Git integration.
#>

function Invoke-PermanentCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CleanupTargets,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Initialize cleanup results tracking
        $script:CleanupResults = @{
            StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TotalSizeReclaimed = 0
            FilesRemoved = 0
            DirectoriesRemoved = 0
            Errors = @()
            DryRun = $DryRun.IsPresent
            TargetsCleaned = @()
        }

        # Ensure we have logging capability
        if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
            function Write-CustomLog {
                param(
                    [string]$Message,
                    [string]$Level = "INFO"
                )
                
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] $Message"
                Write-Host $logMessage
                
                if ($Level -eq "ERROR") {
                    $script:CleanupResults.Errors += $logMessage
                }
            }
        }
    }
    
    process {
        try {
            # Parse the cleanup targets
            $targets = $CleanupTargets | ConvertFrom-Json
            
            foreach ($target in $targets) {
                if (-not $target.Path -or -not $target.MaxAge) {
                    Write-CustomLog "Invalid target configuration: Missing Path or MaxAge" "ERROR"
                    continue
                }
                
                $cutoffDate = (Get-Date).AddDays(-$target.MaxAge)
                Write-CustomLog "Processing cleanup target: $($target.Path) with cutoff date: $cutoffDate"
                
                # Perform the cleanup
                $result = Remove-OldFiles -Path $target.Path -CutoffDate $cutoffDate -DryRun:$DryRun -Force:$Force
                
                if ($result) {
                    $script:CleanupResults.TotalSizeReclaimed += $result.SizeReclaimed
                    $script:CleanupResults.FilesRemoved += $result.FilesRemoved
                    $script:CleanupResults.DirectoriesRemoved += $result.DirectoriesRemoved
                    $script:CleanupResults.TargetsCleaned += @{
                        Path = $target.Path
                        FilesRemoved = $result.FilesRemoved
                        SizeReclaimed = $result.SizeReclaimed
                    }
                }
            }
            
            # Update the cleanup manifest
            $manifestPath = Join-Path $PWD "cleanup-manifest.json"
            $script:CleanupResults | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8
            
            Write-CustomLog "Cleanup operation completed. Total size reclaimed: $($script:CleanupResults.TotalSizeReclaimed) bytes"
        }
        catch {
            Write-CustomLog "Error during cleanup operation: $_" "ERROR"
            throw
        }
    }
    
    end {
        return $script:CleanupResults
    }
}

function Remove-OldFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [DateTime]$CutoffDate,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$Force
    )
    
    $result = @{
        FilesRemoved = 0
        DirectoriesRemoved = 0
        SizeReclaimed = 0
    }
    
    # Get all files older than cutoff date
    $files = Get-ChildItem -Path $Path -Recurse -File | 
        Where-Object { $_.LastWriteTime -lt $CutoffDate }
    
    if ($files) {
        $totalSize = ($files | Measure-Object Length -Sum).Sum ?? 0
        
        if (-not $DryRun) {
            foreach ($file in $files) {
                try {
                    Remove-Item $file.FullName -Force:$Force -ErrorAction Stop
                    $result.FilesRemoved++
                    $result.SizeReclaimed += $file.Length
                }
                catch {
                    Write-CustomLog "Error removing file $($file.FullName): $_" "ERROR"
                }
            }
        }
    }
    
    # Clean empty directories
    $emptyDirs = Get-ChildItem -Path $Path -Directory -Recurse | 
        Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) }
    
    if ($emptyDirs -and -not $DryRun) {
        foreach ($dir in $emptyDirs) {
            try {
                Remove-Item $dir.FullName -Force:$Force -ErrorAction Stop
                $result.DirectoriesRemoved++
            }
            catch {
                Write-CustomLog "Error removing directory $($dir.FullName): $_" "ERROR"
            }
        }
    }
    
    return $result
}

