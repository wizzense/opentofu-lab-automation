#Requires -Version 7.0
<#
.SYNOPSIS
GitHub Issue Tracking Integration for PSScriptAnalyzer and Testing Framework

.DESCRIPTION
Provides centralized GitHub issue tracking functionality for:
- PSScriptAnalyzer violations
- Test failures
- Syntax errors
- Build/CI issues

Integrates with PatchManager for controlled issue management.
#>

function Get-GitHubIssue {
    [CmdletBinding()]
    param(
        [string]$Title,
        [string]$Repository = $env:GITHUB_REPOSITORY,
        [string]$Token = $env:GITHUB_TOKEN
    )
    
    if (-not $Repository -or -not $Token) {
        Write-CustomLog "GitHub repository or token not configured" -Level WARN
        return $null
    }
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        $searchQuery = "repo:$Repository `"$Title`" in:title"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($searchQuery)
        $uri = "https://api.github.com/search/issues?q=$encodedQuery"
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        
        if ($response.total_count -gt 0) {
            return $response.items[0]
        }
        
        return $null
        
    } catch {
        Write-CustomLog "Error searching for GitHub issue: $_" -Level ERROR
        return $null
    }
}

function New-GitHubIssue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [hashtable]$Data,
        [string]$Repository = $env:GITHUB_REPOSITORY,
        [string]$Token = $env:GITHUB_TOKEN
    )
    
    if (-not $Repository -or -not $Token) {
        Write-CustomLog "GitHub repository or token not configured" -Level WARN
        return $null
    }
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'Content-Type' = 'application/json'
        }
        
        $issueBody = @{
            title = $Data.Title
            body = $Data.Body
            labels = $Data.Labels
        }
        
        # Add priority label based on severity
        if ($Data.Severity -eq 'Error') {
            $issueBody.labels += 'priority:high'
        } elseif ($Data.Severity -eq 'Warning') {
            $issueBody.labels += 'priority:medium'
        } else {
            $issueBody.labels += 'priority:low'
        }
        
        $uri = "https://api.github.com/repos/$Repository/issues"
        $jsonBody = $issueBody | ConvertTo-Json -Depth 3
        
        if ($PSCmdlet.ShouldProcess($Data.Title, "Create GitHub issue")) {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $jsonBody
            Write-CustomLog "Created GitHub issue #$($response.number): $($Data.Title)" -Level SUCCESS
            return $response
        }
        
    } catch {
        Write-CustomLog "Error creating GitHub issue: $_" -Level ERROR
        return $null
    }
}

function Update-GitHubIssue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        $Issue,
        [hashtable]$Data,
        [string]$Repository = $env:GITHUB_REPOSITORY,
        [string]$Token = $env:GITHUB_TOKEN
    )
    
    if (-not $Repository -or -not $Token) {
        Write-CustomLog "GitHub repository or token not configured" -Level WARN
        return $null
    }
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'Content-Type' = 'application/json'
        }
        
        # Add update timestamp to body
        $updatedBody = $Data.Body + "`n`n---`n**Updated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        $updateBody = @{
            body = $updatedBody
            labels = $Data.Labels
        }
        
        # Preserve existing labels and add new ones
        $existingLabels = $Issue.labels | ForEach-Object { $_.name }
        $allLabels = ($existingLabels + $Data.Labels) | Sort-Object -Unique
        $updateBody.labels = $allLabels
        
        $uri = "https://api.github.com/repos/$Repository/issues/$($Issue.number)"
        $jsonBody = $updateBody | ConvertTo-Json -Depth 3
        
        if ($PSCmdlet.ShouldProcess("Issue #$($Issue.number)", "Update GitHub issue")) {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -Body $jsonBody
            Write-CustomLog "Updated GitHub issue #$($Issue.number): $($Data.Title)" -Level INFO
            return $response
        }
        
    } catch {
        Write-CustomLog "Error updating GitHub issue: $_" -Level ERROR
        return $null
    }
}

function New-TestFailureIssue {
    [CmdletBinding()]
    param(
        [string]$TestName,
        [string]$FailureMessage,
        [string]$FilePath,
        [string]$TestFramework = "Pester"
    )
    
    $issueData = @{
        Title = "Test Failure: $TestName"
        Body = @"
## Test Failure Report

**Test Framework:** $TestFramework  
**Test Name:** $TestName  
**File:** $FilePath  

### Failure Details:
```
$FailureMessage
```

### Recommended Actions:
1. Review test implementation
2. Check for breaking changes in tested code
3. Update test expectations if needed
4. Verify test environment setup

### Auto-Generated Information:
- **Detection Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Framework:** $TestFramework
- **Integration:** Testing Framework

---
*This issue was automatically created by the testing framework.*
"@
        Labels = @("test-failure", $TestFramework.ToLower(), "automated")
        Severity = "Error"
    }
    
    return New-GitHubIssue -Data $issueData
}

