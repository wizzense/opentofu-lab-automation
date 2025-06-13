# /workspaces/opentofu-lab-automation/scripts/maintenance/cleanup-duplicate-directories.ps1

<#
.SYNOPSIS
    Cleans up duplicate directories and obsolete fix scripts

.DESCRIPTION
    This script handles:
    1. Duplicate Modules directories (Modules/ vs modules/)
    2. Obsolete fixes directory that contains historical Pester fix scripts
    3. Any other duplicate or legacy directory structures

.PARAMETER DryRun
    Show what would be done without making changes

.PARAMETER ArchiveObsolete
    Move obsolete directories to archive instead of deleting

.EXAMPLE
    ./scripts/maintenance/cleanup-duplicate-directories.ps1 -DryRun
    ./scripts/maintenance/cleanup-duplicate-directories.ps1 -ArchiveObsolete
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$ArchiveObsolete
)





# Initialize logging
$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = "/workspaces/opentofu-lab-automation/docs/reports/project-status"
$reportFile = "$reportPath/$timestamp-duplicate-cleanup.md"

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
# Duplicate Directory Cleanup Report
**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Mode**: $$(if (DryRun) { "Dry Run" } else { "Live Execution" })

## Summary
This report documents the cleanup of duplicate directories and obsolete fix scripts.

## Issues Identified

"@
    Set-Content -Path $reportFile -Value $reportContent
}

function Compare-Directories {
    param($Dir1, $Dir2)
    
    



if (-not (Test-Path $Dir1) -or -not (Test-Path $Dir2)) {
        return $false
    }
    
    $files1 = Get-ChildItem -Path $Dir1 -Recurse -File | Sort-Object Name
    $files2 = Get-ChildItem -Path $Dir2 -Recurse -File | Sort-Object Name
    
    if ($files1.Count -ne $files2.Count) {
        return $false
    }
    
    for ($i = 0; $i -lt $files1.Count; $i++) {
        $content1 = Get-Content -Path $files1[$i].FullName -Raw -ErrorAction SilentlyContinue
        $content2 = Get-Content -Path $files2[$i].FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content1 -ne $content2) {
            return $false
        }
    }
    
    return $true
}

function Cleanup-DuplicateModules {
    Write-Log "Analyzing duplicate Modules directories..."
    
    $modernModules = "/workspaces/opentofu-lab-automation/pwsh/modules"
    $legacyModules = "/workspaces/opentofu-lab-automation/pwsh/Modules"
    
    if (-not (Test-Path $legacyModules)) {
        Write-Log "No legacy Modules directory found"
        return
    }
    
    if (-not (Test-Path $modernModules)) {
        Write-Log "WARNING: Modern modules directory not found!" -Level "WARNING"
        return
    }
    
    # Compare LabRunner directories
    $modernLabRunner = "$modernModules/LabRunner"
    $legacyLabRunner = "$legacyModules/LabRunner"
    
    if ((Test-Path $modernLabRunner) -and (Test-Path $legacyLabRunner)) {
        Write-Log "Comparing LabRunner directories..."
        
        $areIdentical = Compare-Directories -Dir1 $modernLabRunner -Dir2 $legacyLabRunner
        
        if ($areIdentical) {
            Write-Log "LabRunner directories are identical - safe to remove legacy"
            
            if ($ArchiveObsolete) {
                $archivePath = "/workspaces/opentofu-lab-automation/archive/legacy-modules/Modules-capital-$timestamp"
                Write-Log "Archiving legacy Modules: $legacyModules -> $archivePath"
                
                if (-not $DryRun) {
                    if (-not (Test-Path (Split-Path $archivePath))) {
                        New-Item -Path (Split-Path $archivePath) -ItemType Directory -Force | Out-Null
                    }
                    Move-Item -Path $legacyModules -Destination $archivePath -Force
                }
            } else {
                Write-Log "Removing duplicate legacy Modules directory: $legacyModules"
                if (-not $DryRun) {
                    Remove-Item -Path $legacyModules -Recurse -Force
                }
            }
        } else {
            Write-Log "WARNING: LabRunner directories differ - manual review needed!" -Level "WARNING"
            
            # Show differences
            $modernFiles = Get-ChildItem -Path $modernLabRunner -File | Sort-Object Name
            $legacyFiles = Get-ChildItem -Path $legacyLabRunner -File | Sort-Object Name
            
            Write-Log "Modern LabRunner files: $($modernFiles.Count)"
            Write-Log "Legacy LabRunner files: $($legacyFiles.Count)"
        }
    }
}

