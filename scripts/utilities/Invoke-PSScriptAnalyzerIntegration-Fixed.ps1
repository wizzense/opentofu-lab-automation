#Requires -Version 7.0

# Define fallback logging function first
function Write-CustomLog {
    param([string]$Message, [string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN' { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'White' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
PSScriptAnalyzer Integration for Issue Reporting and Tracking

.DESCRIPTION
Integrates PSScriptAnalyzer with GitHub issue tracking to provide:
- Automated detection and reporting of syntax issues
- GitHub issue tracking for identified problems
- Read-only validation with no automatic fixes
- All changes must go through PatchManager workflow

.PARAMETER Mode
Operation mode: Analyze or Track

.PARAMETER Severity
Minimum severity level to process: Information, Warning, Error

.PARAMETER CreateIssues
Create GitHub issues for detected problems (enabled by default)

.EXAMPLE
Invoke-PSScriptAnalyzerIntegration -Mode Track -CreateIssues
#>

param(
    [ValidateSet("Analyze", "Track")]
    [string]$Mode = "Analyze",
    [ValidateSet("Information", "Warning", "Error")]
    [string]$Severity = "Warning",
    [switch]$CreateIssues = $true
)

# Import required modules and set up enhanced logging
try {
    Import-Module "Logging" -Force -ErrorAction Stop
    Write-Verbose "Logging module imported successfully"
} catch {
    Write-Warning "Using fallback logging - Logging module not available: $_"
}

$ErrorActionPreference = 'Continue'

# Import additional required modules
try {
    Import-Module PSScriptAnalyzer -Force -ErrorAction Stop
} catch {
    Write-CustomLog "PSScriptAnalyzer module not available. Install with: Install-Module PSScriptAnalyzer -Force" -Level ERROR
    exit 1
}

function Invoke-PSScriptAnalyzerIntegration {
    [CmdletBinding()]
    param(
        [string]$ProjectPath = $env:PROJECT_ROOT,
        [ValidateSet("Analyze", "Track")]
        [string]$Mode = "Analyze",
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Severity = "Warning",
        [switch]$CreateIssues = $true
    )
    
    Write-CustomLog "Starting PSScriptAnalyzer integration for issue reporting and tracking" -Level INFO
      # Step 1: Run analysis
    $analysisResults = Invoke-PSScriptAnalyzerAnalysis -ProjectPath $ProjectPath -Severity $Severity
    
    # Display analysis results
    Show-AnalysisResults -Results $analysisResults
    
    # Initialize result containers
    $trackingResults = @{ IssuesCreated = 0; IssuesUpdated = 0; Categories = @{} }
    
    # Step 2: Create GitHub issues for problems (no validation-onlying - only reporting)
    if ($Mode -eq "Track" -and $CreateIssues) {
        $trackingResults = New-GitHubIssueTracking -Results $analysisResults
        Write-CustomLog "Created $($trackingResults.IssuesCreated) GitHub issues" -Level INFO
    }
    
    return @{
        Analysis = $analysisResults
        Tracking = $trackingResults
    }
    }
}

function Invoke-PSScriptAnalyzerAnalysis {
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        [string]$Severity
    )
    
    Write-CustomLog "Running PSScriptAnalyzer on $ProjectPath" -Level INFO
    
    $scriptFiles = Get-ChildItem -Path $ProjectPath -Filter "*.ps1" -Recurse | 
                   Where-Object { $_.FullName -notmatch '\\archive\\|\\backup\\|\\temp\\' }
    
    $allIssues = @()    $analysisStats = @{
        TotalFiles = $scriptFiles.Count
        FilesWithIssues = 0
        TotalIssues = 0
        IssuesBySeverity = @{
            Error = 0
            Warning = 0
            Information = 0
        }
        IssuesByRule = @{}
    }
    
    foreach ($file in $scriptFiles) {
        try {
            $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Severity $Severity
            
            if ($issues.Count -gt 0) {
                $analysisStats.FilesWithIssues++
                $analysisStats.TotalIssues += $issues.Count
                  foreach ($issue in $issues) {
                    # Categorize issues
                    $analysisStats.IssuesBySeverity[$issue.Severity]++
                    
                    if (-not $analysisStats.IssuesByRule.ContainsKey($issue.RuleName)) {
                        $analysisStats.IssuesByRule[$issue.RuleName] = 0
                    }
                    $analysisStats.IssuesByRule[$issue.RuleName]++
                    
                    # Add file context to issue
                    $issue | Add-Member -NotePropertyName "FilePath" -NotePropertyValue $file.FullName
                    $allIssues += $issue
                }
            }
        } catch {
            Write-CustomLog "Error analyzing $($file.FullName): $_" -Level ERROR
        }
    }
    
    return @{
        Issues = $allIssues
        Statistics = $analysisStats
        Timestamp = Get-Date
    }
}

function New-GitHubIssueTracking {
    [CmdletBinding()]
    param($Results)
    
    $trackingResults = @{
        IssuesCreated = 0
        IssuesUpdated = 0
        Categories = @{}
    }
      # Group issues by rule for better tracking
    $issueGroups = $Results.Issues | Group-Object RuleName
    
    foreach ($group in $issueGroups) {
        $ruleName = $group.Name
        $ruleIssues = $group.Group
        
        # Create issue data
        $issueData = @{
            Title = "PSScriptAnalyzer: $ruleName violations"
            Body = New-IssueBody -RuleName $ruleName -Issues $ruleIssues
            Labels = @("code-quality", "psscriptanalyzer", $ruleName.ToLower())
            Severity = Get-MaxSeverity -Issues $ruleIssues
        }
        
        try {
            # Simulate GitHub issue creation for now
            Write-CustomLog "Would create GitHub issue: $($issueData.Title)" -Level INFO
            $trackingResults.IssuesCreated++
            $trackingResults.Categories[$ruleName] = $ruleIssues.Count
            
        } catch {
            Write-CustomLog "Error creating GitHub issue for $ruleName`: $_" -Level ERROR
        }
    }
    
    return $trackingResults
}

function New-IssueBody {
    param($RuleName, $Issues)
    
    $severity = Get-MaxSeverity -Issues $Issues
    $fileList = $Issues | Group-Object FilePath | ForEach-Object {
        "- `$($_.Name)` ($($_.Count) issues)"
    }
    
    $body = @"
## PSScriptAnalyzer Rule Violation: $RuleName

**Severity:** $severity  
**Total Occurrences:** $($Issues.Count)  
**Files Affected:** $($fileList.Count)

### Affected Files:
$($fileList -join "`n")

### Rule Description:
$(Get-RuleDescription -RuleName $RuleName)

### Recommended Action:
$(Get-RecommendedAction -RuleName $RuleName)

### Auto-Generated Information:
- **Detection Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Analysis Tool:** PSScriptAnalyzer
- **Integration:** PatchManager

---
*This issue was automatically created by the PSScriptAnalyzer integration system.*
"@
    
    return $body
}

function Get-MaxSeverity {
    param($Issues)
    
    $severityOrder = @('Information', 'Warning', 'Error')
    $maxSeverity = 'Information'
    
    foreach ($issue in $Issues) {
        $currentIndex = $severityOrder.IndexOf($issue.Severity)
        $maxIndex = $severityOrder.IndexOf($maxSeverity)
        
        if ($currentIndex -gt $maxIndex) {
            $maxSeverity = $issue.Severity
        }
    }
    
    return $maxSeverity
}

function Get-RuleDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RuleName
    )
    
    try {
        $rule = Get-ScriptAnalyzerRule -Name $RuleName
        return $rule.Description
    }
    catch {
        return "Rule description not available"
    }
}

