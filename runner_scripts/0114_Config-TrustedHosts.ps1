Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

if ($Config.SetTrustedHosts -eq $true) {
    
    start-process cmd.exe -ArgumentList "/d /c winrm set winrm/config/client @{TrustedHosts=`"$Config.TrustedHosts`"}"

} else {
    Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
}



}

