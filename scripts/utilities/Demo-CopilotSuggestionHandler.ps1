#Requires -Version 7.0
<#
.SYNOPSIS
    Demonstrates automated Copilot suggestion implementation capabilities
    
.DESCRIPTION
    This script shows how PatchManager can automatically monitor GitHub PRs
    for Copilot review comments and implement the suggestions automatically.
    
.PARAMETER PullRequestNumber
    The PR number to monitor (optional, defaults to finding recent PRs)
    
.PARAMETER Repository
    The repository to monitor
    
.PARAMETER Mode
    Test mode - WhatIf shows what would be done, Live implements changes
    
.EXAMPLE
    ./Demo-CopilotSuggestionHandler.ps1 -PullRequestNumber 123 -Mode WhatIf
    
.NOTES
    This script demonstrates the new automated Copilot suggestion handling
    capability in PatchManager v2.0
#>

CmdletBinding()
param(
    Parameter(Mandatory = $false)
    int$PullRequestNumber,
    
    Parameter(Mandatory = $false)
    string$Repository = "wizzense/opentofu-lab-automation",
    
    Parameter(Mandatory = $false)
    ValidateSet("WhatIf", "Live", "Demo")
    string$Mode = "Demo"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Copilot Suggestion Handler Demo ===" -ForegroundColor Cyan
Write-Host "Repository: $Repository" -ForegroundColor Green
Write-Host "Mode: $Mode" -ForegroundColor Yellow

# Import PatchManager with new Copilot functionality
try {
    Import-Module "$($env:PWSH_MODULES_PATH -replace '\\', '/')/PatchManager" -Force
    Write-Host " PatchManager module loaded successfully" -ForegroundColor Green
} catch {
    Write-Warning "Failed to load PatchManager module: $($_.Exception.Message)"
    Write-Host "Attempting fallback import..." -ForegroundColor Yellow
    Import-Module "./pwsh/modules/PatchManager" -Force
}

# Check if GitHub CLI is available
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Warning "GitHub CLI is required for Copilot suggestion handling"
    Write-Host "Please install GitHub CLI and authenticate with 'gh auth login'" -ForegroundColor Yellow
    exit 1
}

try {
    switch ($Mode) {
        "Demo" {
            Write-Host "`n--- DEMO MODE: Showing Copilot Integration Capabilities ---" -ForegroundColor Cyan
            
            Write-Host "`n1. Finding recent pull requests..." -ForegroundColor Yellow
            $recentPRs = gh api "repos/$Repository/pulls?state=open&per_page=5" | ConvertFrom-Jsonif ($recentPRs.Count -gt 0) {
                Write-Host "Found $($recentPRs.Count) open pull requests:" -ForegroundColor Green
                foreach ($pr in $recentPRs) {
                    Write-Host "  #$($pr.number): $($pr.title)" -ForegroundColor White
                }
                
                # Use the provided PR number or the first one found
                $targetPR = if ($PullRequestNumber) { $PullRequestNumber } else { $recentPRs0.number }
                
                Write-Host "`n2. Checking PR #$targetPR for Copilot suggestions..." -ForegroundColor Yellow
                
                # Demo the suggestion handler in WhatIf mode
                $result = Invoke-CopilotSuggestionHandler -PullRequestNumber $targetPR -Repository $Repository -WhatIf -ValidateAfterFix
                
                Write-Host "`n3. Demo Results:" -ForegroundColor Green
                Write-Host "   Success: $($result.Success)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
                Write-Host "   Message: $($result.Message)" -ForegroundColor White
                if ($result.ImplementedCount) {
                    Write-Host "   Would implement: $($result.ImplementedCount) suggestions" -ForegroundColor Cyan
                }
                
            } else {
                Write-Host "No open pull requests found" -ForegroundColor Yellow
            }
        }
        
        "WhatIf" {
            if (-not $PullRequestNumber) {
                throw "PullRequestNumber is required for WhatIf mode"
            }
            
            Write-Host "`n--- WHAT-IF MODE: Analyzing PR #$PullRequestNumber ---" -ForegroundColor Cyan
            
            $result = Invoke-CopilotSuggestionHandler -PullRequestNumber $PullRequestNumber -Repository $Repository -WhatIf -ValidateAfterFix
            
            Write-Host "`nResults:" -ForegroundColor Green
            Write-Host "  Success: $($result.Success)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
            Write-Host "  Message: $($result.Message)" -ForegroundColor White
            Write-Host "  Would implement: $($result.ImplementedCount) suggestions" -ForegroundColor Cyan
            Write-Host "  Would fail: $($result.FailedCount) suggestions" -ForegroundColor Red
        }
        
        "Live" {
            if (-not $PullRequestNumber) {
                throw "PullRequestNumber is required for Live mode"
            }
            
            Write-Host "`n--- LIVE MODE: Implementing PR #$PullRequestNumber Suggestions ---" -ForegroundColor Red
            Write-Host "WARNING: This will make actual changes to files!" -ForegroundColor Red
            
            $confirmation = Read-Host "Are you sure you want to proceed? (yes/no)"
            if ($confirmation -ne "yes") {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                exit 0
            }
            
            $result = Invoke-CopilotSuggestionHandler -PullRequestNumber $PullRequestNumber -Repository $Repository -AutoCommit -ValidateAfterFix
            
            Write-Host "`nResults:" -ForegroundColor Green
            Write-Host "  Success: $($result.Success)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
            Write-Host "  Message: $($result.Message)" -ForegroundColor White
            Write-Host "  Implemented: $($result.ImplementedCount) suggestions" -ForegroundColor Green
            Write-Host "  Failed: $($result.FailedCount) suggestions" -ForegroundColor Red
            Write-Host "  Files modified: $($result.ModifiedFiles.Count)" -ForegroundColor Cyan
            
            if ($result.ModifiedFiles.Count -gt 0) {
                Write-Host "`nModified files:" -ForegroundColor Cyan
                foreach ($file in $result.ModifiedFiles) {
                    Write-Host "  - $file" -ForegroundColor White
                }
            }
        }
    }
    
    Write-Host "`n=== Demo Completed Successfully ===" -ForegroundColor Green
    
} catch {
    Write-Error "Demo failed: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Review Copilot suggestions in GitHub PR interface" -ForegroundColor White
Write-Host "2. Run this handler automatically with: Invoke-CopilotSuggestionHandler -PullRequestNumber <PR#> -AutoCommit" -ForegroundColor White
Write-Host "3. Set up GitHub Actions to run this automatically on PR reviews" -ForegroundColor White
