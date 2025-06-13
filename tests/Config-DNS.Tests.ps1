






. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0113_Config-DNS' -Skip:($SkipNonWindows) {
    BeforeAll {
        Enable-WindowsMocks
    }
        It 'calls Set-DnsClientServerAddress with value from config'  {
        $script = Get-RunnerScriptPath '0113_Config-DNS.ps1'
        $config = [pscustomobject]@{
            SetDNSServers = $true
            DNSServers    = '1.2.3.4'
        }

        # Mock Windows-specific cmdlets for cross-platform compatibility
        Mock Get-NetIPAddress { [pscustomobject]@{ InterfaceIndex = 99 } }
        Mock Set-DnsClientServerAddress {}

        & $script -Config $config

        Should -Invoke -CommandName Set-DnsClientServerAddress -Times 1 -ParameterFilter {
            $InterfaceIndex -eq 99 -and $ServerAddresses -eq '1.2.3.4'
        }
    }
}




