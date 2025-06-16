function Format-PatchOutput {
    <#
    .SYNOPSIS
    Formats patch operation output with improved readability and actionable information
    
    .DESCRIPTION
    Creates well-formatted, informative output for patch operations including
    validation results, affected files, and next steps.
    
    .PARAMETER PatchDescription
    Description of the patch
    
    .PARAMETER BranchName
    Git branch name
    
    .PARAMETER AffectedFiles
    List of files affected by the patch
    
    .PARAMETER ValidationResults
    Results from validation operations
    
    .PARAMETER CommitHash
    Git commit hash
    
    .PARAMETER PullRequestUrl
    URL of created pull request
    
    .PARAMETER PullRequestNumber
    Pull request number
    
    .PARAMETER Success
    Whether the operation was successful
    
    .PARAMETER Warnings
    List of warnings to display
    
    .PARAMETER NextSteps
    Suggested next steps for the user
    
    .EXAMPLE
    Format-PatchOutput -PatchDescription "feat: new feature" -BranchName "patch/feature" -Success $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatchDescription,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$AffectedFiles = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationResults = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $false)]
        [string]$PullRequestUrl,
        
        [Parameter(Mandatory = $false)]
        [int]$PullRequestNumber,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Warnings = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$NextSteps = @()
    )
    
    # Header with status
    $statusIcon = if ($Success) { "✓" } else { "✗" }
    $statusColor = if ($Success) { "Green" } else { "Red" }
    $statusText = if ($Success) { "SUCCESS" } else { "FAILED" }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host " $statusIcon PATCH OPERATION $statusText" -ForegroundColor $statusColor
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    
    # Patch Details
    Write-Host "PATCH DETAILS" -ForegroundColor Cyan
    Write-Host "  Description: $PatchDescription" -ForegroundColor White
    if ($BranchName) {
        Write-Host "  Branch: $BranchName" -ForegroundColor White
    }
    if ($CommitHash) {
        Write-Host "  Commit: $($CommitHash.Substring(0,8))" -ForegroundColor White
    }
    Write-Host ""
    
    # Affected Files (if any)
    if ($AffectedFiles.Count -gt 0) {
        Write-Host "📁 AFFECTED FILES ($($AffectedFiles.Count))" -ForegroundColor Cyan
        $AffectedFiles | ForEach-Object {
            $relativePath = $_ -replace [regex]::Escape($env:PROJECT_ROOT), "."
            Write-Host "  • $relativePath" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Validation Results
    if ($ValidationResults.Count -gt 0) {
        Write-Host "🔍 VALIDATION RESULTS" -ForegroundColor Cyan
        
        foreach ($key in $ValidationResults.Keys) {
            $result = $ValidationResults[$key]
            if ($result -is [hashtable] -and $result.ContainsKey('Success')) {
                $icon = if ($result.Success) { "✓" } else { "✗" }
                $color = if ($result.Success) { "Green" } else { "Red" }
                Write-Host "  $icon $key" -ForegroundColor $color
                
                if ($result.ContainsKey('Details') -and $result.Details) {
                    Write-Host "    $($result.Details)" -ForegroundColor Gray
                }
            } else {
                Write-Host "  • $key`: $result" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Pull Request Information
    if ($PullRequestUrl) {
        Write-Host "🔗 PULL REQUEST" -ForegroundColor Cyan
        Write-Host "  Number: #$PullRequestNumber" -ForegroundColor White
        Write-Host "  URL: $PullRequestUrl" -ForegroundColor Blue
        Write-Host ""
    }
    
    # Warnings (if any)
    if ($Warnings.Count -gt 0) {
        Write-Host "⚠️  WARNINGS" -ForegroundColor Yellow
        $Warnings | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Next Steps
    if ($NextSteps.Count -gt 0) {
        Write-Host "🎯 NEXT STEPS" -ForegroundColor Magenta
        $NextSteps | ForEach-Object {
            Write-Host "  • $_" -ForegroundColor White
        }
    } elseif ($Success) {
        Write-Host "🎯 NEXT STEPS" -ForegroundColor Magenta
        if ($PullRequestUrl) {
            Write-Host "  • Review and merge the pull request: $PullRequestUrl" -ForegroundColor White
            Write-Host "  • Monitor for Copilot suggestions and automatic implementation" -ForegroundColor White
            Write-Host "  • Branch will be auto-cleaned after PR merge" -ForegroundColor White
        } else {
            Write-Host "  • Commit your changes manually if needed" -ForegroundColor White
            Write-Host "  • Run tests to validate the changes" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    # Return structured result for programmatic use
    return @{
        Success = $Success
        PatchDescription = $PatchDescription
        BranchName = $BranchName
        AffectedFiles = $AffectedFiles
        ValidationResults = $ValidationResults
        CommitHash = $CommitHash
        PullRequestUrl = $PullRequestUrl
        PullRequestNumber = $PullRequestNumber
        Warnings = $Warnings
        NextSteps = $NextSteps
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
}
