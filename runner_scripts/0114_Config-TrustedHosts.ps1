Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0114_Config-TrustedHosts.ps1'

if ($Config.SetTrustedHosts -eq $true) {
    
    Start-Process -FilePath cmd.exe -ArgumentList "/d /c winrm set winrm/config/client @{TrustedHosts=`"$Config.TrustedHosts`"}

} else {
    Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
}
}
