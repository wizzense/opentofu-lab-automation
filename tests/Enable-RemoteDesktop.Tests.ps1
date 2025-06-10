. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0101_Enable-RemoteDesktop' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0101_Enable-RemoteDesktop.ps1'
    }

    It 'enables RDP when allowed and currently disabled' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $true }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 1 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Set-ItemProperty -Times 1
    }

    It 'skips registry change when already enabled' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $true }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 0 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Set-ItemProperty -Times 0
    }

    It 'does nothing when AllowRemoteDesktop is false' {
        $cfg = [pscustomobject]@{ AllowRemoteDesktop = $false }
        Mock Get-ItemProperty { [pscustomobject]@{ fDenyTSConnections = 1 } }
        Mock Set-ItemProperty {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Set-ItemProperty -Times 0
    }
}
