. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0111_Disable-TCPIP6' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0111_Disable-TCPIP6.ps1'
    }

    It 'disables IPv6 bindings when flag is true' {
        $cfg = [pscustomobject]@{ DisableTCPIP6 = $true }
        Mock Get-NetAdapterBinding { @{ } }
        Mock Disable-NetAdapterBinding {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Disable-NetAdapterBinding -Times 1
    }

    It 'skips when flag is false' {
        $cfg = [pscustomobject]@{ DisableTCPIP6 = $false }
        Mock Disable-NetAdapterBinding {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Disable-NetAdapterBinding -Times 0
    }
}
