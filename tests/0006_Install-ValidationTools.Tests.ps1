# .SYNOPSIS
# Tests for the 0006_Install-ValidationTools script.

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

BeforeAll {
    # Load the script under test
    $script:ScriptPath = Get-RunnerScriptPath '0006_Install-ValidationTools.ps1'
    if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
        throw "Script under test not found: 0006_Install-ValidationTools.ps1 (resolved path: $script:ScriptPath)"
    }
    # Set up test environment
    $TestConfig = Get-TestConfiguration
    $SkipNonWindows = -not (Get-Platform).IsWindows
}

Describe '0006_Install-ValidationTools Tests' -Tag 'Installer' {
    Context 'Install-Cosign Function Tests' {
        It 'should support common parameters' -Skip:($SkipNonWindows) {
            $scriptContent = Get-Content $script:ScriptPath -Raw
            $scriptContent | Should -Match '\[CmdletBinding\(\s*\(.*SupportsShouldProcess.*\)\s*\)'  # Corrected usage
        }
    }
}

# Clean up test environment
AfterAll {
    # Restore any modified system state
}



