. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Reset-Machine script' {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '9999_Reset-Machine.ps1'
        . (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'Get-Platform.ps1')
    }

    BeforeEach {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
    }

    It 'invokes sysprep and configures Remote Desktop on Windows'  {
        Mock Get-Platform { 'Windows' }
        $sysprep = 'C:\\Windows\\System32\\Sysprep\\Sysprep.exe'
        Mock Test-Path { $true } -ParameterFilter { $Path -eq $sysprep }
        Mock Start-Process {}
        Mock Set-ItemProperty {}
        if (-not (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue)) {
            function global:New-NetFirewallRule {}
        }
        Mock New-NetFirewallRule {}
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $false; FirewallPorts = @() }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 1 } }
        . $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Start-Process -Times 1 -ParameterFilter {
            $FilePath -eq $sysprep -and $ArgumentList -eq '/generalize /oobe /shutdown /quiet' -and $Wait
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1
        Should -Invoke -CommandName New-NetFirewallRule -Times 1
    }

    It 'calls Restart-Computer on Linux' {
        Mock Get-Platform { 'Linux' }
        Mock Restart-Computer {}
        . $script:ScriptPath -Config ([pscustomobject]@{})
        Should -Invoke -CommandName Restart-Computer -Times 1
    }

    It 'returns exit code 1 for unknown platform' {
        Mock Get-Platform { 'Unknown' }
        Mock Restart-Computer {}
        try {
            . $script:ScriptPath -Config ([pscustomobject]@{})
            $code = $LASTEXITCODE
        } catch {
            $code = 1
        }
        $code | Should -Be 1
        Should -Invoke -CommandName Restart-Computer -Times 0
    }

    AfterAll {
        $cmd = Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.CommandType -eq 'Function') {
            Remove-Item Function:\New-NetFirewallRule -ErrorAction SilentlyContinue
        }
    }
}
