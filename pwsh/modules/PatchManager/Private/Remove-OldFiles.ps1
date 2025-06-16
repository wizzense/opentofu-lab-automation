#Requires -Version 7.0

<#
.SYNOPSIS
Private function to remove old files and directories

.DESCRIPTION
Helper function for cleanup operations that removes files older than a cutoff date
and cleans up empty directories.

.PARAMETER Path
The path to scan for old files

.PARAMETER CutoffDate
Files older than this date will be removed

.PARAMETER DryRun
If specified, only simulates the cleanup without actually removing files

.PARAMETER Force
If specified, forces removal of read-only files
#>

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
    
    if (-not (Test-Path $Path)) {
        Write-CustomLog "Path does not exist: $Path" "WARN"
        return $result
    }
    
    # Get all files older than cutoff date
    $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
             Where-Object { $_.LastWriteTime -lt $CutoffDate }
    
    if ($files) {
        $totalSize = ($files | Measure-Object Length -Sum).Sum
        if (-not $totalSize) { $totalSize = 0 }
        
        Write-CustomLog "Found $($files.Count) old files (total size: $totalSize bytes)" "INFO"
        
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
        } else {
            Write-CustomLog "DRY RUN: Would remove $($files.Count) files" "INFO"
            $result.FilesRemoved = $files.Count
            $result.SizeReclaimed = $totalSize
        }
    }
    
    # Clean empty directories
    $emptyDirs = Get-ChildItem -Path $Path -Directory -Recurse -ErrorAction SilentlyContinue | 
                 Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) }
    
    if ($emptyDirs) {
        Write-CustomLog "Found $($emptyDirs.Count) empty directories" "INFO"
        
        if (-not $DryRun) {
            foreach ($dir in $emptyDirs) {
                try {
                    Remove-Item $dir.FullName -Force:$Force -ErrorAction Stop
                    $result.DirectoriesRemoved++
                }
                catch {
                    Write-CustomLog "Error removing directory $($dir.FullName): $_" "ERROR"
                }
            }
        } else {
            Write-CustomLog "DRY RUN: Would remove $($emptyDirs.Count) empty directories" "INFO"
            $result.DirectoriesRemoved = $emptyDirs.Count
        }
    }
    
    return $result
}
