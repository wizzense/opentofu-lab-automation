Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {

if ($Config.SetDNSServers -eq $true) {
    
    $interfaceIndex = (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1 -ExpandProperty InterfaceIndex)
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $Config.DNSServers

} else {
    Write-CustomLog "SetDNSServers flag is disabled. Skipping DNS configuration."
}
}
