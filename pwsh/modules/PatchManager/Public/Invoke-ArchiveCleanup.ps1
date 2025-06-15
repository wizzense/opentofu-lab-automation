function Invoke-ArchiveCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,
        
        [Parameter(Mandatory=$false)]
        [switch]$PreserveCritical,
        
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-CleanupLog {
        param (
            [string]$Message,
            [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [$Level] $Message"
        
        # Color coding based on level
        switch ($Level) {
            "INFO"    { Write-Host $formattedMessage -ForegroundColor Gray }
            "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
            "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
            "ERROR"   { Write-Host $formattedMessage -ForegroundColor Red }
            "DEBUG"   { Write-Host $formattedMessage -ForegroundColor DarkGray }
        }
    }
    
    Write-CleanupLog "Starting archive cleanup for $ProjectRoot..." "INFO"
    
    # Known archive directories to clean up
    $archiveDirs = @(
        "$ProjectRoot/archive/broken-syntax-files",
        "$ProjectRoot/archive/broken-syntax-files-*",
        "$ProjectRoot/archive/broken-workflows-*",
        "$ProjectRoot/archive/cleanup-*",
        "$ProjectRoot/archive/duplicate-labrunner-*",
        "$ProjectRoot/archive/excess-installers-*",
        "$ProjectRoot/archive/excess-readme-files-*",
        "$ProjectRoot/archive/root-fix-scripts-*",
        "$ProjectRoot/archive/summary-files-*"
    )
    
    # Critical directories to preserve (if -PreserveCritical is set)
    $criticalDirs = @(
        "$ProjectRoot/archive/working-workflows-*"
    )
    
    # Stage 1: Count files to ensure we have something to work with
    $matchingDirs = @()
    foreach ($pattern in $archiveDirs) {
        $dirs = Get-Item -Path $pattern -ErrorAction SilentlyContinue
        if ($dirs) {
            $matchingDirs += $dirs
        }
    }
    
    if ($matchingDirs.Count -eq 0) {
        Write-CleanupLog "No archive directories found to clean up" "INFO"
        return
    }
    
    Write-CleanupLog "Found $($matchingDirs.Count) archive directories to process" "INFO"
    
    # Stage 2: Move critical files to backups directory if needed
    if ($PreserveCritical) {
        $backupDir = "$ProjectRoot/backups/consolidated-backups/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $null = New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction SilentlyContinue
        
        foreach ($pattern in $criticalDirs) {
            $dirs = Get-Item -Path $pattern -ErrorAction SilentlyContinue
            if ($dirs) {
                foreach ($dir in $dirs) {
                    $targetDir = Join-Path $backupDir (Split-Path $dir -Leaf)
                    if ($WhatIf) {
                        Write-CleanupLog "WhatIf: Would copy $($dir.FullName) to $targetDir" "INFO"
                    }
                    else {
                        Write-CleanupLog "Backing up critical directory $($dir.Name)..." "INFO"
                        $null = Copy-Item -Path $dir -Destination $targetDir -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }
    
    # Stage 3: Clean up archive directories
    $removed = 0
    $errors = 0
    
    foreach ($dir in $matchingDirs) {
        try {
            if ($PreserveCritical) {
                # Skip critical directories
                $isCritical = $false
                foreach ($pattern in $criticalDirs) {
                    if ($dir -like $pattern) {
                        $isCritical = $true
                        break
                    }
                }
                
                if ($isCritical) {
                    Write-CleanupLog "Skipping critical directory: $($dir.FullName)" "WARNING"
                    continue
                }
            }
            
            if ($WhatIf) {
                Write-CleanupLog "WhatIf: Would remove $($dir.FullName)" "INFO"
            }
            else {
                Write-CleanupLog "Removing $($dir.FullName)..." "INFO"
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
                $removed++
                Write-CleanupLog "Successfully removed $($dir.FullName)" "SUCCESS"
            }
        }
        catch {
            Write-CleanupLog "Failed to remove $($dir.FullName): $_" "ERROR"
            $errors++
        }
    }
    
    # Stage 4: Clean up orphaned files in the archive directory
    $archiveRoot = "$ProjectRoot/archive"
    if (Test-Path $archiveRoot) {
        $archiveFiles = Get-ChildItem -Path $archiveRoot -File -ErrorAction SilentlyContinue
        
        # Only clean up specific patterns
        $allowedPatterns = @(
            "*backup*.ps1",
            "*broken*.ps1",
            "*temp*.ps1",
            "*old*.ps1",
            "test-*.ps1",
            "*.bak"
        )
        
        $filesToRemove = @()
        foreach ($pattern in $allowedPatterns) {
            $filesToRemove += $archiveFiles | Where-Object { $_.Name -like $pattern }
        }
        
        if ($filesToRemove.Count -gt 0) {
            Write-CleanupLog "Found $($filesToRemove.Count) orphaned files to clean up" "INFO"
            
            foreach ($file in $filesToRemove) {
                try {
                    if ($WhatIf) {
                        Write-CleanupLog "WhatIf: Would remove $($file.FullName)" "INFO"
                    }
                    else {
                        Write-CleanupLog "Removing $($file.Name)..." "INFO"
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                        $removed++
                    }
                }
                catch {
                    Write-CleanupLog "Failed to remove $($file.Name): $_" "ERROR"
                    $errors++
                }
            }
        }
    }
    
    # Summary
    if (-not $WhatIf) {
        Write-CleanupLog "Archive cleanup complete: removed $removed items with $errors errors" "INFO"
    }
    else {
        Write-CleanupLog "Archive cleanup preview complete: would remove $removed items" "INFO"
    }
    
    return [PSCustomObject]@{
        RemovedItems = $removed
        Errors = $errors
        WhatIf = $WhatIf
    }
}
