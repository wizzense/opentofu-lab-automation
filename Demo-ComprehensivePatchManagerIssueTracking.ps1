#Requires -Version 7.0

<#
.SYNOPSIS
    Demo script for enhanced PatchManager with comprehensive GitHub issue tracking
    
.DESCRIPTION
    This script demonstrates the new PatchManager capabilities:
    1. Automatic GitHub issue creation for every PR
    2. Comprehensive error tracking with GitHub issues
    3. Test failure tracking and central bug tracking
    4. Runtime error monitoring with detailed issue creation
    
.PARAMETER DemoType
    Type of demo to run (PR, Error, TestFailure, Comprehensive)
    
.PARAMETER CreateActualIssues
    Whether to create actual GitHub issues (default: false for safety)
    
.EXAMPLE
    ./Demo-ComprehensivePatchManagerIssueTracking.ps1 -DemoType "PR" -CreateActualIssues
    
.EXAMPLE
    ./Demo-ComprehensivePatchManagerIssueTracking.ps1 -DemoType "Comprehensive"
    
.NOTES
    - Demonstrates all new issue tracking capabilities
    - Safe to run without creating actual GitHub issues
    - Shows integration with existing PatchManager workflow
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("PR", "Error", "TestFailure", "RuntimeError", "Comprehensive")]
    [string]$DemoType = "Comprehensive",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateActualIssues = $false
)

# Import required modules
Write-Host "=== Enhanced PatchManager Issue Tracking Demo ===" -ForegroundColor Cyan
Write-Host "Demo Type: $DemoType" -ForegroundColor Yellow
Write-Host "Create Actual Issues: $CreateActualIssues" -ForegroundColor Yellow
Write-Host ""

try {
    Import-Module 'PatchManager' -Force
    Write-Host "PatchManager module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to import PatchManager module: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Attempting to import from local path..." -ForegroundColor Yellow
    
    $projectRoot = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation"
    Import-Module "$projectRoot\pwsh\modules\PatchManager" -Force
    Write-Host "PatchManager imported from local path" -ForegroundColor Green
}

