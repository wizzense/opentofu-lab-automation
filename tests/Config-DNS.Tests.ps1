. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0113_Config-DNS' {
    It 'calls Set-DnsClientServerAddress with value from config' -Skip:($SkipNonWindows) {
        $script = Join-Path $PSScriptRoot '..' 'runner_scripts' '0113_Config-DNS.ps1'
        $config = [pscustomobject]@{
            SetDNSServers = $true
            DNSServers    = '1.2.3.4'
        }

        Mock Get-NetIPAddress { [pscustomobject]@{ InterfaceIndex = 99 } }
        Mock Set-DnsClientServerAddress {}

        & $script -Config $config

        Assert-MockCalled Set-DnsClientServerAddress -ParameterFilter {
            $InterfaceIndex -eq 99 -and $ServerAddresses -eq '1.2.3.4'
        } -Times 1
    }
}

