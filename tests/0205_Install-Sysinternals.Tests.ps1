



# filepath: tests/0205_Install-Sysinternals.Tests.ps1
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

BeforeAll {
    # Load the script under test
    # Get the script path using the LabRunner function  
        $script:ScriptPath = Get-RunnerScriptPath '0205_Install-Sysinternals.ps1'
        if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
            throw "Script under test not found: 0205_Install-Sysinternals.ps1 (resolved path: $script:ScriptPath)"
        }
    # Script will be tested via pwsh -File execution
    
    # Set up test environment
    $TestConfig = Get-TestConfiguration
    $SkipNonWindows = -not (Get-Platform).IsWindows
    $SkipNonLinux = -not (Get-Platform).IsLinux
    $SkipNonMacOS = -not (Get-Platform).IsMacOS
    $SkipNonAdmin = -not (Test-IsAdministrator)
}

Describe '0205_Install-Sysinternals Tests' -Tag 'Unknown' {
    
    Context 'Script Structure Validation' {
        It 'should ' -Skip: {
            $script:ScriptPath | Should -Exist
            { . $script:ScriptPath } | Should -Not -Throw
        }
        It 'should ' -Skip: {
            $scriptName = [System.IO.Path]::GetFileName($script:ScriptPath)
            $scriptName | Should -Match '^[0-9]{4}_[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
        }
    }
    
    Context 'Parameter Validation' {
        It 'should ' -Skip: {
            $config = [pscustomobject]@{ TestProperty = 'TestValue' }
            $configJson = $config | ConvertTo-Json -Depth 5
            $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
            $configJson | Set-Content -Path $tempConfig
            try {
                $pwsh = (Get-Command pwsh).Source
                { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig -WhatIf } | Should -Not -Throw
            } finally {
                Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Clean up test environment
AfterAll {
    # Restore any modified system state
    # Remove test artifacts
}




