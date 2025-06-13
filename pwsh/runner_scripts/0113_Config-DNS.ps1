Param([object]$Config)




Import-Module "$PSScriptRoot/../modules/LabRunner/LabRunner.psd1" -Force

Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.SetDNSServers -eq $true) {
    $mockInterface = [PSCustomObject]@{ InterfaceIndex = 1 }
    $interfaceIndex = (Invoke-CrossPlatformCommand -CommandName 'Get-NetIPAddress' -Parameters @{ AddressFamily = 'IPv4' } -MockResult @($mockInterface) | Select-Object -First 1 -ExpandProperty InterfaceIndex)
    Write-CustomLog "Setting DNS servers to $($Config.DNSServers) on interface $interfaceIndex"
    Invoke-CrossPlatformCommand -CommandName 'Set-DnsClientServerAddress' -Parameters @{ InterfaceIndex = $interfaceIndex; ServerAddresses = $Config.DNSServers } -SkipOnUnavailable
    Write-CustomLog 'DNS servers configured'
} else {
    Write-CustomLog "SetDNSServers flag is disabled. Skipping DNS configuration."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"


