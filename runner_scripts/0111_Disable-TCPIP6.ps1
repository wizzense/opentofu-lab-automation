Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

if ($Config.DisableTCPIP6 -eq $true) {
    
    Get-NetAdapterBinding -ComponentID 'ms_tcpip6' | where-object enabled -eq $true | Disable-NetAdapterBinding -ComponentID 'ms_tcpip6'

} else {
    Write-CustomLog "DisableTCPIP6 flag is disabled. Skipping IPv6 configuration."
}


}

