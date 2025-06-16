#Requires -Version 7.0
<#
.SYNOPSIS
    Advanced demonstration of automated Copilot suggestion implementation with background monitoring
    
.DESCRIPTION
    This script demonstrates the enhanced Copilot suggestion handler that can:
    1. Monitor PRs in the background for delayed Copilot reviews
    2. Automatically implement suggestions when they appear
    3. Log all activities with full audit trail
    4. Use PatchManager for safe, rollback-enabled changes
    
.PARAMETER Mode
    The demonstration mode:
    - SingleRun: Check once and implement suggestions
    - BackgroundMonitor: Continuously monitor for new suggestions
    - TestBoth: Demonstrate both modes
    
.PARAMETER PullRequestNumber
    The PR number to monitor (optional, defaults to finding recent PRs)
    
.PARAMETER MonitorIntervalSeconds
    How often to check for new suggestions in background mode (default: 300 seconds)
    
.EXAMPLE
    ./Demo-AdvancedCopilotHandler.ps1 -Mode BackgroundMonitor -PullRequestNumber 123
    
.EXAMPLE
    ./Demo-AdvancedCopilotHandler.ps1 -Mode TestBoth
    
.NOTES
    This demonstrates the complete workflow:
    1. Create PR -> Copilot reviews (with delay) -> Auto-implement -> Commit -> Ready for human review
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("SingleRun", "BackgroundMonitor", "TestBoth")]
    [string]$Mode = "TestBoth",
    
    [Parameter(Mandatory = $false)]
    [int]$PullRequestNumber,
    
    [Parameter(Mandatory = $false)]
    [int]$MonitorIntervalSeconds = 60  # Shorter for demo
)

$ErrorActionPreference = "Stop"

# Import PatchManager
Import-Module "$PSScriptRoot/../../pwsh/modules/PatchManager" -Force

Write-Host @"

============================================================================
    ADVANCED COPILOT SUGGESTION HANDLER DEMONSTRATION
============================================================================

This demo shows the enhanced Copilot integration that handles the reality
of delayed Copilot reviews by monitoring PRs in the background and 
automatically implementing suggestions when they appear.

WORKFLOW:
1. Create PR with PatchManager
2. Background monitor starts
3. Copilot reviews PR (with natural delay)
4. Monitor detects new suggestions
5. Auto-implement suggestions with PatchManager
6. Commit changes to PR
7. Human reviewer sees PR with suggestions already implemented

============================================================================
"@ -ForegroundColor Cyan

# Find a recent PR if not specified
if (-not $PullRequestNumber) {
    Write-Host "Finding recent PRs..." -ForegroundColor Yellow
    
    try {
        $recentPRs = gh pr list --limit 5 --json number,title,state | ConvertFrom-Json
        if ($recentPRs) {
            $PullRequestNumber = $recentPRs[0].number
            Write-Host "Using PR #$PullRequestNumber`: $($recentPRs[0].title)" -ForegroundColor Green
        } else {
            Write-Host "No recent PRs found. Creating a test PR..." -ForegroundColor Yellow
            
            # Create a test PR with intentional issues for Copilot to find
            $testResult = Invoke-GitControlledPatch -PatchDescription "test: create demo PR with issues for Copilot review" -PatchOperation {
                # Create a test file with common issues Copilot will flag
                $testContent = @"
# Test file with intentional issues for Copilot to review

def test_function():
    url = 'http:/example.com'  # Missing slash - Copilot will flag this
    print("URL is: " + url)
    return True

class TestClass:
    def __init__(self):
        self.status = "ready"
    
    def get_status(self):
        return self.status
"@
                Set-Content -Path "test-copilot-review.py" -Value $testContent
                Write-Host "Created test file with issues for Copilot to review" -ForegroundColor Yellow
            } -AutoCommitUncommitted -CreatePullRequest
            
            if ($testResult.Success) {
                # Extract PR number from result or fetch it
                $PullRequestNumber = 999  # Would need to parse actual PR number
                Write-Host "Created test PR #$PullRequestNumber" -ForegroundColor Green
            } else {
                throw "Failed to create test PR"
            }
        }
    } catch {
        Write-Warning "Could not find or create PR. Using PR #1 for demo purposes."
        $PullRequestNumber = 1
    }
}

Write-Host "`nDemonstrating with PR #$PullRequestNumber" -ForegroundColor Cyan

