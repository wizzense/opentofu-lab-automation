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
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('OldBackups', 'TempFiles', 'LogFiles', 'DuplicateFiles', 'EmptyDirectories', 'All')]
        [string[]]$CleanupTargets,
        
        [Parameter(Mandatory = $false)]
        [int]$AgeThresholdDays = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    begin {
        $ErrorActionPreference = "Stop"
        
        # Initialize cleanup tracking
        $script:CleanupResults = @{
            StartTime = Get-Date
            Targets = $CleanupTargets
            AgeThreshold = $AgeThresholdDays
            DryRun = $DryRun
            Operations = @()
            FilesDeleted = 0
            SpaceSaved = 0
            Errors = @()
        }
        
        # Logging function
        if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
            function Write-CustomLog {
                param([string]$Message, [string]$Level = "INFO")
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $color = switch ($Level) {
                    "ERROR" { "Red" }
                    "WARN" { "Yellow" }
                    "INFO" { "Green" }
                    "DEBUG" { "Cyan" }
                    default { "White" }
                }
                Write-Host "[$timestamp] [PatchManager] [$Level] $Message" -ForegroundColor $color
            }
        }
        
        # Define cleanup patterns
        $script:CleanupPatterns = @{
            TempFiles = @("*.tmp", "*.temp", "*.cache", "*.lock", "*~")
            LogFiles = @("*.log", "*.log.*", "logs/*.log")
            OldBackups = @("*.bak", "*.old", "*.orig", "*backup*", "backups/*")
            DuplicateFiles = @("*copy*", "*duplicate*", "*(1)*", "*(2)*")
        }
    }
    
    process {
        try {
            Write-CustomLog "Starting PatchManager permanent cleanup" "INFO"
            Write-CustomLog "Targets: $($CleanupTargets -join ', ')" "INFO"
            Write-CustomLog "Age threshold: $AgeThresholdDays days" "INFO"
            
            if ($DryRun) {
                Write-CustomLog "DRY RUN MODE - No files will be deleted" "WARN"
            }
            
            $cutoffDate = (Get-Date).AddDays(-$AgeThresholdDays)
            $totalFilesFound = 0
            $totalSizeFound = 0
            
            # Process each cleanup target
            foreach ($target in $CleanupTargets) {
                if ($target -eq 'All') {
                    $actualTargets = @('OldBackups', 'TempFiles', 'LogFiles', 'DuplicateFiles', 'EmptyDirectories')
                } else {
                    $actualTargets = @($target)
                }
                
                foreach ($actualTarget in $actualTargets) {
                    Write-CustomLog "Processing cleanup target: $actualTarget" "INFO"
                    
                    $targetResult = switch ($actualTarget) {
                        'OldBackups' { 
                            Invoke-OldBackupCleanup -CutoffDate $cutoffDate -DryRun:$DryRun -Force:$Force
                        }
                        'TempFiles' { 
                            Invoke-TempFileCleanup -CutoffDate $cutoffDate -DryRun:$DryRun -Force:$Force
                        }
                        'LogFiles' { 
                            Invoke-LogFileCleanup -CutoffDate $cutoffDate -DryRun:$DryRun -Force:$Force
                        }
                        'DuplicateFiles' { 
                            Invoke-DuplicateFileCleanup -DryRun:$DryRun -Force:$Force
                        }
                        'EmptyDirectories' { 
                            Invoke-EmptyDirectoryCleanup -DryRun:$DryRun -Force:$Force
                        }
                    }
                    
                    $script:CleanupResults.Operations += $targetResult
                    $totalFilesFound += $targetResult.FilesFound
                    $totalSizeFound += $targetResult.SizeFound
                    
                    if (-not $DryRun) {
                        $script:CleanupResults.FilesDeleted += $targetResult.FilesDeleted
                        $script:CleanupResults.SpaceSaved += $targetResult.SpaceFreed
                    }
                }
            }
            
            # Summary
            $sizeMB = [math]::Round($totalSizeFound / 1MB, 2)
            if ($DryRun) {
                Write-CustomLog "DRY RUN SUMMARY: Found $totalFilesFound files ($sizeMB MB) that would be deleted" "INFO"
            } else {
                $freedMB = [math]::Round($script:CleanupResults.SpaceSaved / 1MB, 2)
                Write-CustomLog "CLEANUP SUMMARY: Deleted $($script:CleanupResults.FilesDeleted) files ($freedMB MB freed)" "INFO"
            }
            
            # Create cleanup manifest
            $script:CleanupResults.EndTime = Get-Date
            $script:CleanupResults.Duration = $script:CleanupResults.EndTime - $script:CleanupResults.StartTime
            
            $manifestPath = "cleanup-manifest-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            $script:CleanupResults | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8
            Write-CustomLog "Created cleanup manifest: $manifestPath" "INFO"
            
            return $script:CleanupResults
            
        } catch {
            Write-CustomLog "Fatal error during permanent cleanup: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

# Helper functions for specific cleanup operations
function Invoke-OldBackupCleanup {
    param($CutoffDate, [switch]$DryRun, [switch]$Force)
    
    $patterns = $script:CleanupPatterns.OldBackups
    $files = @()
    
    foreach ($pattern in $patterns) {
        $foundFiles = Get-ChildItem -Path "." -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $CutoffDate }
        $files += $foundFiles
    }
    
    $totalSize = ($files | Measure-Object Length -Sum).Sum ?? 0
    
    if (-not $DryRun -and $files.Count -gt 0) {
        if (-not $Force) {
            $confirmation = Read-Host "Delete $($files.Count) old backup files? (y/N)"
            if ($confirmation -notmatch '^[Yy]') {
                Write-CustomLog "Skipped old backup cleanup" "INFO"
                return @{ Target = "OldBackups"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
            }
        }
        
        $deleted = 0
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force
                $deleted++
            } catch {
                Write-CustomLog "Failed to delete $($file.FullName): $($_.Exception.Message)" "WARN"
            }
        }
        
        return @{ Target = "OldBackups"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = $deleted; SpaceFreed = $totalSize }
    }
    
    return @{ Target = "OldBackups"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
}

function Invoke-TempFileCleanup {
    param($CutoffDate, [switch]$DryRun, [switch]$Force)
    
    $patterns = $script:CleanupPatterns.TempFiles
    $files = @()
    
    foreach ($pattern in $patterns) {
        $foundFiles = Get-ChildItem -Path "." -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $CutoffDate }
        $files += $foundFiles
    }
    
    $totalSize = ($files | Measure-Object Length -Sum).Sum ?? 0
    
    if (-not $DryRun -and $files.Count -gt 0) {
        $deleted = 0
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force
                $deleted++
            } catch {
                Write-CustomLog "Failed to delete $($file.FullName): $($_.Exception.Message)" "WARN"
            }
        }
        
        return @{ Target = "TempFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = $deleted; SpaceFreed = $totalSize }
    }
    
    return @{ Target = "TempFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
}

