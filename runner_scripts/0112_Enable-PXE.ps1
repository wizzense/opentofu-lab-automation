Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0112_Enable-PXE.ps1'

if ($Config.ConfigPXE -eq $true) {

    Write-CustomLog "Adding inbound firewall rule 'prov-pxe-67' (UDP 67)"
    New-NetFirewallRule -DisplayName prov-pxe-67 -Enabled True -Direction inbound -Protocol udp -LocalPort 67 -Action Allow -RemoteAddress any
    Write-CustomLog "Adding inbound firewall rule 'prov-pxe-69' (UDP 69)"
    New-NetFirewallRule -DisplayName prov-pxe-69 -Enabled True -Direction inbound -Protocol udp -LocalPort 69 -Action Allow -RemoteAddress any
    Write-CustomLog "Adding inbound firewall rule 'prov-pxe-17519' (TCP 17519)"
    New-NetFirewallRule -DisplayName prov-pxe-17519 -Enabled True -Direction inbound -Protocol tcp -LocalPort 17519 -Action Allow -RemoteAddress any
    Write-CustomLog "Adding inbound firewall rule 'prov-pxe-17530' (TCP 17530)"
    New-NetFirewallRule -DisplayName prov-pxe-17530 -Enabled True -Direction inbound -Protocol tcp -LocalPort 17530 -Action Allow -RemoteAddress any

} else {
    Write-CustomLog 'ConfigPXE is false. Skipping PXE firewall configuration.'
}
}
