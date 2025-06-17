#Requires -Version 7.0
<#
.SYNOPSIS
    Cleans up old and merged Git branches
    
.DESCRIPTION
    Removes old Git branches while preserving protected branches and recent activity.
    Integrates with GitHub CLI to check for merged PRs and no-delete labels.
    
.PARAMETER Remote
    The remote to clean up branches from (default: origin)
    
.PARAMETER PreserveHours
    Hours to preserve recent branches (default: 24)
    
.PARAMETER Force
    Force deletion of branches regardless of age
    
.PARAMETER LogPath
    Path to write cleanup logs (default: logs/branch-cleanup.log)
    
.EXAMPLE
    Invoke-BranchCleanup -Force
    
.EXAMPLE
    Invoke-BranchCleanup -PreserveHours 48 -Remote upstream
    
.NOTES
    Follows PowerShell 7.0+ cross-platform standards
    Uses Write-CustomLog for consistent logging
    Respects no-emoji policy with clear, professional output
#>

function Invoke-BranchCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",

        [Parameter(Mandatory = $false)]
        [int]$PreserveHours = 24,

        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = "logs/branch-cleanup.log"
    )

    $alwaysPreserveBranches = @(
        "main",
        "master", 
        "develop",
        "feature/*",
        "hotfix/*",
        "release/*"
    )

    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    function Write-CleanupLog {
        param([string]$Message, [string]$Level = "INFO")
        Write-CustomLog -Message $Message -Level $Level
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message" | Add-Content $LogPath
    }

    Write-CleanupLog "Starting branch cleanup..." "INFO"
    Write-CleanupLog "Remote: $Remote" "INFO"
    Write-CleanupLog "Preserve Hours: $PreserveHours" "INFO"
    Write-CleanupLog "Force Mode: $Force" "INFO"
    
    try {
        # Get all remote branches
        $branches = git branch -r | Where-Object { $_ -notmatch 'HEAD' } | ForEach-Object { $_.Trim() }
        $preserveCutoff = (Get-Date).AddHours(-$PreserveHours)
        $stats = @{
            Total = $branches.Count
            Protected = 0
            Recent = 0
            Deleted = 0
            Failed = 0
        }

        # Get list of currently merged PRs
        $mergedPRs = @()
        try {
            $mergedPRs = gh pr list --state merged --json headRefName --limit 100 | ConvertFrom-Json | Select-Object -ExpandProperty headRefName
            Write-CleanupLog "Found $($mergedPRs.Count) recently merged PRs" "INFO"
        }
        catch {
            Write-CleanupLog "Failed to get merged PRs: $($_.Exception.Message)" "WARN"
        }

        foreach ($branch in $branches) {
            $branchName = $branch -replace "^$Remote/", ''
            Write-CleanupLog "Processing branch: $branchName" "INFO"
            
            # Skip protected branches
            $isProtected = $false
            foreach ($pattern in $alwaysPreserveBranches) {
                if ($branchName -like $pattern) {
                    $isProtected = $true
                    break
                }
            }
            if ($isProtected) {
                Write-CleanupLog "Protected branch: $branchName - skipping" "INFO"
                $stats.Protected++
                continue
            }

            # Check for no-delete label on PR and skip if found
            try {
                $prInfo = gh pr view $branchName --json labels 2>$null | ConvertFrom-Json
                if ($prInfo.labels | Where-Object { $_.name -eq 'no-delete' }) {
                    Write-CleanupLog "Branch has no-delete label: $branchName - preserving" "WARN"
                    $stats.Protected++
                    continue
                }
            }
            catch {
                # PR might not exist, which is fine
            }

            # Get last commit timestamp
            $lastCommit = git log -1 --format="%ct" $branch 2>$null
            if (-not $lastCommit) { continue }
            
            $lastCommitDate = [DateTimeOffset]::FromUnixTimeSeconds([long]$lastCommit).DateTime
            
            # Keep recent branches unless forced
            if (-not $Force -and $lastCommitDate -gt $preserveCutoff) {
                Write-CleanupLog "Recent branch: $branchName (modified $($lastCommitDate.ToString('g'))) - preserving" "INFO"
                $stats.Recent++
                continue
            }

            # Delete branch if it's merged or force is used
            $isMerged = $mergedPRs -contains $branchName -or 
                       (git branch -r --merged | Where-Object { $_ -match [regex]::Escape($branch) })
            
            if ($isMerged -or $Force) {
                if ($PSCmdlet.ShouldProcess($branchName, "Delete branch")) {
                    Write-CleanupLog "Deleting branch: $branchName" "WARN"
                    $result = git push $Remote --delete $branchName 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-CleanupLog "Successfully deleted: $branchName" "SUCCESS"
                        git branch -D $branchName 2>$null # Clean up local branch if it exists
                        $stats.Deleted++
                    }
                    else {
                        Write-CleanupLog "Failed to delete: $branchName - $result" "ERROR"
                        $stats.Failed++
                    }
                }
            }
        }

        # Write summary
        $summary = @"
Branch Cleanup Summary
---------------------
Total Branches: $($stats.Total)
Protected: $($stats.Protected)
Recent: $($stats.Recent)
Deleted: $($stats.Deleted)
Failed: $($stats.Failed)
"@

        Write-CleanupLog $summary "INFO"
        Write-CleanupLog "Branch cleanup complete. See $LogPath for full details." "SUCCESS"

        return @{
            Success = $true
            Stats = $stats
            LogPath = $LogPath
            Message = "Cleanup complete. Deleted $($stats.Deleted) branches."
        }
    }
    catch {
        $errorMsg = "Branch cleanup failed: $($_.Exception.Message)"
        Write-CleanupLog $errorMsg "ERROR"
        return @{
            Success = $false
            Error = $errorMsg
        }
    }
}
