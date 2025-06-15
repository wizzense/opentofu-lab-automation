<#
.SYNOPSIS
Consolidates all backup files into a centralized backup location

.DESCRIPTION
Finds and moves all backup files from throughout the project into a consolidated
backup directory structure, organized by date and type.

.PARAMETER Config
A PSCustomObject containing configuration parameters:
- ProjectRoot: The root directory of the project to scan for backup files
- Force: Skip confirmation prompts and force the consolidation (Optional)
- ExcludePaths: Additional paths to exclude from backup consolidation (Optional)

.EXAMPLE
$config = [PSCustomObject]@{
    ProjectRoot = "."
    Force = $true
}
Invoke-BackupConsolidation -Config $config

.NOTES
Follows OpenTofu Lab Automation maintenance standards
#>
function Invoke-BackupConsolidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    $ErrorActionPreference = "Stop"
    
    # Import required modules
    Import-Module "/pwsh/modules/LabRunner/"  -ForceImport-Module "/workspaces/opentofu-lab-automation/pwsh/modules/CodeFixer/"Logging/" -Force

    # Fallback definition for Write-CustomLog if not available
    if (-not (Get-Command "Write-CustomLog" -ErrorAction SilentlyContinue)) {
        function Write-CustomLog {
            param([string]$Message, [string]$Level = "INFO")
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $color = switch ($Level) {
                "ERROR" { "Red" }
                "WARN" { "Yellow" }
                "INFO" { "Green" }
                default { "White" }
            }
            Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
        }
    }
    
    # Extract configuration parameters
    $ProjectRoot = $Config.ProjectRoot
    $Force = if ($null -ne $Config.Force) { $Config.Force } else { $false }
    $ExcludePaths = if ($null -ne $Config.ExcludePaths) { $Config.ExcludePaths } else { @() }
    
    # Main execution with LabRunner pattern
    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Starting backup consolidation process" "INFO"
          try {
            # Resolve project root
            $ProjectRoot = Resolve-Path $ProjectRoot -ErrorAction Stop
            $BackupDestination = Join-Path $ProjectRoot $script:BackupRootPath (Get-Date -Format "yyyyMMdd")
            
            Write-CustomLog "Backup destination will be: $BackupDestination" "INFO"
            
            # Create backup destination
            if (-not (Test-Path $BackupDestination)) {
                New-Item -ItemType Directory -Path $BackupDestination -Force | Out-Null
                Write-CustomLog "Created backup destination directory" "INFO"
            }
            
            # Build exclusion patterns
            $AllExclusions = $script:BackupExclusions + $ExcludePaths
            Write-CustomLog "Using exclusion patterns: $($AllExclusions -join ', ')" "DEBUG"
            
            # Find backup files with proper exclusion handling
            $BackupPatterns = @("*.bak", "*backup*", "*.old", "*.orig", "*~")
            $BackupFiles = @()
            
            foreach ($Pattern in $BackupPatterns) {
                try {
                    $Files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Filter $Pattern -ErrorAction SilentlyContinue
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
                }
            }
            
            # Confirm operation unless Force is specified
            if (-not $Force) {
                Write-CustomLog "Found $($BackupFiles.Count) backup files to consolidate" "INFO"
                $Confirmation = Read-Host "Proceed with consolidation? (y/N)"
                if ($Confirmation -notmatch '^[Yy]') {
                    Write-CustomLog "Operation cancelled by user" "INFO"
                    return @{ Success = $false; Message = "Cancelled by user" }
                }
            }
        
        # Process backup files            # Process backup files
            $ProcessedCount = 0
            $TotalSize = 0
            $FailedMoves = @()

            Write-Progress -Activity "Backup Consolidation" -Status "Preparing to process files" -PercentComplete 0
            
            for ($i = 0; $i -lt $BackupFiles.Count; $i++) {
                $File = $BackupFiles[$i]
                $percentComplete = ($i / $BackupFiles.Count) * 100
                Write-Progress -Activity "Backup Consolidation" -Status "Processing file $($i+1) of $($BackupFiles.Count)" -PercentComplete $percentComplete
                
                try {
                    $RelativePath = $File.FullName.Replace($ProjectRoot, "").TrimStart([char]'\', [char]'/')
                    $DestinationPath = Join-Path $BackupDestination $RelativePath
                    $DestinationDir = Split-Path $DestinationPath -Parent

                    if (-not (Test-Path $DestinationDir)) {
                        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
                    }

                    Move-Item -Path $File.FullName -Destination $DestinationPath -Force
                    Write-CustomLog "Moved $($File.FullName) to $DestinationPath" "INFO"
                    $ProcessedCount++
                    $TotalSize += $File.Length
                } catch {
                    $ErrorMessage = "Failed to move $($File.FullName): $($_.Exception.Message)"
                    Write-CustomLog $ErrorMessage "WARN"
                    $FailedMoves += $File.FullName
                }
            }
            
            Write-Progress -Activity "Backup Consolidation" -Status "Complete" -Completed
            
            $SummaryMessage = "Backup consolidation completed: $ProcessedCount files moved, $([math]::Round($TotalSize / 1MB, 2)) MB total size"
            Write-CustomLog $SummaryMessage "INFO"

            if ($FailedMoves.Count -gt 0) {
                Write-CustomLog "Failed to move $($FailedMoves.Count) files. See warnings for details." "WARN"
            }
            
            return @{
                Success = ($FailedMoves.Count -eq 0)
                FilesProcessed = $ProcessedCount
                TotalSize = $TotalSize
                Message = $SummaryMessage
                FailedFiles = $FailedMoves
            }
        } catch {
            Write-CustomLog "Fatal error during backup consolidation: $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}







