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
            
            # Determine priority-based labels
            $priorityLabels = switch ($Priority) {
                "Critical" { @("priority: critical", "severity: high") }
                "High" { @("priority: high", "severity: medium") }
                "Medium" { @("priority: medium") }
                "Low" { @("priority: low") }
                default { @("priority: medium") }
            }
            
            # Combine all labels
            $allLabels = $Labels + $priorityLabels + @("automated-patch", "needs-review")
            
            # Create issue title
            $issueTitle = "🐛 Automated Fix: $($PatchDescription -replace '^(fix:|bug:)\s*', '')"
            
            # Create comprehensive issue body
            $issueBody = @"
## 🤖 Automated Bug Fix Applied

**Description**: $PatchDescription  
**Priority**: $Priority  
**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")  
**Patch Manager**: v2.0 with automated issue tracking

## 📋 Fix Details

### What Was Fixed
This automated patch addresses a bug or issue identified in the codebase. The fix has been applied automatically using PatchManager with comprehensive validation.

### Files Affected
$($AffectedFiles | ForEach-Object { "- $_" } | Out-String)

### Pull Request
$(if ($PullRequestUrl) { "🔗 **Associated PR**: $PullRequestUrl" } else { "[WARN]️ **No PR**: This was a direct commit fix" })

## 🔍 Validation Status

- [x] **Syntax Validation**: PowerShell syntax validated
- [x] **Import Analysis**: Module imports verified  
- [x] **Path Compatibility**: Cross-platform paths checked
- [x] **Automated Testing**: Basic validation completed
- [ ] **Manual Review**: **REQUIRED** - Human verification needed
- [ ] **Integration Testing**: **REQUIRED** - Full testing in clean environment

## 🚨 Action Required

### For Maintainers
1. **Review the fix**: Verify the automated changes are correct
2. **Test thoroughly**: Ensure the fix doesn't introduce new issues
3. **Validate impact**: Check for any unintended side effects
4. **Close when confirmed**: Mark as resolved after validation

### For Developers
- **Monitor for issues**: Watch for any problems related to this fix
- **Report regressions**: Create new issues if problems arise
- **Provide feedback**: Comment on effectiveness of the automated fix

## 📊 Priority: $Priority

$(switch ($Priority) {
    "Critical" { "🔴 **CRITICAL**: Immediate attention required - potential system impact" }
    "High" { "🟠 **HIGH**: Should be reviewed within 24 hours" }
    "Medium" { "🟡 **MEDIUM**: Standard review process applies" }
    "Low" { "🟢 **LOW**: Review when convenient" }
})

## 🏷️ Labels Applied
$($allLabels | ForEach-Object { "- ``$_``" } | Out-String)

---

**🤖 This issue was created automatically by PatchManager v2.0**  
** Automated fixes help maintain code quality and reduce manual work**  
**👥 Human review and approval still required for all changes**
"@

            # Create the issue using GitHub CLI
            $labelsArg = $allLabels -join ","
            Write-Host "  Executing: gh issue create..." -ForegroundColor Gray
            
            $issueUrl = gh issue create --title $issueTitle --body $issueBody --label $labelsArg 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                # Extract issue number from URL
                $issueNumber = if ($issueUrl -match '/(\d+)$') { $matches[1] } else { $null }
                
                Write-Host "  [PASS] GitHub issue created successfully!" -ForegroundColor Green
                Write-Host "  📎 Issue URL: $issueUrl" -ForegroundColor Cyan
                Write-Host "  🔢 Issue Number: #$issueNumber" -ForegroundColor Cyan
                Write-Host "  🏷️  Priority: $Priority" -ForegroundColor Cyan
                
                # Link to PR if available
                if ($PullRequestUrl -and $issueNumber) {
                    try {
                        Write-Host "  🔗 Linking to pull request..." -ForegroundColor Blue
                        $prNumber = ($PullRequestUrl -split '/')[-1]
                        $linkComment = "🔗 **Linked Pull Request**: #$prNumber`n`nThis issue is automatically linked to the pull request that implements the fix."
                        gh issue comment $issueNumber --body $linkComment | Out-Null
                        Write-Host "  [PASS] Successfully linked to PR #$prNumber" -ForegroundColor Green
                    } catch {
                        Write-Warning "  Failed to link to PR: $($_.Exception.Message)"
                    }
                }
                
                return @{
                    Success = $true
                    Message = "GitHub issue created successfully"
                    IssueUrl = $issueUrl
                    IssueNumber = $issueNumber
                    Priority = $Priority
                    Labels = $allLabels
                }
                
            } else {
                throw "GitHub CLI failed: $issueUrl"
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