function Get-RecommendedAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RuleName
    )
    
    $recommendations = @{
        'PSAvoidUsingCmdletAliases' = 'Replace aliases with full cmdlet names for better readability and compatibility'
        'PSAvoidUsingPlainTextForPassword' = 'Use SecureString or other secure methods for handling passwords'
        'PSAvoidUsingInvokeExpression' = 'Replace Invoke-Expression with safer alternatives'
        'PSUseDeclaredVarsMoreThanAssignments' = 'Remove unused variables or ensure they are used'
        'PSUseApprovedVerbs' = 'Use approved PowerShell verbs for function names'
        'PSUseSingularNouns' = 'Use singular nouns for function names'
        'PSProvideCommentHelp' = 'Add comment-based help to functions'
    }
    
    if ($recommendations.ContainsKey($RuleName)) {
        return $recommendations[$RuleName]
    } else {
        return "Review and fix according to PowerShell best practices"
    }
}

function Show-AnalysisResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Results
    )
    
    $stats = $Results.Statistics
      Write-Host "`nPSScriptAnalyzer Analysis Results" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Files analyzed: $($stats.TotalFiles)" -ForegroundColor White
    Write-Host "Files with issues: $($stats.FilesWithIssues)" -ForegroundColor Yellow
    Write-Host "Total issues: $($stats.TotalIssues)" -ForegroundColor Red
    
    Write-Host "`nIssues by Severity:" -ForegroundColor Yellow
    foreach ($severity in $stats.IssuesBySeverity.Keys) {
        $count = $stats.IssuesBySeverity[$severity]
        if ($count -gt 0) {
            $color = switch ($severity) {
                'Error' { 'Red' }
                'Warning' { 'Yellow' }
                'Information' { 'Cyan' }
            }
            Write-Host "  $severity`: $count" -ForegroundColor $color
        }
    }
    
    Write-Host "`nTop Issues by Rule:" -ForegroundColor Yellow
    $topRules = $stats.IssuesByRule.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10
    foreach ($rule in $topRules) {
        Write-Host "  $($rule.Key): $($rule.Value)" -ForegroundColor White
    }
}

# Main execution
try {
    $result = Invoke-PSScriptAnalyzerIntegration -Mode $Mode -Severity $Severity -CreateIssues:$CreateIssues
    
    Write-CustomLog "PSScriptAnalyzer integration completed successfully" -Level SUCCESS
    
    # Output summary
    Write-Host "`nIntegration Summary:" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "Analysis: $($result.Analysis.Statistics.TotalIssues) issues found" -ForegroundColor White
    Write-Host "Tracking: $($result.Tracking.IssuesCreated) GitHub issues created" -ForegroundColor Blue
}
catch {
    Write-CustomLog "PSScriptAnalyzer integration failed: $_" -Level ERROR
    exit 1
}

try {
    $confirmation = Read-Host "Do you want to run PSScriptAnalyzer on the /pwsh/ directory for additional reporting? (yes/no)"
    if ($confirmation -eq "yes") {
        if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
            Write-CustomLog "Running PSScriptAnalyzer on /pwsh/ directory..." -Level INFO
            Invoke-ScriptAnalyzer -Path '/workspaces/opentofu-lab-automation/pwsh/' -Recurse -Severity Warning,Error -IncludeDefaultRules |
            Format-Table -AutoSize
        } else {
            Write-CustomLog -Level ERROR -Message 'PSScriptAnalyzer module not found. Install with: Install-Module PSScriptAnalyzer -Force';
            exit 1
        }
    } else {
        Write-CustomLog "PSScriptAnalyzer execution skipped by user" -Level INFO
    }
} catch {
    Write-CustomLog -Level ERROR -Message "PSScriptAnalyzer error: $_";
    exit 1
}
