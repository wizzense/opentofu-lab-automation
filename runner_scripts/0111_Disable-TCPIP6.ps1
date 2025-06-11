Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0111_Disable-TCPIP6.ps1'

if ($Config.DisableTCPIP6 -eq $true) {
    Write-CustomLog 'Disabling IPv6 bindings on all adapters'
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | where-object enabled -eq $true | Disable-NetAdapterBinding -ComponentID 'ms_tcpip6'
    Write-CustomLog 'IPv6 bindings disabled'

} else {
    Write-CustomLog "DisableTCPIP6 flag is disabled. Skipping IPv6 configuration."
}
}
