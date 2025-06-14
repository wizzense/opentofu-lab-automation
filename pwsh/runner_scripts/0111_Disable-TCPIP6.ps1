Param([object]$Config)







Import-Module "/C:\Users\alexa\OneDrive\Documents\0. wizzense\opentofu-lab-automation//pwsh/modules/LabRunner/" -Force -Force -Force -Force -Force -Force -ForceWrite-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.DisableTCPIP6 -eq $true) {
    Write-CustomLog 'Disabling IPv6 bindings on all adapters'
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | where-object enabled -eq $true | Disable-NetAdapterBinding -ComponentID 'ms_tcpip6'
    Write-CustomLog 'IPv6 bindings disabled'

} else {
    Write-CustomLog "DisableTCPIP6 flag is disabled. Skipping IPv6 configuration."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"















