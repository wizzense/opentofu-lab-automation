Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner.psd1"
Invoke-LabScript -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.DisableTCPIP6 -eq $true) {
    Write-CustomLog 'Disabling IPv6 bindings on all adapters'
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | where-object enabled -eq $true | Disable-NetAdapterBinding -ComponentID 'ms_tcpip6'
    Write-CustomLog 'IPv6 bindings disabled'

} else {
    Write-CustomLog "DisableTCPIP6 flag is disabled. Skipping IPv6 configuration."
}
}
