Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0114_Config-TrustedHosts.ps1'

    if ($Config.SetTrustedHosts -eq $true) {
        $args = "/d /c winrm set winrm/config/client @{TrustedHosts=`"$($Config.TrustedHosts)`"}"
        Start-Process -FilePath cmd.exe -ArgumentList $args
    } else {
        Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
    }
}