function Cleanup-FixesDirectory {
    Write-Log "Analyzing fixes directory..."
    
    $fixesDir = "/workspaces/opentofu-lab-automation/fixes"
    
    if (-not (Test-Path $fixesDir)) {
        Write-Log "No fixes directory found"
        return
    }
    
    # Check if fixes are historical/obsolete
    $fixesContent = Get-ChildItem -Path $fixesDir -Recurse
    Write-Log "Found $($fixesContent.Count) items in fixes directory"
    
    # Read the README to understand purpose
    $readmePath = "$fixesDir/pester-param-errors/README.md"
    if (Test-Path $readmePath) {
        $readmeContent = Get-Content $readmePath -Raw
        if ($readmeContent -match "historical|development|obsolete" -or 
            $readmeContent -match "working scripts.*final solutions") {
            
            Write-Log "Fixes directory contains historical/development scripts"
            
            if ($ArchiveObsolete) {
                $archivePath = "/workspaces/opentofu-lab-automation/archive/historical-fixes/pester-fixes-$timestamp"
                Write-Log "Archiving fixes directory: $fixesDir -> $archivePath"
                
                if (-not $DryRun) {
                    if (-not (Test-Path (Split-Path $archivePath))) {
                        New-Item -Path (Split-Path $archivePath) -ItemType Directory -Force | Out-Null
                    }
                    Move-Item -Path $fixesDir -Destination $archivePath -Force
                }
            } else {
                Write-Log "Fixes directory identified as obsolete but ArchiveObsolete not specified"
            }
        }
    }
}

function Check-OtherDuplicates {
    Write-Log "Scanning for other potential duplicates..."
    
    # Check for case-sensitive duplicates
    $projectRoot = "/workspaces/opentofu-lab-automation"
    $directories = Get-ChildItem -Path $projectRoot -Directory | Group-Object { $_.Name.ToLower() }
    
    foreach ($group in $directories) {
        if ($group.Count -gt 1) {
            Write-Log "POTENTIAL DUPLICATE: $($group.Name) - $($group.Group.Name -join ', ')" -Level "WARNING"
        }
    }
}

function Update-GitIgnore {
    Write-Log "Updating .gitignore for cleanup patterns..."
    
    $gitignorePath = "/workspaces/opentofu-lab-automation/.gitignore"
    $cleanupEntries = @(
        "# Historical/development directories",
        "archive/historical-fixes/",
        "archive/legacy-modules/",
        ""
    )
    
    if (Test-Path $gitignorePath) {
        $content = Get-Content $gitignorePath -Raw
        $needsUpdate = $false
        
        foreach ($entry in $cleanupEntries) {
            if ($entry -and $content -notmatch [regex]::Escape($entry)) {
                $needsUpdate = $true
                break
            }
        }
        
        if ($needsUpdate -and -not $DryRun) {
            Write-Log "Adding cleanup entries to .gitignore"
            Add-Content -Path $gitignorePath -Value "`n$($cleanupEntries -join "`n")"
        }
    }
}

function Finalize-Report {
    $finalContent = @"

## Final Status
- **Duplicate Modules**: $(if (Test-Path "/workspaces/opentofu-lab-automation/pwsh/Modules") { "Found and processed" } else { "Not found or cleaned" })
- **Fixes directory**: $(if (Test-Path "/workspaces/opentofu-lab-automation/fixes") { "Found and analyzed" } else { "Not found or processed" })
- **Mode**: $$(if (DryRun) { "Dry run - no changes made" } else { "Live execution" })

## Recommendations
1. Review archive directories periodically for cleanup
2. Maintain consistent naming conventions (lowercase)
3. Use archive approach for historical preservation
4. Run validation after cleanup to ensure no broken references

## Next Steps
- Run comprehensive validation: ``./run-final-validation.ps1``
- Update any references to moved directories
- Consider implementing naming convention enforcement

---
**Report completed**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    Add-Content -Path $reportFile -Value $finalContent
    Write-Log "Report saved to: $reportFile"
}

# Main execution
try {
    Initialize-Report
    Write-Log "Starting duplicate directory cleanup process"
    
    # Clean up duplicate Modules directories
    Cleanup-DuplicateModules
    
    # Clean up fixes directory
    Cleanup-FixesDirectory
    
    # Check for other duplicates
    Check-OtherDuplicates
    
    # Update gitignore
    Update-GitIgnore
    
    Write-Log "Duplicate directory cleanup completed successfully"
    
} catch {
    Write-Log "FATAL ERROR: $_" -Level "ERROR"
    throw
} finally {
    Finalize-Report
}


