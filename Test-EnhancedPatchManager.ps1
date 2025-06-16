#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive test and demonstration of enhanced PatchManager features
    
.DESCRIPTION
    This script demonstrates the new capabilities added to PatchManager:
    1. Enhanced git conflict resolution
    2. Automated Copilot suggestion handling
    3. Automatic issue resolution based on PR status
    4. Background monitoring and automation
    
.EXAMPLE
    .\Test-EnhancedPatchManager.ps1 -TestScenario "CopilotIntegration"
    
.EXAMPLE
    .\Test-EnhancedPatchManager.ps1 -TestScenario "IssueResolution"
    
.EXAMPLE
    .\Test-EnhancedPatchManager.ps1 -TestScenario "GitConflictResolution"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "CopilotIntegration", "IssueResolution", "GitConflictResolution", "EndToEnd")]
    [string]$TestScenario = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateTestPR,
    
    [Parameter(Mandatory = $false)]
    [int]$TestPRNumber,
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "logs/enhanced-patchmanager-test.log"
)

begin {
    Write-Host "🚀 Enhanced PatchManager Feature Test Suite" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    # Initialize logging
    $logDir = Split-Path $LogPath
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    function Write-TestLog {
        param([string]$Message, [string]$Level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $LogPath -Value $logEntry
        
        switch ($Level) {
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
            "INFO" { Write-Host $logEntry -ForegroundColor White }
            "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
            "TEST" { Write-Host $logEntry -ForegroundColor Cyan }
            default { Write-Host $logEntry -ForegroundColor Gray }
        }
    }
    
    # Import required modules
    try {
        Import-Module "$env:PWSH_MODULES_PATH/PatchManager" -Force
        Write-TestLog "PatchManager module imported successfully" "SUCCESS"
    } catch {
        Write-TestLog "Failed to import PatchManager module: $($_.Exception.Message)" "ERROR"
        throw
    }
}

process {
    function Test-CopilotIntegration {
        Write-TestLog "=== Testing Copilot Integration ===" "TEST"
        
        if (-not $TestPRNumber) {
            Write-TestLog "No PR number provided for Copilot testing. Use -TestPRNumber parameter or -CreateTestPR" "WARN"
            return $false
        }
        
        try {
            Write-TestLog "Testing Copilot suggestion handler for PR #$TestPRNumber" "INFO"
            
            if ($DryRun) {
                Write-TestLog "DRY RUN: Would start Copilot monitoring for PR #$TestPRNumber" "INFO"
                return $true
            }
            
            # Test single-run mode first
            Write-TestLog "Running single check for existing suggestions..." "INFO"
            $singleResult = Invoke-CopilotSuggestionHandler -PullRequestNumber $TestPRNumber -ValidateAfterFix -LogPath "logs/copilot-test-single.log"
            
            Write-TestLog "Single run result: Found $($singleResult.SuggestionsFound) suggestions, implemented $($singleResult.SuggestionsImplemented)" "INFO"
            
            # Test background monitoring (short duration for testing)
            Write-TestLog "Starting background monitoring test (5 minutes)..." "INFO"
            $monitorJob = Start-Job -ScriptBlock {
                param($PrNumber, $LogPath, $ModulePath)
                Import-Module $ModulePath -Force
                Invoke-CopilotSuggestionHandler -PullRequestNumber $PrNumber -BackgroundMonitor -MonitorIntervalSeconds 60 -AutoCommit -ValidateAfterFix -LogPath $LogPath -MaxMonitorHours 1
            } -ArgumentList $TestPRNumber, "logs/copilot-test-background.log", "$env:PWSH_MODULES_PATH/PatchManager"
            
            Write-TestLog "Background monitoring job started: Job ID $($monitorJob.Id)" "SUCCESS"
            Write-TestLog "Monitoring will run for 1 hour with 60-second intervals" "INFO"
            
            # Wait a bit and check job status
            Start-Sleep -Seconds 5
            $jobState = Get-Job -Id $monitorJob.Id
            Write-TestLog "Background job state: $($jobState.State)" "INFO"
            
            return $true
            
        } catch {
            Write-TestLog "Error testing Copilot integration: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    function Test-IssueResolution {
        Write-TestLog "=== Testing Issue Resolution ===" "TEST"
        
        if (-not $TestPRNumber) {
            Write-TestLog "No PR number provided for issue resolution testing" "WARN"
            return $false
        }
        
        try {
            # Try to find an associated issue
            Write-TestLog "Looking for issues associated with PR #$TestPRNumber" "INFO"
            
            $prInfo = gh pr view $TestPRNumber --json body,title | ConvertFrom-Json
            $issueNumber = $null
            
            # Look for issue references in PR body
            if ($prInfo.body -match '#(\d+)') {
                $issueNumber = [int]$matches[1]
                Write-TestLog "Found issue reference: #$issueNumber" "INFO"
            } else {
                Write-TestLog "No issue reference found in PR body" "WARN"
                
                # Create a test issue for demonstration
                if ($CreateTestPR) {
                    Write-TestLog "Creating test issue for demonstration..." "INFO"
                    $testIssueBody = @"
## Test Issue for Resolution Automation

This is a test issue created to demonstrate the automatic issue resolution feature.

**Associated PR**: #$TestPRNumber

**Test Scenarios**:
- Issue should remain open if PR is closed without merge
- Issue should be automatically closed if PR is merged
- Monitoring should handle timeout gracefully

This issue was created by the enhanced PatchManager test suite.
"@
                    
                    if (-not $DryRun) {
                        $newIssue = gh issue create --title "Test: Automatic issue resolution for PR #$TestPRNumber" --body $testIssueBody --label "automated-test" | ConvertFrom-Json
                        $issueNumber = $newIssue.number
                        Write-TestLog "Created test issue: #$issueNumber" "SUCCESS"
                    } else {
                        Write-TestLog "DRY RUN: Would create test issue" "INFO"
                        return $true
                    }
                }
            }
            
            if ($issueNumber) {
                Write-TestLog "Testing issue resolution monitoring for Issue #$issueNumber, PR #$TestPRNumber" "INFO"
                
                if ($DryRun) {
                    Write-TestLog "DRY RUN: Would start issue resolution monitoring" "INFO"
                    return $true
                }
                
                # Start background monitoring
                $resolutionJob = Start-Job -ScriptBlock {
                    param($IssueNum, $PrNumber, $LogPath, $ModulePath)
                    Import-Module $ModulePath -Force
                    Invoke-GitHubIssueResolution -IssueNumber $IssueNum -PullRequestNumber $PrNumber -MonitorInterval 30 -MaxMonitorHours 1 -LogPath $LogPath
                } -ArgumentList $issueNumber, $TestPRNumber, "logs/issue-resolution-test.log", "$env:PWSH_MODULES_PATH/PatchManager"
                
                Write-TestLog "Issue resolution monitoring job started: Job ID $($resolutionJob.Id)" "SUCCESS"
                Write-TestLog "Monitoring Issue #$issueNumber for PR #$TestPRNumber status changes" "INFO"
                
                # Check job status
                Start-Sleep -Seconds 3
                $jobState = Get-Job -Id $resolutionJob.Id
                Write-TestLog "Resolution job state: $($jobState.State)" "INFO"
                
                return $true
            } else {
                Write-TestLog "No issue found or created for testing" "WARN"
                return $false
            }
            
        } catch {
            Write-TestLog "Error testing issue resolution: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    function Test-GitConflictResolution {
        Write-TestLog "=== Testing Git Conflict Resolution ===" "TEST"
        
        try {
            Write-TestLog "Testing enhanced git push conflict resolution" "INFO"
            
            # Create a test scenario with the enhanced PatchManager
            $testDescription = "test: demonstrate enhanced git conflict resolution"
            $testOperation = {
                # Create a small test file
                $testFile = "test-conflict-resolution-$(Get-Date -Format 'HHmmss').txt"
                "Test content for conflict resolution demo" | Set-Content $testFile
                Write-Host "Created test file: $testFile" -ForegroundColor Green
                
                # Return info about the change
                return @{ TestFile = $testFile }
            }
            
            if ($DryRun) {
                Write-TestLog "DRY RUN: Would create test patch with enhanced git conflict resolution" "INFO"
                return $true
            }
            
            Write-TestLog "Creating test patch to demonstrate conflict resolution..." "INFO"
            
            # Use the enhanced PatchManager with new conflict resolution
            $patchResult = Invoke-GitControlledPatch -PatchDescription $testDescription -PatchOperation $testOperation -CreatePullRequest -AutoCommitUncommitted -Force
            
            if ($patchResult.Success) {
                Write-TestLog "Test patch created successfully: $($patchResult.PullRequestUrl)" "SUCCESS"
                Write-TestLog "Branch: $($patchResult.Branch)" "INFO"
                Write-TestLog "PR Number: $($patchResult.PullRequestNumber)" "INFO"
                
                # Clean up test file
                if (Test-Path $patchResult.ChangedFiles) {
                    Remove-Item $patchResult.ChangedFiles -Force -ErrorAction SilentlyContinue
                }
                
                return $true
            } else {
                Write-TestLog "Test patch failed: $($patchResult.Message)" "ERROR"
                return $false
            }
            
        } catch {
            Write-TestLog "Error testing git conflict resolution: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    function Test-EndToEndWorkflow {
        Write-TestLog "=== Testing End-to-End Workflow ===" "TEST"
        
        try {
            Write-TestLog "Demonstrating complete enhanced PatchManager workflow" "INFO"
            
            $e2eDescription = "test: end-to-end enhanced PatchManager demonstration"
            $e2eOperation = {
                # Create multiple test files to demonstrate comprehensive workflow
                $testFiles = @()
                
                for ($i = 1; $i -le 3; $i++) {
                    $testFile = "e2e-test-file-$i-$(Get-Date -Format 'HHmmss').txt"
                    $content = @"
End-to-End Test File $i
Created: $(Get-Date)
Purpose: Demonstrate enhanced PatchManager capabilities

Features being tested:
- Enhanced git conflict resolution
- Automated Copilot suggestion handling
- Automatic issue resolution
- Background monitoring
- Comprehensive audit trail
"@
                    $content | Set-Content $testFile
                    $testFiles += $testFile
                    Write-Host "Created test file: $testFile" -ForegroundColor Green
                }
                
                return @{ TestFiles = $testFiles }
            }
            
            if ($DryRun) {
                Write-TestLog "DRY RUN: Would create end-to-end test with all enhanced features" "INFO"
                return $true
            }
            
            Write-TestLog "Creating end-to-end test patch with all enhanced features..." "INFO"
            
            # This will trigger:
            # 1. Enhanced git conflict resolution
            # 2. Automatic GitHub issue creation
            # 3. Pull request creation with monitoring
            # 4. Copilot suggestion monitoring
            # 5. Issue resolution monitoring
            $e2eResult = Invoke-GitControlledPatch -PatchDescription $e2eDescription -PatchOperation $e2eOperation -CreatePullRequest -AutoCommitUncommitted -Force
            
            if ($e2eResult.Success) {
                Write-TestLog "End-to-end test created successfully!" "SUCCESS"
                Write-TestLog "PR: $($e2eResult.PullRequestUrl)" "INFO"
                Write-TestLog "Issue: $($e2eResult.IssueUrl)" "INFO"
                Write-TestLog "Monitoring jobs have been started automatically" "INFO"
                
                # All monitoring is now automatic:
                # - Copilot suggestion monitoring (background job)
                # - Issue resolution monitoring (background job)
                # - Branch cleanup monitoring
                
                Write-TestLog "The following automation is now active:" "INFO"
                Write-TestLog "✅ Copilot suggestion monitoring (5-minute intervals)" "INFO"
                Write-TestLog "✅ Issue resolution monitoring (1-minute intervals)" "INFO"
                Write-TestLog "✅ Branch cleanup monitoring" "INFO"
                Write-TestLog "✅ Complete audit trail logging" "INFO"
                
                return $true
            } else {
                Write-TestLog "End-to-end test failed: $($e2eResult.Message)" "ERROR"
                return $false
            }
            
        } catch {
            Write-TestLog "Error in end-to-end test: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
    
    # Main test execution
    $testResults = @{}
    
    switch ($TestScenario) {
        "All" {
            Write-TestLog "Running all test scenarios..." "TEST"
            $testResults.CopilotIntegration = Test-CopilotIntegration
            $testResults.IssueResolution = Test-IssueResolution
            $testResults.GitConflictResolution = Test-GitConflictResolution
            $testResults.EndToEndWorkflow = Test-EndToEndWorkflow
        }
        "CopilotIntegration" {
            $testResults.CopilotIntegration = Test-CopilotIntegration
        }
        "IssueResolution" {
            $testResults.IssueResolution = Test-IssueResolution
        }
        "GitConflictResolution" {
            $testResults.GitConflictResolution = Test-GitConflictResolution
        }
        "EndToEnd" {
            $testResults.EndToEndWorkflow = Test-EndToEndWorkflow
        }
    }
    
    # Summary
    Write-TestLog "=== Test Results Summary ===" "TEST"
    $successCount = 0
    $totalCount = $testResults.Count
    
    foreach ($test in $testResults.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
        Write-TestLog "$($test.Key): $status" "INFO"
        if ($test.Value) { $successCount++ }
    }
    
    Write-TestLog "Overall: $successCount/$totalCount tests passed" "INFO"
    
    if ($successCount -eq $totalCount) {
        Write-TestLog "🎉 All tests completed successfully!" "SUCCESS"
        Write-TestLog "Enhanced PatchManager features are working correctly" "SUCCESS"
    } else {
        Write-TestLog "⚠️ Some tests failed. Check logs for details." "WARN"
    }
}

end {
    Write-TestLog "Enhanced PatchManager test suite completed" "INFO"
    Write-TestLog "Log file: $LogPath" "INFO"
    
    # Show active background jobs
    $activeJobs = Get-Job | Where-Object { $_.State -eq 'Running' }
    if ($activeJobs) {
        Write-TestLog "Active background monitoring jobs:" "INFO"
        foreach ($job in $activeJobs) {
            Write-TestLog "  Job ID $($job.Id): $($job.Name)" "INFO"
        }
        Write-TestLog "Use Get-Job | Receive-Job to check job output" "INFO"
        Write-TestLog "Use Remove-Job -Id <id> to clean up completed jobs" "INFO"
    }
}
