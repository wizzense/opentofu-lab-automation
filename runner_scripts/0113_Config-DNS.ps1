Param([pscustomobject]$Config)
Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'LabRunner.psm1')
Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.SetDNSServers -eq $true) {
    $interfaceIndex = (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1 -ExpandProperty InterfaceIndex)
    Write-CustomLog "Setting DNS servers to $($Config.DNSServers) on interface $interfaceIndex"
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $Config.DNSServers
    Write-CustomLog 'DNS servers configured'

} else {
    Write-CustomLog "SetDNSServers flag is disabled. Skipping DNS configuration."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
