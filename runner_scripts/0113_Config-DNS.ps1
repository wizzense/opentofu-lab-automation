Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0113_Config-DNS.ps1'

if ($Config.SetDNSServers -eq $true) {
    $interfaceIndex = (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1 -ExpandProperty InterfaceIndex)
    Write-CustomLog "Setting DNS servers to $($Config.DNSServers) on interface $interfaceIndex"
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $Config.DNSServers
    Write-CustomLog 'DNS servers configured'

} else {
    Write-CustomLog "SetDNSServers flag is disabled. Skipping DNS configuration."
}
}
