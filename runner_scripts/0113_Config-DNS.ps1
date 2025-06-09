Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

if ($Config.SetDNSServers -eq $true) {
    
    $interfaceIndex = (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1 -ExpandProperty InterfaceIndex)
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $Config.DNSServers

} else {
    Write-CustomLog "SetDNSServers flag is disabled. Skipping DNS configuration."
}
}