function New-BuildFailureIssue {
    [CmdletBinding()]
    param(
        [string]$BuildType,
        [string]$FailureMessage,
        [string]$LogPath
    )
    
    $issueData = @{
        Title = "Build Failure: $BuildType"
        Body = @"
## Build Failure Report

**Build Type:** $BuildType  
**Log Path:** $LogPath  

### Failure Details:
```
$FailureMessage
```

### Recommended Actions:
1. Check build configuration
2. Verify dependencies
3. Review recent changes
4. Check CI/CD pipeline status

### Auto-Generated Information:
- **Detection Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Build System:** CI/CD
- **Integration:** Build Pipeline

---
*This issue was automatically created by the build system.*
"@
        Labels = @("build-failure", "ci-cd", "automated")
        Severity = "Error"
    }
    
    return New-GitHubIssue -Data $issueData
}

function Close-ResolvedIssues {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Labels = @("automated"),
        [string]$Repository = $env:GITHUB_REPOSITORY,
        [string]$Token = $env:GITHUB_TOKEN
    )
    
    if (-not $Repository -or -not $Token) {
        Write-CustomLog "GitHub repository or token not configured" -Level WARN
        return
    }
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        # Get open issues with specified labels
        $labelQuery = $Labels -join ","
        $searchQuery = "repo:$Repository state:open labels:$labelQuery"
        $encodedQuery = [System.Web.HttpUtility]::UrlEncode($searchQuery)
        $uri = "https://api.github.com/search/issues?q=$encodedQuery"
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        
        foreach ($issue in $response.items) {
            # Check if issue is resolved (placeholder logic - customize as needed)
            $isResolved = Test-IssueResolved -Issue $issue
            
            if ($isResolved) {
                if ($PSCmdlet.ShouldProcess("Issue #$($issue.number)", "Close resolved issue")) {
                    Close-GitHubIssue -Issue $issue -Repository $Repository -Token $Token
                }
            }
        }
        
    } catch {
        Write-CustomLog "Error checking for resolved issues: $_" -Level ERROR
    }
}

function Test-IssueResolved {
    param($Issue)
    
    # Placeholder logic - implement specific resolution checks
    # For PSScriptAnalyzer issues: re-run analysis and check if rule violations are gone
    # For test failures: check if tests are now passing
    # For build failures: check if builds are successful
    
    if ($Issue.labels | Where-Object { $_.name -eq "psscriptanalyzer" }) {
        # Check if PSScriptAnalyzer issues are resolved
        return Test-PSScriptAnalyzerIssueResolved -Issue $Issue
    }
    
    if ($Issue.labels | Where-Object { $_.name -eq "test-failure" }) {
        # Check if test is now passing
        return Test-TestFailureResolved -Issue $Issue
    }
    
    return $false
}

function Test-PSScriptAnalyzerIssueResolved {
    param($Issue)
    
    # Extract rule name from issue title
    if ($Issue.title -match "PSScriptAnalyzer: (.+) violations") {
        $ruleName = $Matches[1]
        
        # Re-run PSScriptAnalyzer to check if violations still exist
        try {
            $currentIssues = Invoke-ScriptAnalyzer -Path $env:PROJECT_ROOT -Recurse -IncludeRule $ruleName
            return $currentIssues.Count -eq 0
        } catch {
            return $false
        }
    }
    
    return $false
}

function Test-TestFailureResolved {
    param($Issue)
    
    # Extract test information from issue
    # This would need to be customized based on your test naming conventions
    # For now, return false to keep issues open for manual review
    return $false
}

function Close-GitHubIssue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        $Issue,
        [string]$Repository = $env:GITHUB_REPOSITORY,
        [string]$Token = $env:GITHUB_TOKEN
    )
    
    try {
        $headers = @{
            'Authorization' = "token $Token"
            'Accept' = 'application/vnd.github.v3+json'
            'Content-Type' = 'application/json'
        }
        
        $closeBody = @{
            state = "closed"
        }
        
        $uri = "https://api.github.com/repos/$Repository/issues/$($Issue.number)"
        $jsonBody = $closeBody | ConvertTo-Json
        
        if ($PSCmdlet.ShouldProcess("Issue #$($Issue.number)", "Close GitHub issue")) {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Patch -Body $jsonBody
            Write-CustomLog "Closed resolved GitHub issue #$($Issue.number)" -Level SUCCESS
            return $response
        }
        
    } catch {
        Write-CustomLog "Error closing GitHub issue: $_" -Level ERROR
    }
}

# Export functions for module usage
Export-ModuleMember -Function @(
    'Get-GitHubIssue',
    'New-GitHubIssue', 
    'Update-GitHubIssue',
    'New-TestFailureIssue',
    'New-BuildFailureIssue',
    'Close-ResolvedIssues',
    'Test-IssueResolved',
    'Close-GitHubIssue'
)
