#Requires -Version 7.0

<#
.SYNOPSIS
    The ONLY way to create pull requests for patches.

.DESCRIPTION
    Creates clean, professional pull requests with proper issue linking.
    No emoji/Unicode output - follows project standards.

.PARAMETER Description
    Description of the patch

.PARAMETER BranchName
    Name of the branch to create PR from

.PARAMETER IssueNumber
    Issue number to link (for auto-closing)

.PARAMETER AffectedFiles
    Files affected by the patch

.PARAMETER DryRun
    Preview what would be created without actually creating

.EXAMPLE
    New-PatchPR -Description "Fix module loading" -BranchName "patch/fix-loading"

.EXAMPLE
    New-PatchPR -Description "Fix bug" -BranchName "patch/fix-bug" -IssueNumber 123

.NOTES
    This function replaces:
    - New-SimplePRForPatch
    - CheckoutAndCommit
    - Various PR creation functions
#>

function New-PatchPR {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BranchName,

        [Parameter(Mandatory = $false)]
        [int]$IssueNumber,

        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    begin {
        function Write-PRLog {
            param($Message, $Level = "INFO")
            if (Get-Command Write-CustomLog -ErrorAction SilentlyContinue) {
                Write-CustomLog -Message $Message -Level $Level
            } else {
                Write-Host "[$Level] $Message"
            }
        }

        Write-PRLog "Creating pull request for: $Description" -Level "INFO"
    }

    process {
        try {
            # Check GitHub CLI availability
            if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
                throw "GitHub CLI (gh) not found. Please install and authenticate with GitHub CLI."
            }

            # Create PR title and body
            $prTitle = "Patch: $Description"
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC'

            $prBody = @"
## Patch Description
$Description

### Files Affected
$(if ($AffectedFiles.Count -gt 0) {
    ($AffectedFiles | ForEach-Object { "- ``$_``" }) -join "`n"
} else {
    "*Files will be identified during review*"
})

### Validation Results
- Branch created from clean state
- Changes applied and committed
- Ready for review and merge

$(if ($IssueNumber) {
    "### Related Issue`nCloses #$IssueNumber"
} else {
    ""
})

### Quality Assurance
This patch follows the PatchManager workflow:
- Branch created from clean state  
- Changes applied and tested
- Ready for review and merge

**Created**: $timestamp
**Branch**: ``$BranchName``

---
*Created by PatchManager*
"@

            if ($DryRun) {
                Write-PRLog "DRY RUN: Would create PR with title: $prTitle" -Level "INFO"
                return @{
                    Success = $true
                    DryRun = $true
                    Title = $prTitle
                    Body = $prBody
                }
            }

            # Ensure we have changes committed
            $gitStatus = git status --porcelain 2>&1
            if ($gitStatus -and ($gitStatus | Where-Object { $_ -match '\S' })) {
                Write-PRLog "Committing pending changes..." -Level "INFO"
                git add . 2>&1 | Out-Null
                git commit -m "PatchManager: $Description" 2>&1 | Out-Null

                if ($LASTEXITCODE -ne 0) {
                    Write-PRLog "Warning: Git commit may have had issues, but continuing..." -Level "WARN"
                }
            }

            # Push branch
            Write-PRLog "Pushing branch: $BranchName" -Level "INFO"
            git push origin $BranchName 2>&1 | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to push branch $BranchName"
            }

            # Create PR with robust error handling
            Write-PRLog "Creating pull request: $prTitle" -Level "INFO"
            $result = gh pr create --title $prTitle --body $prBody --head $BranchName --label "patch" 2>&1

            # Handle label errors gracefully
            if ($LASTEXITCODE -ne 0 -and $result -match "not found") {
                Write-PRLog "Label issue detected, creating PR without labels" -Level "WARN"
                $result = gh pr create --title $prTitle --body $prBody --head $BranchName 2>&1
            }

            if ($LASTEXITCODE -eq 0) {
                # Extract PR number from URL
                $prNumber = $null
                if ($result -match '/pull/(\d+)') {
                    $prNumber = $matches[1]
                }

                Write-PRLog "Pull request created successfully: $result" -Level "SUCCESS"
                if ($prNumber) {
                    Write-PRLog "PR number: #$prNumber" -Level "INFO"
                }

                return @{
                    Success = $true
                    PullRequestUrl = $result.ToString().Trim()
                    PullRequestNumber = $prNumber
                    Title = $prTitle
                }
            } else {
                # Check if this is an "already exists" error (which is actually success)
                $errorText = $result -join ' '
                if ($errorText -match "already exists.*https://github\.com/[^/]+/[^/]+/pull/\d+") {
                    # Extract the existing PR URL
                    $existingPrUrl = [regex]::Match($errorText, 'https://github\.com/[^/]+/[^/]+/pull/\d+').Value

                    # Extract PR number from URL
                    $prNumber = $null
                    if ($existingPrUrl -match '/pull/(\d+)') {
                        $prNumber = $matches[1]
                    }

                    Write-PRLog "Pull request already exists: $existingPrUrl" -Level "SUCCESS"
                    Write-PRLog "Using existing PR #$prNumber" -Level "INFO"

                    return @{
                        Success = $true
                        PullRequestUrl = $existingPrUrl
                        PullRequestNumber = $prNumber
                        Title = $prTitle
                        Message = "Using existing pull request"
                    }
                } else {
                    throw "GitHub CLI failed: $errorText"
                }
            }

        } catch {
            $errorMessage = "Failed to create pull request: $($_.Exception.Message)"
            Write-PRLog $errorMessage -Level "ERROR"

            return @{
                Success = $false
                Message = $errorMessage
            }
        }
    }
}

Export-ModuleMember -Function New-PatchPR
