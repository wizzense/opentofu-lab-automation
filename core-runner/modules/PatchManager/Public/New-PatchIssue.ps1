#Requires -Version 7.0

<#
.SYNOPSIS
    The ONLY way to create GitHub issues for patch tracking.

.DESCRIPTION
    Creates clean, professional GitHub issues for patch tracking.
    No emoji/Unicode output - follows project standards.

.PARAMETER Description
    Description of the patch/issue

.PARAMETER Priority
    Priority level (Low, Medium, High, Critical)

.PARAMETER AffectedFiles
    Files affected by the patch

.PARAMETER Labels
    Additional labels to apply

.PARAMETER DryRun
    Preview what would be created without actually creating

.EXAMPLE
    New-PatchIssue -Description "Fix module loading bug" -Priority "High"

.EXAMPLE
    New-PatchIssue -Description "Update config files" -AffectedFiles @("config.json", "settings.ps1") -DryRun

.NOTES
    This function replaces:
    - Invoke-ComprehensiveIssueTracking
    - Invoke-GitHubIssueIntegration
    - New-SimpleIssueForPatch
    - And all other issue creation functions
#>

function New-PatchIssue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Priority = "Medium",

        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$Labels = @(),

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    begin {
        function Write-IssueLog {
            param($Message, $Level = "INFO")
            if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
                Write-CustomLog -Message $Message -Level $Level
            } else {
                Write-Host "[$Level] $Message"
            }
        }

        Write-IssueLog "Creating GitHub issue for: $Description" -Level "INFO"
    }

    process {
        try {
            # Check GitHub CLI availability
            if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
                throw "GitHub CLI (gh) not found. Please install and authenticate with GitHub CLI."
            }

            # Create issue title and body
            $issueTitle = "Patch: $Description"
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC'

            $issueBody = @"
## Patch Tracking Issue

**Description**: $Description
**Priority**: $Priority
**Created**: $timestamp

### Files Affected
$(if ($AffectedFiles.Count -gt 0) {
    ($AffectedFiles | ForEach-Object { "- ``$_``" }) -join "`n"
} else {
    "*Files will be identified during patch review*"
})

### Expected Actions
1. Review associated pull request when created
2. Validate changes in clean environment
3. Approve and merge if all checks pass
4. This issue will auto-close when PR is merged

---
*Created by PatchManager*
"@

            if ($DryRun) {
                Write-IssueLog "DRY RUN: Would create issue with title: $issueTitle" -Level "INFO"
                return @{
                    Success = $true
                    DryRun = $true
                    Title = $issueTitle
                    Body = $issueBody
                }
            }

            # Prepare labels
            $allLabels = @("patch") + $Labels
            if ($Priority -eq "High" -or $Priority -eq "Critical") {
                $allLabels += "priority"
            }

            # Create the issue with robust error handling
            Write-IssueLog "Creating GitHub issue: $issueTitle" -Level "INFO"
            $result = gh issue create --title $issueTitle --body $issueBody --label ($allLabels -join ',') 2>&1

            # Handle label errors gracefully
            if ($LASTEXITCODE -ne 0 -and $result -match "not found") {
                Write-IssueLog "Label issue detected, creating without labels" -Level "WARN"
                $result = gh issue create --title $issueTitle --body $issueBody 2>&1
            }

            if ($LASTEXITCODE -eq 0) {
                # Extract issue number from URL
                $issueNumber = $null
                if ($result -match '/issues/(\d+)') {
                    $issueNumber = $matches[1]
                }

                Write-IssueLog "Issue created successfully: $result" -Level "SUCCESS"
                if ($issueNumber) {
                    Write-IssueLog "Issue number: #$issueNumber" -Level "INFO"
                }

                return @{
                    Success = $true
                    IssueUrl = $result.ToString().Trim()
                    IssueNumber = $issueNumber
                    Title = $issueTitle
                }
            } else {
                throw "GitHub CLI failed: $($result -join ' ')"
            }

        } catch {
            $errorMessage = "Failed to create issue: $($_.Exception.Message)"
            Write-IssueLog $errorMessage -Level "ERROR"

            return @{
                Success = $false
                Message = $errorMessage
            }
        }
    }
}

Export-ModuleMember -Function New-PatchIssue
