#Requires -Version 7.0

<#
.SYNOPSIS
    Permanent cleanup functionality integrated into PatchManager

.DESCRIPTION
    Provides comprehensive cleanup capabilities for removing problematic files,
    duplicate backups, and other maintenance tasks with detailed logging and rollback support.

.PARAMETER CleanupTargets
    JSON string containing cleanup target configuration

.PARAMETER DryRun
    If specified, performs a dry run without actually removing files

.PARAMETER Force
    If specified, forces removal of read-only files

.EXAMPLE
    $targets = @(
        @{ Path = "backup/*"; MaxAge = 30; Pattern = "*.bak" }
    ) | ConvertTo-Json
    Invoke-PermanentCleanup -CleanupTargets $targets

.NOTES
    This function integrates with the centralized logging system
#>

function Invoke-PermanentCleanup {
    [CmdletBinding(SupportsShouldProcess)]
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
            Success = $true
            StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TotalSizeReclaimed = 0
            FilesRemoved = 0
            DirectoriesRemoved = 0
            Errors = @()
            DryRun = $DryRun.IsPresent
            TargetsCleaned = @()
        }
        
        Write-CustomLog "Starting permanent cleanup process" "INFO"
    }
    
    process {
        try {
            # Parse the cleanup targets
            $targets = $CleanupTargets | ConvertFrom-Json
            
            foreach ($target in $targets) {
                if (-not $target.Path -or -not $target.MaxAge) {
                    Write-CustomLog "Invalid target configuration: Missing Path or MaxAge" "ERROR"
                    $script:CleanupResults.Errors += "Invalid target configuration"
                    continue
                }
                
                $cutoffDate = (Get-Date).AddDays(-$target.MaxAge)
                Write-CustomLog "Processing cleanup target: $($target.Path), MaxAge: $($target.MaxAge) days" "INFO"
                
                if (Test-Path $target.Path) {
                    $cleanupResult = Remove-OldFiles -Path $target.Path -CutoffDate $cutoffDate -DryRun:$DryRun -Force:$Force
                    
                    $script:CleanupResults.FilesRemoved += $cleanupResult.FilesRemoved
                    $script:CleanupResults.DirectoriesRemoved += $cleanupResult.DirectoriesRemoved
                    $script:CleanupResults.TotalSizeReclaimed += $cleanupResult.SizeReclaimed
                    $script:CleanupResults.TargetsCleaned += $target.Path
                    
                    Write-CustomLog "Cleaned $($cleanupResult.FilesRemoved) files, $($cleanupResult.DirectoriesRemoved) directories from $($target.Path)" "SUCCESS"
                } else {
                    Write-CustomLog "Target path does not exist: $($target.Path)" "WARN"
                }
            }
            
            # Generate cleanup manifest
            $manifestPath = Join-Path $env:PROJECT_ROOT "cleanup-manifest-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            if (-not $DryRun) {
                $script:CleanupResults | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8
            }
            
            Write-CustomLog "Cleanup operation completed. Total size reclaimed: $($script:CleanupResults.TotalSizeReclaimed) bytes" "SUCCESS"
        }
        catch {
            Write-CustomLog "Error during cleanup operation: $_" "ERROR"
            $script:CleanupResults.Success = $false
            $script:CleanupResults.Errors += $_.Exception.Message
            throw
        }
    }
    
    end {
        return $script:CleanupResults
    }
}


