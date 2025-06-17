# Helper functions for enhanced GitHub label management
function Test-GitHubLabelValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LabelName
    )
    
    # GitHub label name restrictions:
    # - Cannot contain certain special characters
    # - Length limits (typically 50 characters)
    # - Cannot be empty
    
    if ([string]::IsNullOrWhiteSpace($LabelName)) {
        return $false
    }
    
    if ($LabelName.Length -gt 50) {
        return $false
    }
    
    # Check for invalid characters (GitHub typically rejects some special chars)
    if ($LabelName -match '[<>\\/:"|?*]') {
        return $false
    }
    
    return $true
}

function Get-GitHubLabelConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LabelName
    )
    
    # Enhanced label configuration with semantic colors and descriptions
    $config = switch ($LabelName) {
        "bug" { 
            @{ Color = "d73a4a"; Description = "Something isn't working" }
        }
        "automated" { 
            @{ Color = "0075ca"; Description = "Created automatically by PatchManager" }
        }
        "high-priority" { 
            @{ Color = "b60205"; Description = "High priority issue requiring immediate attention" }
        }
        "priority" { 
            @{ Color = "d93f0b"; Description = "Priority issue requiring prompt attention" }
        }
        "minor" { 
            @{ Color = "c2e0c6"; Description = "Minor issue or enhancement" }
        }
        "critical" {
            @{ Color = "8b0000"; Description = "Critical issue requiring immediate action" }
        }
        "enhancement" {
            @{ Color = "a2eeef"; Description = "New feature or request" }
        }
        "documentation" {
            @{ Color = "0075ca"; Description = "Improvements or additions to documentation" }
        }
        "testing" {
            @{ Color = "5319e7"; Description = "Testing related changes" }
        }
        default { 
            @{ Color = "fbca04"; Description = "Auto-created label for $LabelName" }
        }
    }
    
    return $config
}

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
            Write-Host "  GitHub CLI (gh) not found - skipping issue creation" -ForegroundColor Gray
            $script:shouldSkip = $true
            $script:skipReason = @{
                Success = $false
                Message = "GitHub CLI (gh) not found. Cannot create issues automatically."
                IssueUrl = $null
                IssueNumber = $null
            }
            return
        }
        
        # Enhanced repository validation with better error handling
        try {
            # Check if we're in a git repository
            $gitRepo = git config --get remote.origin.url 2>&1
            if ($LASTEXITCODE -ne 0 -or -not $gitRepo) {
                Write-Host "  Not in a git repository - skipping issue creation" -ForegroundColor Gray
                $script:shouldSkip = $true
                $script:skipReason = @{
                    Success = $false
                    Message = "Not in a git repository"
                    IssueUrl = $null
                    IssueNumber = $null
                }
                return
            }
            
            # Check if it's a GitHub repository
            if ($gitRepo -notmatch "github\.com") {
                Write-Host "  Not a GitHub repository - skipping issue creation" -ForegroundColor Gray
                $script:shouldSkip = $true
                $script:skipReason = @{
                    Success = $false
                    Message = "Not a GitHub repository"
                    IssueUrl = $null
                    IssueNumber = $null
                }
                return
            }
            
            # Verify GitHub CLI authentication and repository access
            $repoAccess = gh auth status 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  GitHub CLI not authenticated - skipping issue creation" -ForegroundColor Gray
                $script:shouldSkip = $true
                $script:skipReason = @{
                    Success = $false
                    Message = "GitHub CLI not authenticated"
                    IssueUrl = $null
                    IssueNumber = $null
                }
                return
            }
            
            # Test repository access with a simple command
            $repoTest = gh repo view --json name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  Cannot access GitHub repository - skipping issue creation" -ForegroundColor Gray
                $script:shouldSkip = $true
                $script:skipReason = @{
                    Success = $false
                    Message = "Cannot access GitHub repository (check permissions)"
                    IssueUrl = $null
                    IssueNumber = $null
                }
                return
            }
        }
        catch {
            Write-Host "  Repository validation failed - skipping issue creation" -ForegroundColor Gray
            $script:shouldSkip = $true
            $script:skipReason = @{
                Success = $false
                Message = "Repository validation failed: $($_.Exception.Message)"
                IssueUrl = $null
                IssueNumber = $null
            }
            return
        }
        
        # Detect if this is a bug fix
        $isBugFix = $PatchDescription -match '\b(fix|bug|error|issue|problem|broken|critical|urgent|emergency)\b' -or $ForceCreate
        
        if (-not $isBugFix -and -not $ForceCreate) {
            Write-Host "  Not a bug fix - skipping issue creation" -ForegroundColor Gray
            $script:shouldSkip = $true
            $script:skipReason = @{
                Success = $true
                Message = "Skipped issue creation - not a bug fix"
                IssueUrl = $null
                IssueNumber = $null
            }
            return
        }
        
        $script:shouldSkip = $false
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
                "Critical" { @("high-priority") }
                "High" { @("priority") }
                "Medium" { @() }  # No additional labels for medium
                "Low" { @("minor") }
                default { @() }
            }
            
            # Combine all labels and remove duplicates
            $allLabels = ($Labels + $priorityLabels + @("automated")) | Sort-Object -Unique            # Robustly create any missing labels before issue creation with enhanced error handling
            $validLabels = @()
            $labelCreationErrors = @()
            
            foreach ($label in $allLabels) {
                Write-Host "  Checking if label '$label' exists..." -ForegroundColor Gray
                
                # Validate label name against GitHub restrictions
                if (-not (Test-GitHubLabelValidity -LabelName $label)) {
                    Write-Warning "  Label '$label' contains invalid characters - skipping"
                    $labelCreationErrors += "Invalid label name: $label"
                    continue
                }
                
                # Check if label exists with enhanced error handling
                $labelExists = $false
                try {
                    # Primary method: JSON-based check
                    $existingLabelsResult = gh label list --json name 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $existingLabels = $existingLabelsResult | ConvertFrom-Json
                        $labelExists = $existingLabels | Where-Object { $_.name -eq $label }
                    }
                    else {
                        # Fallback: Check exit code and output
                        Write-Host "    JSON method failed, using fallback..." -ForegroundColor Gray
                        $labelOutput = gh label list 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            $labelExists = $labelOutput -match "^$([regex]::Escape($label))\s"
                        }
                        else {
                            Write-Warning "  Could not retrieve existing labels: $labelOutput"
                            # Assume label doesn't exist and try to create it
                            $labelExists = $false
                        }
                    }
                }
                catch {
                    Write-Host "    Label existence check failed, assuming label doesn't exist..." -ForegroundColor Gray
                    $labelExists = $false
                }
                
                if (-not $labelExists) {
                    try {
                        Write-Host "  Creating missing label: $label" -ForegroundColor Yellow
                        
                        # Enhanced label configuration with better defaults
                        $labelConfig = Get-GitHubLabelConfiguration -LabelName $label
                        
                        # Attempt to create the label with retry logic
                        $createAttempts = 0
                        $maxAttempts = 3
                        $createSuccess = $false
                        
                        while ($createAttempts -lt $maxAttempts -and -not $createSuccess) {
                            $createAttempts++
                            Write-Host "    Attempt $createAttempts of $maxAttempts..." -ForegroundColor Gray
                            
                            $createResult = gh label create $label --color $labelConfig.Color --description $labelConfig.Description 2>&1
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "  Successfully created label: $label" -ForegroundColor Green
                                $validLabels += $label
                                $createSuccess = $true
                            }
                            elseif ($createResult -match "already exists") {
                                Write-Host "  Label '$label' already exists (concurrent creation)" -ForegroundColor Gray
                                $validLabels += $label
                                $createSuccess = $true
                            }
                            elseif ($createResult -match "(rate limit|try again|timeout)") {
                                Write-Host "    Rate limited or timeout, waiting before retry..." -ForegroundColor Yellow
                                Start-Sleep -Seconds (2 * $createAttempts)
                            }
                            else {
                                Write-Warning "  Could not create label '$label' (attempt $createAttempts): $createResult"
                                if ($createAttempts -eq $maxAttempts) {
                                    $labelCreationErrors += "Failed to create label '$label': $createResult"
                                }
                            }
                        }
                    }
                    catch {
                        Write-Warning "  Exception creating label '$label': $($_.Exception.Message)"
                        $labelCreationErrors += "Exception creating label '$label': $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Host "  Label '$label' already exists" -ForegroundColor Gray
                    $validLabels += $label
                }
            }
            
            # Log label creation summary
            if ($labelCreationErrors.Count -gt 0) {
                Write-Warning "  Label creation encountered $($labelCreationErrors.Count) errors:"
                $labelCreationErrors | ForEach-Object { Write-Warning "    $_" }
            }            
            Write-Host "  Successfully validated/created $($validLabels.Count) of $($allLabels.Count) labels" -ForegroundColor Cyan
            
            # Update labels list to only include successfully verified/created labels
            $allLabels = $validLabels# Create comprehensive GitHub issue (NO EMOJIS - project policy)
            $title = "PatchManager: $PatchDescription"
              # Create detailed issue body with full context
            $prLinkText = if ($PullRequestUrl) { 
                "`n**Pull Request**: $PullRequestUrl"
            } else { 
                "`n**Pull Request**: Will be linked when created" 
            }
            
            $body = @"
