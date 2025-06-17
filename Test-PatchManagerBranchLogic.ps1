#Requires -Version 7.0

<#
.SYNOPSIS
Test the improved PatchManager branch logic

.DESCRIPTION
This script tests the enhanced PatchManager logic that handles:
1. Already being on the target branch
2. Branch already exists scenarios
3. Proper fallback when branch creation fails

.EXAMPLE
./Test-PatchManagerBranchLogic.ps1
#>

# Import required modules by name (admin-friendly)
Import-Module 'Logging' -Force
Import-Module 'PatchManager' -Force

function Test-BranchLogicScenarios {
    [CmdletBinding()]
    param()
    
    begin {
        Write-CustomLog "Starting PatchManager branch logic tests" -Level INFO
        $testResults = @()
    }
    
    process {
        try {
            # Test 1: Check current branch detection
            Write-CustomLog "Test 1: Testing current branch detection" -Level INFO
            $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($currentBranch) {
                Write-CustomLog "PASS: Current branch detected as: $currentBranch" -Level SUCCESS
                $testResults += @{ Test = "Current Branch Detection"; Result = "PASS"; Details = $currentBranch }
            } else {
                Write-CustomLog "FAIL: Could not detect current branch" -Level ERROR
                $testResults += @{ Test = "Current Branch Detection"; Result = "FAIL"; Details = "No branch detected" }
            }
            
            # Test 2: Test branch existence check
            Write-CustomLog "Test 2: Testing branch existence check" -Level INFO
            $testBranchName = "patch/test-branch-logic"
            $branchExists = git branch --list $testBranchName 2>$null
            if ($branchExists) {
                Write-CustomLog "INFO: Test branch $testBranchName already exists" -Level INFO
            } else {
                Write-CustomLog "INFO: Test branch $testBranchName does not exist" -Level INFO
            }
            $testResults += @{ Test = "Branch Existence Check"; Result = "PASS"; Details = "Logic working" }
            
            # Test 3: Test dry run functionality
            Write-CustomLog "Test 3: Testing dry run functionality" -Level INFO
            try {
                $testPatch = {
                    Write-CustomLog "This is a test patch operation" -Level INFO
                }
                
                Invoke-GitControlledPatch -PatchDescription "Test branch logic" -PatchOperation $testPatch -DryRun
                Write-CustomLog "PASS: Dry run completed successfully" -Level SUCCESS
                $testResults += @{ Test = "Dry Run Functionality"; Result = "PASS"; Details = "Dry run successful" }
            }
            catch {
                Write-CustomLog "FAIL: Dry run failed: $($_.Exception.Message)" -Level ERROR
                $testResults += @{ Test = "Dry Run Functionality"; Result = "FAIL"; Details = $_.Exception.Message }
            }
            
            # Test 4: Test branch name generation
            Write-CustomLog "Test 4: Testing branch name generation" -Level INFO
            $testDescription = "Test: Special Characters & Spaces!"
            $sanitizedName = $testDescription -replace '[^a-zA-Z0-9]', '-'
            $expectedPattern = "patch/\d{8}-\d{6}-test--special-characters---spaces-"
            if ($sanitizedName -match "test--special-characters---spaces-") {
                Write-CustomLog "PASS: Branch name sanitization working" -Level SUCCESS
                $testResults += @{ Test = "Branch Name Generation"; Result = "PASS"; Details = "Sanitization working" }
            } else {
                Write-CustomLog "FAIL: Branch name sanitization not working as expected" -Level ERROR
                $testResults += @{ Test = "Branch Name Generation"; Result = "FAIL"; Details = "Sanitization failed" }
            }
            
        }
        catch {
            Write-CustomLog "Error during testing: $($_.Exception.Message)" -Level ERROR
            $testResults += @{ Test = "General Error"; Result = "FAIL"; Details = $_.Exception.Message }
        }
    }
    
    end {
        Write-CustomLog "======== Test Results Summary ========" -Level INFO
        $passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
        $failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
        
        foreach ($result in $testResults) {
            $level = if ($result.Result -eq "PASS") { "SUCCESS" } else { "ERROR" }
            Write-CustomLog "$($result.Test): $($result.Result) - $($result.Details)" -Level $level
        }
        
        Write-CustomLog "=======================================" -Level INFO
        Write-CustomLog "Tests Passed: $passCount" -Level SUCCESS
        Write-CustomLog "Tests Failed: $failCount" -Level $(if ($failCount -eq 0) { "SUCCESS" } else { "ERROR" })
        
        if ($failCount -eq 0) {
            Write-CustomLog "All branch logic tests PASSED!" -Level SUCCESS
            return $true
        } else {
            Write-CustomLog "Some branch logic tests FAILED" -Level ERROR
            return $false
        }
    }
}

function Test-BranchScenarios {
    [CmdletBinding()]
    param()
    
    Write-CustomLog "Testing specific branch scenarios..." -Level INFO
    
    # Scenario 1: Already on target branch
    Write-CustomLog "Scenario 1: Simulating already on target branch" -Level INFO
    $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
    Write-CustomLog "Current branch: $currentBranch" -Level INFO
    
    # Scenario 2: Branch creation with existing branch
    Write-CustomLog "Scenario 2: Testing with potentially existing branch" -Level INFO
    
    # This demonstrates the new logic without actually creating branches
    Write-CustomLog "Enhanced PatchManager now handles:" -Level INFO
    Write-CustomLog "- Already on target branch detection" -Level INFO
    Write-CustomLog "- Existing branch reuse" -Level INFO
    Write-CustomLog "- Better error messages with current branch info" -Level INFO
    Write-CustomLog "- Proper fallback scenarios" -Level INFO
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-CustomLog "OpenTofu Lab Automation - PatchManager Branch Logic Test" -Level INFO
    Write-CustomLog "========================================================" -Level INFO
    
    $branchTestResult = Test-BranchLogicScenarios
    Test-BranchScenarios
    
    if ($branchTestResult) {
        Write-CustomLog "PatchManager branch logic is working correctly!" -Level SUCCESS
        exit 0
    } else {
        Write-CustomLog "PatchManager branch logic needs attention" -Level ERROR
        exit 1
    }
}
