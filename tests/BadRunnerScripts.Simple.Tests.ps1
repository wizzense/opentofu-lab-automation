#!/usr/bin/env pwsh
# /workspaces/opentofu-lab-automation/tests/BadRunnerScripts.Simple.Tests.ps1

Describe "Bad Runner Scripts Handling - Core Tests" {
    
    BeforeAll {
        # Source the validation functions directly
        . "$PSScriptRoot/../pwsh/modules/LabRunner/Public/Test-RunnerScriptSafety.ps1"
        
        # Set up test environment
        $TestRunnerScriptsDir = "$TestDrive/runner_scripts"
        New-Item -ItemType Directory -Path $TestRunnerScriptsDir -Force | Out-Null
    }
    
    Context "Script Name Validation" {
        It "should reject scripts with spaces in filename" {
            $badScript = "$TestRunnerScriptsDir/bad script name.ps1"
            "Write-Host 'Hello'" | Out-File $badScript -Encoding UTF8
            
            { Test-RunnerScriptName $badScript } | Should -Throw "*Invalid script name*"
        }
        
        It "should accept valid script names" {
            $goodScript = "$TestRunnerScriptsDir/0999_ValidScript.ps1"
            "Write-Host 'Hello'" | Out-File $goodScript -Encoding UTF8
            
            { Test-RunnerScriptName $goodScript } | Should -Not -Throw
        }
    }
    
    Context "Security Validation" {
        It "should detect dangerous commands" {
            $maliciousScript = @"
# This script tries to do dangerous things
Remove-Item C:\ -Recurse -Force
"@
            $scriptPath = "$TestRunnerScriptsDir/0999_MaliciousScript.ps1"
            $maliciousScript | Out-File $scriptPath -Encoding UTF8
            
            { Test-RunnerScriptSafety $scriptPath } | Should -Throw "*dangerous*"
        }
        
        It "should detect hardcoded credentials" {
            $credentialScript = @"
# Script with hardcoded credentials
`$password = "SuperSecret123!"
"@
            $scriptPath = "$TestRunnerScriptsDir/0998_CredentialScript.ps1"
            $credentialScript | Out-File $scriptPath -Encoding UTF8
            
            { Test-RunnerScriptSafety $scriptPath } | Should -Throw "*credentials*"
        }
        
        It "should allow safe scripts" {
            $safeScript = @"
# Safe script
Write-Host "Installing something safely..."
"@
            $scriptPath = "$TestRunnerScriptsDir/0997_SafeScript.ps1"
            $safeScript | Out-File $scriptPath -Encoding UTF8
            
            { Test-RunnerScriptSafety $scriptPath } | Should -Not -Throw
        }
    }
    
    Context "Syntax Validation" {
        It "should detect syntax errors" {
            $syntaxErrorScript = @"
# Script with syntax errors
if (`$true {
    Write-Host "Missing closing brace"
"@
            $scriptPath = "$TestRunnerScriptsDir/0996_SyntaxError.ps1"
            $syntaxErrorScript | Out-File $scriptPath -Encoding UTF8
            
            $result = Test-RunnerScriptSyntax $scriptPath
            $result.HasErrors | Should -Be $true
        }
        
        It "should detect valid syntax" {
            $validScript = @"
# Script with valid syntax
if (`$true) {
    Write-Host "Valid syntax"
}
"@
            $scriptPath = "$TestRunnerScriptsDir/0995_ValidSyntax.ps1"
            $validScript | Out-File $scriptPath -Encoding UTF8
            
            $result = Test-RunnerScriptSyntax $scriptPath
            $result.HasErrors | Should -Be $false
        }
    }
    
    AfterAll {
        # Clean up test artifacts
        if (Test-Path $TestRunnerScriptsDir) {
            Remove-Item $TestRunnerScriptsDir -Recurse -Force
        }
    }
}
