Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"
Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.DisableTCPIP6 -eq $true) {
    Write-CustomLog 'Disabling IPv6 bindings on all adapters'
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | where-object enabled -eq $true | Disable-NetAdapterBinding -ComponentID 'ms_tcpip6'
    Write-CustomLog 'IPv6 bindings disabled'

} else {
    Write-CustomLog "DisableTCPIP6 flag is disabled. Skipping IPv6 configuration."
}
}
