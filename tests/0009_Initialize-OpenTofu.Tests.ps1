# filepath: tests/0009_Initialize-OpenTofu.Tests.ps1
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

BeforeAll {
    # Load the script under test
    $scriptPath = Join-Path $PSScriptRoot '..' '/workspaces/opentofu-lab-automation/pwsh/runner_scripts/0009_Initialize-OpenTofu.ps1'
    if (Test-Path $scriptPath) {
        . $scriptPath
    }
    
    # Set up test environment
    $TestConfig = Get-TestConfiguration
    $SkipNonWindows = -not (Get-Platform).IsWindows
    $SkipNonLinux = -not (Get-Platform).IsLinux
    $SkipNonMacOS = -not (Get-Platform).IsMacOS
    $SkipNonAdmin = -not (Test-IsAdministrator)
}

Describe '0009_Initialize-OpenTofu Tests' -Tag 'Unknown' {
    
    Context 'Script Structure Validation' {
        It 'should have valid PowerShell syntax' -Skip:($SkipNonWindows) {
            $scriptPath | Should -Exist
            { . $scriptPath } | Should -Not -Throw
        }
        
        It 'should follow naming conventions' -Skip:($SkipNonWindows) {
            $scriptName = [System.IO.Path]::GetFileName($scriptPath)
            $scriptName | Should -Match '^[0-9]{4}_[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
        }
    }
    
    Context 'Parameter Validation' {
        It 'should accept Config parameter' -Skip:($SkipNonWindows) {
            { & $scriptPath -Config 'TestValue' -WhatIf } | Should -Not -Throw
        }
    }
}

# Clean up test environment
AfterAll {
    # Restore any modified system state
    # Remove test artifacts
}
