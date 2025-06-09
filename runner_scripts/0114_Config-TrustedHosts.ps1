Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {

if ($Config.SetTrustedHosts -eq $true) {
    
    start-process cmd.exe -ArgumentList "/d /c winrm set winrm/config/client @{TrustedHosts=`"$Config.TrustedHosts`"}"

} else {
    Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
}
}
