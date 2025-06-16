#Requires -Version 7.0
<#
.SYNOPSIS
    Consolidates backup files for PatchManager operations
    
.DESCRIPTION
    Migrated from BackupManager into PatchManager to provide unified backup consolidation
    with enhanced Git integration and change control features.
    
.PARAMETER Config
    Configuration object with ProjectRoot, Force, and ExcludePaths properties
    
.EXAMPLE
    $config = @{
        ProjectRoot = "."
        Force = $true
        ExcludePaths = @("*.tmp", "node_modules")
    }
    Invoke-BackupConsolidation -Config $config
    
.NOTES
    This function is now part of PatchManager's comprehensive change management system.
    Integrated with Git operations and provides audit trails.
#>

function Invoke-BackupConsolidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    begin {
        $ErrorActionPreference = "Stop"
        
        # Default backup exclusions for OpenTofu Lab Automation
        $script:DefaultBackupExclusions = @(
            "*.git/*", "node_modules/*", "*.tmp", "*.temp", 
            "logs/*", "*.log", "backups/*", "archive/*",
            ".vscode/*", "*.cache", "*.lock"
        )
        
        # Initialize logging
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
    }
    
    process {
        try {
            Write-CustomLog "Starting PatchManager backup consolidation" "INFO"
            
            # Extract and validate configuration
            $ProjectRoot = $Config.ProjectRoot ?? "."
            $Force = $Config.Force ?? $false
            $ExcludePaths = $Config.ExcludePaths ?? @()
            
            # Resolve project root to absolute path
            $ProjectRoot = Resolve-Path $ProjectRoot -ErrorAction Stop
            $BackupDestination = Join-Path $ProjectRoot "backups" "consolidated-backups" (Get-Date -Format "yyyyMMdd-HHmmss")
            
            Write-CustomLog "Backup destination: $BackupDestination" "INFO"
            
            # Create backup destination
            if (-not (Test-Path $BackupDestination)) {
                New-Item -ItemType Directory -Path $BackupDestination -Force | Out-Null
                Write-CustomLog "Created backup destination directory" "INFO"
            }
            
            # Combine exclusions
            $AllExclusions = $script:DefaultBackupExclusions + $ExcludePaths
            Write-CustomLog "Using exclusion patterns: $($AllExclusions.Count) patterns" "DEBUG"
            
            # Find backup files
            $BackupPatterns = @("*.bak", "*backup*", "*.old", "*.orig", "*~", "*.backup", "*-backup-*")
            $BackupFiles = @()
            
            foreach ($Pattern in $BackupPatterns) {
                try {
                    $Files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Filter $Pattern -ErrorAction SilentlyContinue
                    
                    # Filter out excluded files
                    $FilteredFiles = $Files | Where-Object {
                        $FilePath = $_.FullName
                        $RelativePath = $FilePath.Replace($ProjectRoot, "").TrimStart([char]'\', [char]'/')
                        
                        $Excluded = $false
                        foreach ($Exclusion in $AllExclusions) {
                            if ($RelativePath -like $Exclusion -or $FilePath -like "*$($Exclusion.Replace('*', ''))*") {
                                $Excluded = $true
                                break
                            }
                        }
                        return -not $Excluded
                    }
                    
                    $BackupFiles += $FilteredFiles
                    Write-CustomLog "Found $($FilteredFiles.Count) files matching pattern '$Pattern'" "DEBUG"
                } catch {
                    Write-CustomLog "Error searching for pattern '$Pattern': $($_.Exception.Message)" "WARN"
                }
            }
            
            if ($BackupFiles.Count -eq 0) {
                Write-CustomLog "No backup files found to consolidate" "INFO"
                return @{
                    Success = $true
                    FilesProcessed = 0
                    TotalSize = 0
                    Message = "No backup files found"
                    BackupDestination = $BackupDestination
                }
            }
            
            # Confirmation unless Force is specified
            if (-not $Force) {
                Write-CustomLog "Found $($BackupFiles.Count) backup files to consolidate" "INFO"
                $Confirmation = Read-Host "Proceed with consolidation? (y/N)"
                if ($Confirmation -notmatch '^[Yy]') {
                    Write-CustomLog "Operation cancelled by user" "INFO"
                    return @{ Success = $false; Message = "Cancelled by user" }
                }
            }
            
            # Process backup files with progress tracking
            $ProcessedCount = 0
            $TotalSize = 0
            $FailedMoves = @()
            
            Write-Progress -Activity "PatchManager Backup Consolidation" -Status "Preparing..." -PercentComplete 0
            
            for ($i = 0; $i -lt $BackupFiles.Count; $i++) {
                $File = $BackupFiles[$i]
                $percentComplete = [math]::Round(($i / $BackupFiles.Count) * 100, 2)
                Write-Progress -Activity "PatchManager Backup Consolidation" -Status "Processing file $($i+1) of $($BackupFiles.Count): $($File.Name)" -PercentComplete $percentComplete
                
                try {
                    # Maintain directory structure in backup
                    $RelativePath = $File.FullName.Replace($ProjectRoot, "").TrimStart([char]'\', [char]'/')
                    $DestinationPath = Join-Path $BackupDestination $RelativePath
                    $DestinationDir = Split-Path $DestinationPath -Parent
                    
                    # Create destination directory if needed
                    if (-not (Test-Path $DestinationDir)) {
                        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
                    }
                    
                    # Move file to consolidated backup location
                    Move-Item -Path $File.FullName -Destination $DestinationPath -Force
                    Write-CustomLog "Moved: $($File.Name) -> $RelativePath" "DEBUG"
                    
                    $ProcessedCount++
                    $TotalSize += $File.Length
                } catch {
                    $ErrorMessage = "Failed to move $($File.FullName): $($_.Exception.Message)"
                    Write-CustomLog $ErrorMessage "WARN"
                    $FailedMoves += $File.FullName
                }
            }
            
            Write-Progress -Activity "PatchManager Backup Consolidation" -Status "Complete" -Completed
            
            # Create consolidation summary
            $SizeInMB = [math]::Round($TotalSize / 1MB, 2)
            $SummaryMessage = "Backup consolidation completed: $ProcessedCount files moved, $SizeInMB MB total"
            Write-CustomLog $SummaryMessage "INFO"
            
            # Create consolidation manifest
            $Manifest = @{
                ConsolidationDate = Get-Date
                FilesProcessed = $ProcessedCount
                TotalSizeBytes = $TotalSize
                TotalSizeMB = $SizeInMB
                SourcePatterns = $BackupPatterns
                ExclusionPatterns = $AllExclusions
                FailedFiles = $FailedMoves
                BackupDestination = $BackupDestination
                GitCommit = (git rev-parse HEAD 2>$null)
            }
            
            $ManifestPath = Join-Path $BackupDestination "consolidation-manifest.json"
            $Manifest | ConvertTo-Json -Depth 3 | Set-Content -Path $ManifestPath -Encoding UTF8
            Write-CustomLog "Created consolidation manifest: $ManifestPath" "INFO"
            
            if ($FailedMoves.Count -gt 0) {
                Write-CustomLog "Failed to move $($FailedMoves.Count) files. See warnings for details." "WARN"
            }
            
            return @{
                Success = ($FailedMoves.Count -eq 0)
                FilesProcessed = $ProcessedCount
                TotalSize = $TotalSize
                TotalSizeMB = $SizeInMB
                Message = $SummaryMessage
                FailedFiles = $FailedMoves
                BackupDestination = $BackupDestination
                ManifestPath = $ManifestPath
            }
            
        } catch {
            Write-CustomLog "Fatal error during backup consolidation: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}
