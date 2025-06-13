






# filepath: tests/0200_Get-SystemInfo.Tests.ps1
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

BeforeAll {
    # Load the script under test
    # Get the script path using the LabRunner function  
        $script:ScriptPath = Get-RunnerScriptPath '0200_Get-SystemInfo.ps1'
        if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
            throw "Script under test not found: 0200_Get-SystemInfo.ps1 (resolved path: $script:ScriptPath)"
        }
    # Script will be tested via pwsh -File execution
    
    # Set up test environment
    $TestConfig = Get-TestConfiguration
    $SkipNonWindows = -not (Get-Platform).IsWindows
    $SkipNonLinux = -not (Get-Platform).IsLinux
    $SkipNonMacOS = -not (Get-Platform).IsMacOS
    $SkipNonAdmin = -not (Test-IsAdministrator)
}

Describe '0200_Get-SystemInfo Tests' -Tag 'Feature' {
    
    Context 'Script Structure Validation' {
         | Should -Not -Throw
        }
        _[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
        }
        
    }
    
    Context 'Parameter Validation' {
        
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
         | Should -Not -Throw
        }
    }
    
    

# Clean up test environment
AfterAll {
    # Restore any modified system state
    # Remove test artifacts
}







