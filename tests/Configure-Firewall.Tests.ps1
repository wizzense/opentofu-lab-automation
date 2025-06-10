. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0102_Configure-Firewall' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0102_Configure-Firewall.ps1'
    }

    It 'creates firewall rules for each port when ports are specified' {
        $cfg = [pscustomobject]@{ FirewallPorts = @(80, 443) }
        Mock New-NetFirewallRule {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled New-NetFirewallRule -Times 2
    }

    It 'skips when no FirewallPorts are provided' {
        $cfg = [pscustomobject]@{ FirewallPorts = $null }
        Mock New-NetFirewallRule {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled New-NetFirewallRule -Times 0
    }
}