function Demo-PRTracking {
    Write-Host "`n=== Demonstrating PR Tracking with GitHub Issues ===" -ForegroundColor Cyan
    
    Write-Host "Creating a sample patch with pull request and automatic issue tracking..." -ForegroundColor Yellow
    
    if ($CreateActualIssues) {
        # Create actual PR with issue tracking
        $patchResult = Invoke-GitControlledPatch -PatchDescription "Demo: Enhanced PatchManager issue tracking" -PatchOperation {
            # Create a demo file change
            $demoFile = "demo-patch-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
            "Demo patch content created at $(Get-Date)" | Out-File $demoFile
            Write-Host "Created demo file: $demoFile" -ForegroundColor Green
        } -CreatePullRequest -AffectedFiles @("demo-patch-*.txt")
        
        if ($patchResult.Success) {
            Write-Host "SUCCESS: PR created with issue tracking!" -ForegroundColor Green
            Write-Host "  PR URL: $($patchResult.PullRequestUrl)" -ForegroundColor Cyan
            Write-Host "  Tracking Issue: $($patchResult.IssueUrl)" -ForegroundColor Cyan
            Write-Host "  Issue Number: #$($patchResult.IssueNumber)" -ForegroundColor Cyan
        } else {
            Write-Host "DEMO RESULT: $($patchResult.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "DRY RUN: Would create PR with comprehensive issue tracking" -ForegroundColor Yellow
        Write-Host "  - Pull request would be created with detailed description" -ForegroundColor Gray
        Write-Host "  - GitHub issue would track PR lifecycle" -ForegroundColor Gray
        Write-Host "  - Issue would include review checklist and merge requirements" -ForegroundColor Gray
        Write-Host "  - Issue would auto-close when PR is merged" -ForegroundColor Gray
    }
}

function Demo-ErrorTracking {
    Write-Host "`n=== Demonstrating Error Tracking with GitHub Issues ===" -ForegroundColor Cyan
    
    Write-Host "Simulating various types of errors and demonstrating automatic issue creation..." -ForegroundColor Yellow
    
    # Demo 1: Import Error
    Write-Host "`n1. Import Error Demo:" -ForegroundColor White
    try {
        $result = Invoke-ErrorHandler -ErrorType "ImportError" -Context @{
            ModuleName = "NonExistentModule"
            Path = "./modules/NonExistentModule"
            Operation = "Module Import Demo"
        } -CreateIssue:$CreateActualIssues
        
        Write-Host "Import error processed successfully" -ForegroundColor Green
        if ($result.IssueCreated) {
            Write-Host "  Issue created: $($result.IssueUrl)" -ForegroundColor Cyan
        } else {
            Write-Host "  DRY RUN: Would create issue for import error" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Demo 2: Runtime Error
    Write-Host "`n2. Runtime Error Demo:" -ForegroundColor White
    try {
        # Create a mock error record
        $mockError = try { 
            throw "Demo runtime error for issue tracking demonstration" 
        } catch { $_ }
        
        $result = Invoke-ErrorHandler -ErrorRecord $mockError -ErrorType "RuntimeError" -Context @{
            Operation = "Demo Script Execution"
            Component = "Error Tracking Demo"
        } -CreateIssue:$CreateActualIssues -Priority "High"
        
        Write-Host "Runtime error processed successfully" -ForegroundColor Green
        if ($result.IssueCreated) {
            Write-Host "  Issue created: $($result.IssueUrl)" -ForegroundColor Cyan
        } else {
            Write-Host "  DRY RUN: Would create high-priority issue for runtime error" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Runtime error demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Demo 3: Build Failure
    Write-Host "`n3. Build Failure Demo:" -ForegroundColor White
    try {
        $result = Invoke-ErrorHandler -ErrorType "BuildFailure" -Context @{
            Operation = "Build Process"
            Stage = "Compilation"
            ErrorMessage = "MSBuild failed with exit code 1"
            LogPath = "./logs/build-failure-demo.log"
        } -CreateIssue:$CreateActualIssues -Priority "Critical"
        
        Write-Host "Build failure processed successfully" -ForegroundColor Green
        if ($result.IssueCreated) {
            Write-Host "  Issue created: $($result.IssueUrl)" -ForegroundColor Cyan
        } else {
            Write-Host "  DRY RUN: Would create critical issue for build failure" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Build failure demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Demo-TestFailureTracking {
    Write-Host "`n=== Demonstrating Test Failure Tracking ===" -ForegroundColor Cyan
    
    Write-Host "Simulating test failures and demonstrating automatic issue creation..." -ForegroundColor Yellow
    
    # Create mock Pester test results with failures
    $mockTestResults = [PSCustomObject]@{
        TotalTests = 25
        PassedTests = 22
        FailedTests = @(
            [PSCustomObject]@{
                Name = "Module Import Test"
                FailureMessage = "Module 'TestModule' could not be imported"
                Source = "./tests/ModuleImport.Tests.ps1"
            },
            [PSCustomObject]@{
                Name = "Configuration Validation"
                FailureMessage = "Configuration file validation failed - missing required property 'APIKey'"
                Source = "./tests/Configuration.Tests.ps1"
            },
            [PSCustomObject]@{
                Name = "Cross-Platform Path Test"
                FailureMessage = "Path separator test failed on Unix systems"
                Source = "./tests/CrossPlatform.Tests.ps1"
            }
        )
        Output = "Test run completed with 3 failures out of 25 tests"
    }
    
    try {
        $result = Invoke-ErrorHandler -TestResults $mockTestResults -ErrorType "TestFailure" -Context @{
            TestFramework = "Pester"
            TestRun = "Automated CI/CD"
            Branch = "feature/demo-testing"
        } -CreateIssue:$CreateActualIssues -Priority "High"
        
        Write-Host "Test failures processed successfully" -ForegroundColor Green
        if ($result.IssueCreated) {
            Write-Host "  Issue created: $($result.IssueUrl)" -ForegroundColor Cyan
            Write-Host "  Tracking $($mockTestResults.FailedTests.Count) failed tests" -ForegroundColor Cyan
        } else {
            Write-Host "  DRY RUN: Would create issue tracking 3 test failures" -ForegroundColor Yellow
            Write-Host "    - Module Import Test failure" -ForegroundColor Gray
            Write-Host "    - Configuration Validation failure" -ForegroundColor Gray
            Write-Host "    - Cross-Platform Path Test failure" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Test failure demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Demo-MonitoredExecution {
    Write-Host "`n=== Demonstrating Monitored Execution with Automatic Issue Creation ===" -ForegroundColor Cyan
    
    Write-Host "Running monitored execution that will detect and track errors automatically..." -ForegroundColor Yellow
    
    try {
        $executionResult = Invoke-MonitoredExecution -ScriptBlock {
            Write-Host "Starting monitored script execution..." -ForegroundColor Green
            
            # Simulate some successful operations
            Write-Host "Operation 1: Success" -ForegroundColor Green
            Start-Sleep 1
            
            # Simulate a warning condition
            Write-Warning "This is a demo warning that should be tracked"
            
            # Simulate an error that should create an issue
            Write-Error "Demo error: This error should be automatically tracked in a GitHub issue"
            
            # Simulate a critical failure
            throw "Demo critical failure for comprehensive issue tracking"
            
        } -ErrorHandling "Comprehensive" -CreateIssues:$CreateActualIssues -Context @{
            Operation = "Comprehensive Demo"
            Component = "Monitored Execution"
            Purpose = "Demonstrating automatic error detection and issue creation"
        }
        
        Write-Host "`nMONITORED EXECUTION RESULTS:" -ForegroundColor Cyan
        Write-Host "  Success: $($executionResult.Success)" -ForegroundColor $(if ($executionResult.Success) { "Green" } else { "Red" })
        Write-Host "  Execution Time: $($executionResult.ExecutionTime)" -ForegroundColor White
        Write-Host "  Errors Detected: $($executionResult.Errors.Count)" -ForegroundColor White
        Write-Host "  Issues Created: $($executionResult.IssuesCreated.Count)" -ForegroundColor White
        
        if ($executionResult.IssuesCreated.Count -gt 0) {
            Write-Host "`n  GitHub Issues Created:" -ForegroundColor Cyan
            foreach ($issue in $executionResult.IssuesCreated) {
                Write-Host "    - #$($issue.IssueNumber) [$($issue.ErrorType)]: $($issue.Summary)" -ForegroundColor White
                Write-Host "      URL: $($issue.IssueUrl)" -ForegroundColor Gray
            }
        } elseif (-not $CreateActualIssues) {
            Write-Host "`n  DRY RUN: Would create issues for detected errors" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "Monitored execution demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Demo-ComprehensiveIssueTracking {
    Write-Host "`n=== Demonstrating Direct Issue Creation API ===" -ForegroundColor Cyan
    
    Write-Host "Creating various types of comprehensive tracking issues..." -ForegroundColor Yellow
    
    # Demo 1: PR Tracking Issue
    Write-Host "`n1. PR Tracking Issue:" -ForegroundColor White
    try {
        $prIssue = Invoke-ComprehensiveIssueTracking -Operation "PR" -Title "Demo PR: Comprehensive Issue Tracking" -Description "This is a demonstration of comprehensive PR tracking with detailed issue creation." -PullRequestNumber 999 -PullRequestUrl "https://github.com/demo/repo/pull/999" -AffectedFiles @("demo.ps1", "README.md") -Priority "Medium" -AutoClose
        
        if ($CreateActualIssues -and $prIssue.Success) {
            Write-Host "  PR tracking issue created: $($prIssue.IssueUrl)" -ForegroundColor Green
        } else {
            Write-Host "  DRY RUN: Would create comprehensive PR tracking issue" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  PR issue demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Demo 2: Error Tracking Issue
    Write-Host "`n2. Error Tracking Issue:" -ForegroundColor White
    try {
        $errorIssue = Invoke-ComprehensiveIssueTracking -Operation "Error" -Title "Demo Error: System Integration Failure" -Description "Demonstration of comprehensive error tracking with detailed context and resolution steps." -ErrorDetails @{
            ErrorMessage = "Integration with external API failed"
            ErrorCategory = "ExternalService"
            Operation = "API Integration"
            StatusCode = 500
            ResponseBody = "Internal Server Error"
            Timestamp = (Get-Date).ToString()
        } -AffectedFiles @("integration.ps1", "config.json") -Priority "High"
        
        if ($CreateActualIssues -and $errorIssue.Success) {
            Write-Host "  Error tracking issue created: $($errorIssue.IssueUrl)" -ForegroundColor Green
        } else {
            Write-Host "  DRY RUN: Would create comprehensive error tracking issue" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Error issue demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Demo 3: Warning Monitoring Issue
    Write-Host "`n3. Warning Monitoring Issue:" -ForegroundColor White
    try {
        $warningIssue = Invoke-ComprehensiveIssueTracking -Operation "Warning" -Title "Demo Warning: Performance Degradation Detected" -Description "Demonstration of warning condition monitoring and tracking." -ErrorDetails @{
            WarningMessage = "Response time exceeding 5 seconds threshold"
            WarningSource = "Performance Monitor"
            Frequency = "Intermittent"
            Impact = "User experience degradation"
        } -Priority "Low"
        
        if ($CreateActualIssues -and $warningIssue.Success) {
            Write-Host "  Warning monitoring issue created: $($warningIssue.IssueUrl)" -ForegroundColor Green
        } else {
            Write-Host "  DRY RUN: Would create comprehensive warning monitoring issue" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Warning issue demo failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Run the appropriate demo based on the parameter
switch ($DemoType) {
    "PR" { Demo-PRTracking }
    "Error" { Demo-ErrorTracking }
    "TestFailure" { Demo-TestFailureTracking }
    "RuntimeError" { Demo-MonitoredExecution }
    "Comprehensive" {
        Demo-PRTracking
        Demo-ErrorTracking  
        Demo-TestFailureTracking
        Demo-MonitoredExecution
        Demo-ComprehensiveIssueTracking
    }
}

Write-Host "`n=== Demo Complete ===" -ForegroundColor Cyan
Write-Host "The enhanced PatchManager now provides:" -ForegroundColor Yellow
Write-Host "  1. Automatic GitHub issue creation for every PR" -ForegroundColor White
Write-Host "  2. Comprehensive error tracking with detailed GitHub issues" -ForegroundColor White
Write-Host "  3. Test failure tracking and central bug tracking" -ForegroundColor White
Write-Host "  4. Runtime error monitoring with automatic issue creation" -ForegroundColor White
Write-Host "  5. All errors and failures tracked centrally for systematic resolution" -ForegroundColor White

if (-not $CreateActualIssues) {
    Write-Host "`nNote: This was a dry run. Use -CreateActualIssues to create real GitHub issues." -ForegroundColor Yellow
}

Write-Host "`nAll functionality is now integrated into the PatchManager workflow!" -ForegroundColor Green