## Automated Patch Issue

**Patch Description**: $PatchDescription
**Priority**: $Priority
**Created**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')
**PatchManager Version**: v2.0$prLinkText

### Affected Files
$($AffectedFiles | ForEach-Object { "- ``$_``" } | Out-String)

### Patch Details
- **Type**: $(if ($PatchDescription -match '\b(fix|bug)\b') { 'Bug Fix' } elseif ($PatchDescription -match '\b(feat|feature)\b') { 'Feature' } elseif ($PatchDescription -match '\b(chore|maintenance)\b') { 'Maintenance' } else { 'General Patch' })
- **Auto-generated**: Yes
- **Manual Review Required**: Yes

### Expected Actions

1. **Review the pull request** $(if ($PullRequestUrl) { "at $PullRequestUrl" } else { "(will be linked when created)" })
2. **Validate changes** in a clean environment  
3. **Test functionality** to ensure no regressions
4. **Approve and merge** if all validations pass
5. **Close this issue** after successful merge

### Automation Status

- [x] Patch applied successfully
- $(if ($PullRequestUrl) { '[x]' } else { '[ ]' }) Pull request $(if ($PullRequestUrl) { 'created' } else { 'pending' })
- [ ] Awaiting human review and approval

**Note**: This issue was created automatically by PatchManager to track the patch lifecycle and ensure proper review process.
"@
              # Ensure we have at least one valid label for the issue
            if ($allLabels.Count -eq 0) {
                Write-Warning "  No valid labels available, using default 'automated' label"
                # Try to create a minimal automated label as fallback
                try {
                    gh label create "automated" --color "0075ca" --description "Automated by PatchManager" 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) {
                        $allLabels = @("automated")
                    }
                }
                catch {
                    Write-Warning "  Could not create fallback label, proceeding without labels"
                    $allLabels = @()
                }
            }
            
            $labelString = if ($allLabels.Count -gt 0) { $allLabels -join ',' } else { "" }
            Write-Host "  Creating issue with title: $title" -ForegroundColor Cyan
            if ($labelString) {
                Write-Host "  Labels: $labelString" -ForegroundColor Gray
            } else {
                Write-Host "  No labels will be applied" -ForegroundColor Gray
            }# Create issue using proper parameter passing to avoid command line issues
            Write-Host "  Creating GitHub issue..." -ForegroundColor Cyan
            
            try {
                # Save body to temp file to avoid command line issues
                $tempBodyFile = [System.IO.Path]::GetTempFileName()
                $body | Out-File -FilePath $tempBodyFile -Encoding utf8
                  # Create issue with file-based body and handle labels appropriately
                if ($labelString) {
                    $issueResult = gh issue create --title $title --body-file $tempBodyFile --label $labelString
                } else {
                    $issueResult = gh issue create --title $title --body-file $tempBodyFile
                }
                
                # Clean up temp file
                Remove-Item $tempBodyFile -Force -ErrorAction SilentlyContinue
                  } catch {
                Write-Host "  Falling back to simple body..." -ForegroundColor Yellow
                # Fallback to simple body if file method fails
                $prText = if ($PullRequestUrl) { "`nPull Request: $PullRequestUrl" } else { "" }
                $simpleBody = "Automated patch: $PatchDescription`nAffected files: $($AffectedFiles -join ', ')$prText`nCreated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
                if ($labelString) {
                    $issueResult = gh issue create --title $title --body $simpleBody --label $labelString
                } else {
                    $issueResult = gh issue create --title $title --body $simpleBody
                }
            }
            
            if ($LASTEXITCODE -eq 0 -and $issueResult) {
                Write-Host "  GitHub issue created successfully: $issueResult" -ForegroundColor Green
                
                # Extract issue number from the URL
                # GitHub CLI returns URL like: https://github.com/owner/repo/issues/123
                $issueNumber = $null
                if ($issueResult -match '/issues/(\d+)') {
                    $issueNumber = $matches[1]
                    Write-Host "  Issue number extracted: #$issueNumber" -ForegroundColor Cyan
                }
                
                return @{
                    Success = $true
                    Message = "GitHub issue created successfully"
                    IssueUrl = $issueResult
                    IssueNumber = $issueNumber
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