function Invoke-LogFileCleanup {
    param($CutoffDate, [switch]$DryRun, [switch]$Force)
    
    $patterns = $script:CleanupPatterns.LogFiles
    $files = @()
    
    foreach ($pattern in $patterns) {
        $foundFiles = Get-ChildItem -Path "." -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $CutoffDate }
        $files += $foundFiles
    }
    
    $totalSize = ($files | Measure-Object Length -Sum).Sum ?? 0
    
    if (-not $DryRun -and $files.Count -gt 0) {
        if (-not $Force) {
            $confirmation = Read-Host "Delete $($files.Count) old log files? (y/N)"
            if ($confirmation -notmatch '^[Yy]') {
                Write-CustomLog "Skipped log file cleanup" "INFO"
                return @{ Target = "LogFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
            }
        }
        
        $deleted = 0
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force
                $deleted++
            } catch {
                Write-CustomLog "Failed to delete $($file.FullName): $($_.Exception.Message)" "WARN"
            }
        }
        
        return @{ Target = "LogFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = $deleted; SpaceFreed = $totalSize }
    }
    
    return @{ Target = "LogFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
}

function Invoke-DuplicateFileCleanup {
    param([switch]$DryRun, [switch]$Force)
    
    # Simple duplicate detection by name patterns
    $patterns = $script:CleanupPatterns.DuplicateFiles
    $files = @()
    
    foreach ($pattern in $patterns) {
        $foundFiles = Get-ChildItem -Path "." -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue
        $files += $foundFiles
    }
    
    $totalSize = ($files | Measure-Object Length -Sum).Sum ?? 0
    
    if (-not $DryRun -and $files.Count -gt 0) {
        if (-not $Force) {
            $confirmation = Read-Host "Delete $($files.Count) potential duplicate files? (y/N)"
            if ($confirmation -notmatch '^[Yy]') {
                Write-CustomLog "Skipped duplicate file cleanup" "INFO"
                return @{ Target = "DuplicateFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
            }
        }
        
        $deleted = 0
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force
                $deleted++
            } catch {
                Write-CustomLog "Failed to delete $($file.FullName): $($_.Exception.Message)" "WARN"
            }
        }
        
        return @{ Target = "DuplicateFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = $deleted; SpaceFreed = $totalSize }
    }
    
    return @{ Target = "DuplicateFiles"; FilesFound = $files.Count; SizeFound = $totalSize; FilesDeleted = 0; SpaceFreed = 0 }
}

function Invoke-EmptyDirectoryCleanup {
    param([switch]$DryRun, [switch]$Force)
    
    $emptyDirs = Get-ChildItem -Path "." -Recurse -Directory | 
        Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) }
    
    if (-not $DryRun -and $emptyDirs.Count -gt 0) {
        if (-not $Force) {
            $confirmation = Read-Host "Delete $($emptyDirs.Count) empty directories? (y/N)"
            if ($confirmation -notmatch '^[Yy]') {
                Write-CustomLog "Skipped empty directory cleanup" "INFO"
                return @{ Target = "EmptyDirectories"; FilesFound = $emptyDirs.Count; SizeFound = 0; FilesDeleted = 0; SpaceFreed = 0 }
            }
        }
        
        $deleted = 0
        foreach ($dir in $emptyDirs) {
            try {
                Remove-Item $dir.FullName -Force
                $deleted++
            } catch {
                Write-CustomLog "Failed to delete $($dir.FullName): $($_.Exception.Message)" "WARN"
            }
        }
        
        return @{ Target = "EmptyDirectories"; FilesFound = $emptyDirs.Count; SizeFound = 0; FilesDeleted = $deleted; SpaceFreed = 0 }
    }
    
    return @{ Target = "EmptyDirectories"; FilesFound = $emptyDirs.Count; SizeFound = 0; FilesDeleted = 0; SpaceFreed = 0 }
}
