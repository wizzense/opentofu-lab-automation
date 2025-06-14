Param([object]$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

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
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















