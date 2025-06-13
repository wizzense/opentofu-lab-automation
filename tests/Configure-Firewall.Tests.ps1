



. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0102_Configure-Firewall' -Skip:($SkipNonWindows) {
    BeforeAll {
        Enable-WindowsMocks
        $script:ScriptPath = Get-RunnerScriptPath '0102_Configure-Firewall.ps1'
        Mock New-NetFirewallRule {}
    }
        It 'creates firewall rules for each port when ports are specified' {
        $cfg = [pscustomobject]@{ FirewallPorts = @(80, 443) }
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName New-NetFirewallRule -Times 2
    }
        It 'skips when no FirewallPorts are provided' {
        $cfg = [pscustomobject]@{ FirewallPorts = $null }
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName New-NetFirewallRule -Times 0
    }
}


