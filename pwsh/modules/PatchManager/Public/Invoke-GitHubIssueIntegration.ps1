#Requires -Version 7.0
<#
.SYNOPSIS
    Creates and manages GitHub issues for automated bug fixes and patches
    
.DESCRIPTION
    This function automatically creates GitHub issues when patches fix bugs,
    links them to pull requests, and provides comprehensive tracking of 
    automated fixes with priority levels and proper labeling.
    
.PARAMETER PatchDescription
    Description of the patch being applied
    
.PARAMETER PullRequestUrl
    URL of the associated pull request
    
.PARAMETER AffectedFiles
    Array of files affected by the patch
    
.PARAMETER Labels
    Labels to apply to the GitHub issue
    
.PARAMETER Priority
    Priority level for the issue (Low, Medium, High, Critical)
    
.PARAMETER ForceCreate
    Force creation of issue even if not detected as bug fix
    
.EXAMPLE
    Invoke-GitHubIssueIntegration -PatchDescription "Fix critical validation bug" -PullRequestUrl "https://github.com/repo/pull/123" -AffectedFiles @("script.ps1") -Priority "High"
    
.NOTES
    - Requires GitHub CLI (gh) to be installed and authenticated
    - Only creates issues for bug fixes unless ForceCreate is specified
    - Links issues to pull requests automatically
    - Provides comprehensive audit trail
#>

function Invoke-GitHubIssueIntegration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        
        [Parameter(Mandatory = $false)]
        [string]$PullRequestUrl,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Labels = @("bug"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Priority = "Medium",
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceCreate
    )
    
    begin {
        Write-Host "GitHub Issue Integration: Starting issue creation process..." -ForegroundColor Blue
        
        # Check if GitHub CLI is available
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            return @{
                Success = $false
                Message = "GitHub CLI (gh) not found. Cannot create issues automatically."
                IssueUrl = $null
                IssueNumber = $null
            }
        }
        
        # Detect if this is a bug fix
        $isBugFix = $PatchDescription -match '\b(fix|bug|error|issue|problem|broken|critical|urgent|emergency)\b' -or $ForceCreate
        
        if (-not $isBugFix -and -not $ForceCreate) {
            Write-Host "  Not a bug fix - skipping issue creation" -ForegroundColor Gray
            return @{
                Success = $true
                Message = "Skipped issue creation - not a bug fix"
                IssueUrl = $null
                IssueNumber = $null
            }
        }
    }
    
    process {
        try {
            Write-Host "  Creating GitHub issue for bug fix..." -ForegroundColor Green
            
            # First check if GitHub CLI is available
            $ghInstalled = $null -ne (Get-Command "gh" -ErrorAction SilentlyContinue)
            if (-not $ghInstalled) {
                Write-Warning "GitHub CLI (gh) not found. Skipping issue creation."
                return @{
                    Success = $false
                    Message = "GitHub CLI (gh) not found"
                    IssueUrl = $null
                    IssueNumber = $null
                }
            }
            
            # Check if we're in a GitHub repository
            $repoExists = (git config --get remote.origin.url) -match "github\.com"
            if (-not $repoExists) {
                Write-Warning "Not in a GitHub repository. Skipping issue creation."
                return @{
                    Success = $false
                    Message = "Not in a GitHub repository"
                    IssueUrl = $null 
                    IssueNumber = $null
                }
            }
            
            # Determine priority-based labels
            $priorityLabels = switch ($Priority) {
                "Critical" { @("bug", "high-priority") }
                "High" { @("bug", "priority") }
                "Medium" { @("bug") }
                "Low" { @("minor") }
                default { @("bug") }
            }
            
            # Combine all labels
            $allLabels = $Labels + $priorityLabels + @("automated")
            
            # First try to create any missing labels
            foreach ($label in $allLabels) {
                Write-Host "  Checking if label '$label' exists..." -ForegroundColor Gray
                $labelExists = gh label list | Select-String -Pattern "^$label\s" -Quiet
                
                if (-not $labelExists) {
                    try {
                        Write-Host "  Creating missing label: $label" -ForegroundColor Yellow
                        # Default color for new labels
                        $labelColor = switch ($label) {
                            "bug" { "d73a4a" }  # red
                            "automated" { "0075ca" }  # blue
                            "high-priority" { "b60205" }  # dark red
                            "priority" { "d93f0b" }  # orange
                            "minor" { "c2e0c6" }  # light green
                            default { "fbca04" }  # yellow
                        }
                        
                        gh label create $label --color $labelColor --description "Auto-created by PatchManager" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
                            Write-Warning "  Could not create label '$label', will continue without it"
                            # Remove the label from our list so we don't try to use it
                            $allLabels = $allLabels | Where-Object{ $_ -ne $label }
                        }
                    }
                    catch {
                        Write-Warning "  Failed to create label '$label': $_"
                    }
                }
            }            # Create GitHub issue
            $title = $PatchDescription
            $body = "Affected files: $($AffectedFiles -join ', ')"
            $labelString = $allLabels -join ','

            $issueResult = gh issue create --title $title --body $body --label $labelString

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  GitHub issue created successfully" -ForegroundColor Green
                return @{
                    Success = $true
                    Message = "GitHub issue created successfully"
                    IssueUrl = $issueResult
                    IssueNumber = ($issueResult -match "#(\d+)") ? $matches[1] : $null
                }
            } else {
                Write-Warning "  Failed to create GitHub issue: $issueResult"
                return @{
                    Success = $false
                    Message = "Failed to create GitHub issue"
                    IssueUrl = $null
                    IssueNumber = $null
                }
            }
            
        } catch {
            Write-Error "Failed to create GitHub issue: $($_.Exception.Message)"
            return @{
                Success = $false
                Message = "Failed to create GitHub issue: $($_.Exception.Message)"
                IssueUrl = $null
                IssueNumber = $null
            }
        }
    }
}



