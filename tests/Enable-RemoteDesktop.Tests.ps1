. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0101_Enable-RemoteDesktop' -Skip:$SkipNonWindows  {
    BeforeAll {
        Enable-WindowsMocks
        $script:ScriptPath = Get-RunnerScriptPath '0101_Enable-RemoteDesktop.ps1'
    }

    It 'enables RDP when allowed and currently disabled' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $true }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 1 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Set-ItemProperty -Times 1
    }

    It 'skips registry change when already enabled' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $true }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 0 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Set-ItemProperty -Times 0
    }

    It 'does nothing when AllowRemoteDesktop is false' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $false }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 1 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Set-ItemProperty -Times 0
    }
}