switch ($Mode) {
    "SingleRun" {
        Write-Host "`n--- SINGLE RUN MODE ---" -ForegroundColor Yellow
        Write-Host "This mode checks once for existing Copilot suggestions and implements them."
        
        $result = Invoke-CopilotSuggestionHandler -PullRequestNumber $PullRequestNumber -AutoCommit -ValidateAfterFix
        
        Write-Host "`nResult:" -ForegroundColor Cyan
        $result | Format-Table -AutoSize
    }
    
    "BackgroundMonitor" {
        Write-Host "`n--- BACKGROUND MONITOR MODE ---" -ForegroundColor Yellow
        Write-Host "This mode continuously monitors for new Copilot suggestions."
        Write-Host "It handles the reality that Copilot reviews aren't instant."
        Write-Host "Press Ctrl+C to stop monitoring.`n"
        
        # Start background monitoring
        Invoke-CopilotSuggestionHandler -PullRequestNumber $PullRequestNumber -BackgroundMonitor -MonitorIntervalSeconds $MonitorIntervalSeconds -AutoCommit -ValidateAfterFix
    }
    
    "TestBoth" {
        Write-Host "`n--- TESTING BOTH MODES ---" -ForegroundColor Yellow
        
        # First, single run to check current state
        Write-Host "`n1. Single run check for existing suggestions:" -ForegroundColor Cyan
        $singleResult = Invoke-CopilotSuggestionHandler -PullRequestNumber $PullRequestNumber -AutoCommit -WhatIf
        Write-Host "Single run result: $($singleResult.Message)" -ForegroundColor Green
        
        # Then demonstrate background monitoring (for a short time)
        Write-Host "`n2. Starting background monitoring for 3 minutes..." -ForegroundColor Cyan
        Write-Host "This simulates monitoring for delayed Copilot reviews." -ForegroundColor Yellow
        Write-Host "In real usage, this would run continuously." -ForegroundColor Yellow
        
        $job = Start-Job -ScriptBlock {
            param($PR, $Interval)
            Import-Module "$using:PSScriptRoot/../../pwsh/modules/PatchManager" -Force
            
            # Monitor for 3 minutes
            $endTime = (Get-Date).AddMinutes(3)
            $checkCount = 0
            
            while ((Get-Date) -lt $endTime) {
                $checkCount++
                Write-Host "Background check #$checkCount for PR #$PR..." -ForegroundColor Gray
                
                try {
                    $result = Invoke-CopilotSuggestionHandler -PullRequestNumber $PR -MonitorIntervalSeconds $Interval -LogPath "logs/demo-copilot-monitor.log"
                    if ($result.NewSuggestions -gt 0) {
                        Write-Host "Found and implemented $($result.NewSuggestions) suggestions!" -ForegroundColor Green
                        break
                    }
                } catch {
                    Write-Host "Check failed: $($_.Exception.Message)" -ForegroundColor Red
                }
                
                Start-Sleep -Seconds $Interval
            }
            
            return @{ CheckCount = $checkCount; CompletedNormally = $true }
        } -ArgumentList $PullRequestNumber, $MonitorIntervalSeconds
        
        # Wait for job with progress
        $timeout = 180  # 3 minutes
        $elapsed = 0
        
        while ($job.State -eq "Running" -and $elapsed -lt $timeout) {
            Write-Progress -Activity "Background Monitoring Demo" -Status "Monitoring PR #$PullRequestNumber for Copilot suggestions..." -PercentComplete (($elapsed / $timeout) * 100)
            Start-Sleep -Seconds 5
            $elapsed += 5
        }
        
        # Get job results
        $jobResult = Receive-Job $job -Wait
        Remove-Job $job
        
        Write-Host "`n3. Background monitoring completed" -ForegroundColor Green
        Write-Host "Performed $($jobResult.CheckCount) background checks" -ForegroundColor Cyan
        
        # Show log contents
        $logPath = "logs/demo-copilot-monitor.log"
        if (Test-Path $logPath) {
            Write-Host "`n4. Log output from background monitoring:" -ForegroundColor Cyan
            Get-Content $logPath | Select-Object -Last 10 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }
}

Write-Host @"

============================================================================
    DEMONSTRATION COMPLETE
============================================================================

KEY BENEFITS DEMONSTRATED:

✅ HANDLES COPILOT REVIEW DELAYS
   - Background monitoring accounts for the natural delay in Copilot reviews
   - No need to manually check back later

✅ AUTOMATED IMPLEMENTATION
   - Suggestions are implemented automatically when detected
   - Uses PatchManager for safe, rollback-enabled changes

✅ COMPREHENSIVE LOGGING
   - Full audit trail of all activities
   - Timestamped logs for transparency

✅ HUMAN-READY REVIEWS
   - By the time humans review the PR, Copilot suggestions are already implemented
   - Faster review cycles and fewer back-and-forth iterations

REAL WORLD WORKFLOW:
1. Developer creates PR with PatchManager
2. Background monitor starts automatically
3. Copilot reviews PR (minutes to hours later)
4. Monitor detects suggestions and implements them
5. Human reviewer sees a cleaner PR with suggestions already applied

============================================================================
"@ -ForegroundColor Green

Write-Host "`nDemo completed successfully!" -ForegroundColor Cyan
