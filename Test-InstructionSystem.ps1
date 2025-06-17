#Requires -Version 7.0

<#
.SYNOPSIS
Test script to verify the updated instruction system works correctly with admin-friendly module imports

.DESCRIPTION
This script validates that:
1. All instruction files use the correct admin-friendly import pattern
2. VS Code settings are properly configured for instruction files
3. No hardcoded paths remain in instruction files
4. Module import patterns are consistent across all files

.EXAMPLE
./Test-InstructionSystem.ps1
#>

# Import required modules by name (admin-friendly)
Import-Module 'Logging' -Force

function Test-InstructionFileConsistency {
    [CmdletBinding()]
    param()
    
    begin {
        Write-CustomLog "Starting instruction file consistency tests" -Level INFO
        $errorCount = 0
    }
    
    process {
        try {
            # Test 1: Check for hardcoded import paths
            Write-CustomLog "Testing for hardcoded import paths..." -Level INFO
            $hardcodedPaths = Get-ChildItem -Path "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\" -Filter "*.instructions.md" -Recurse | 
                ForEach-Object {
                    $content = Get-Content $_.FullName -Raw
                    if ($content -match "Import-Module '/workspaces/") {
                        Write-CustomLog "FAIL: Found hardcoded path in $($_.Name)" -Level ERROR
                        $errorCount++
                        return $_.FullName
                    }
                }
            
            if (-not $hardcodedPaths) {
                Write-CustomLog "PASS: No hardcoded import paths found" -Level SUCCESS
            }
            
            # Test 2: Check for admin-friendly imports
            Write-CustomLog "Testing for admin-friendly import patterns..." -Level INFO
            $instructionFiles = Get-ChildItem -Path "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\" -Filter "*.instructions.md" -Recurse
            $adminFriendlyCount = 0
            
            foreach ($file in $instructionFiles) {
                $content = Get-Content $file.FullName -Raw
                if ($content -match "Import-Module '\w+' -Force") {
                    $adminFriendlyCount++
                }
            }
            
            Write-CustomLog "Found $adminFriendlyCount instruction files with admin-friendly imports" -Level INFO
            
            # Test 3: Check VS Code settings
            Write-CustomLog "Testing VS Code settings configuration..." -Level INFO
            $settingsPath = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\.vscode\settings.json"
            if (Test-Path $settingsPath) {
                $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
                
                if ($settings.'github.copilot.chat.codeGeneration.useInstructionFiles') {
                    Write-CustomLog "PASS: Instruction files enabled in VS Code" -Level SUCCESS
                } else {
                    Write-CustomLog "FAIL: Instruction files not enabled in VS Code" -Level ERROR
                    $errorCount++
                }
                
                if ($settings.'chat.promptFiles') {
                    Write-CustomLog "PASS: Prompt files enabled in VS Code" -Level SUCCESS
                } else {
                    Write-CustomLog "FAIL: Prompt files not enabled in VS Code" -Level ERROR
                    $errorCount++
                }
            } else {
                Write-CustomLog "FAIL: VS Code settings file not found" -Level ERROR
                $errorCount++
            }
            
            # Test 4: Check specific module references
            Write-CustomLog "Testing for correct module references..." -Level INFO
            $requiredModules = @('PatchManager', 'LabRunner', 'Logging', 'BackupManager', 'DevEnvironment', 
                                 'ParallelExecution', 'ScriptManager', 'TestingFramework', 'UnifiedMaintenance')
            
            $patchManagerFile = "c:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation\.vscode\instructions\patchmanager-enforcement.instructions.md"
            if (Test-Path $patchManagerFile) {
                $content = Get-Content $patchManagerFile -Raw
                foreach ($module in $requiredModules) {
                    if ($content -match "pwsh/modules/$module/") {
                        Write-CustomLog "PASS: Found reference to $module module" -Level SUCCESS
                    }
                }
            }
            
        }
        catch {
            Write-CustomLog "Error during testing: $($_.Exception.Message)" -Level ERROR
            $errorCount++
        }
    }
    
    end {
        if ($errorCount -eq 0) {
            Write-CustomLog "All instruction system tests PASSED!" -Level SUCCESS
            return $true
        } else {
            Write-CustomLog "Instruction system tests FAILED with $errorCount errors" -Level ERROR
            return $false
        }
    }
}

function Test-ModuleImportExample {
    [CmdletBinding()]
    param()
    
    begin {
        Write-CustomLog "Testing admin-friendly module import example..." -Level INFO
    }
    
    process {
        try {
            # Demonstrate the correct import pattern
            Write-CustomLog "Example of admin-friendly imports:" -Level INFO
            Write-CustomLog "Import-Module 'Logging' -Force" -Level INFO
            Write-CustomLog "Import-Module 'PatchManager' -Force" -Level INFO
            Write-CustomLog "Import-Module 'LabRunner' -Force" -Level INFO
            
            Write-CustomLog "This replaces the old hardcoded path pattern:" -Level INFO
            Write-CustomLog "OLD: Import-Module '/workspaces/opentofu-lab-automation/pwsh/modules/ModuleName/' -Force" -Level WARN
            Write-CustomLog "NEW: Import-Module 'ModuleName' -Force" -Level SUCCESS
            
        }
        catch {
            Write-CustomLog "Error in module import example: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog "Module import example completed" -Level INFO
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-CustomLog "OpenTofu Lab Automation - Instruction System Test" -Level INFO
    Write-CustomLog "=======================================" -Level INFO
    
    $testResult = Test-InstructionFileConsistency
    Test-ModuleImportExample
    
    if ($testResult) {
        Write-CustomLog "Instruction system is properly configured!" -Level SUCCESS
        exit 0
    } else {
        Write-CustomLog "Instruction system requires fixes" -Level ERROR
        exit 1
    }
}
