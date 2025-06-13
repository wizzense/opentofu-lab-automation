



# filepath: tests/0000_Cleanup-Files.Tests.ps1
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '0000_Cleanup-Files Tests' -Tag 'Maintenance' {
    BeforeAll {
        # Get the script path using the LabRunner function  
        $script:ScriptPath = Get-RunnerScriptPath '0000_Cleanup-Files.ps1'
        if (-not $script:ScriptPath -or -not (Test-Path $script:ScriptPath)) {
            throw "Script under test not found: 0000_Cleanup-Files.ps1 (resolved path: $script:ScriptPath)"
        }
        
        # Set up test environment
        $script:TestConfig = Get-TestConfiguration
        $script:SkipNonWindows = -not (Get-Platform).IsWindows
        $script:SkipNonLinux = -not (Get-Platform).IsLinux
        $script:SkipNonMacOS = -not (Get-Platform).IsMacOS
        $script:SkipNonAdmin = -not (Test-IsAdministrator)
        
        # Set up standard mocks
        Disable-InteractivePrompts
        New-StandardMocks
    }
        
        Context 'Script Structure Validation' {
            It 'should have valid PowerShell syntax' {
                $errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
                $(if (errors) { $errors.Count  } else { 0 }) | Should -Be 0
            }
        It 'should follow naming conventions' {
                $scriptName = [System.IO.Path]::GetFileName($script:ScriptPath)
                $scriptName | Should -Match '^[0-9]{4}_[A-Z][a-zA-Z0-9-]+\.ps1$|^[A-Z][a-zA-Z0-9-]+\.ps1$'
            }
        It 'should have Config parameter' {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match 'Param\s*\(\s*.*\$Config'
            }
        It 'should import LabRunner module' {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match 'Import-Module.*LabRunner'
            }
        It 'should contain Invoke-LabStep call' {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match 'Invoke-LabStep'
            }
        }
        
        Context 'Basic Functionality' {
            It 'should execute without errors with valid config' {
                $config = [pscustomobject]@{}
                $configJson = $config | ConvertTo-Json -Depth 5
                $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
                $configJson | Set-Content -Path $tempConfig
                try {
                    $pwsh = (Get-Command pwsh).Source
                    { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
                } finally {
                    Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
                }
            }
        It 'should handle whatif parameter' {
                $config = [pscustomobject]@{}
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
        
        AfterAll {
            # Cleanup any test artifacts
        }
}




