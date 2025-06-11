Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0114_Config-TrustedHosts.ps1'

    if ($Config.SetTrustedHosts -eq $true) {
        $args = "/d /c winrm set winrm/config/client @{TrustedHosts=`"$($Config.TrustedHosts)`"}"
        Write-CustomLog "Configuring TrustedHosts with: $args"
        Start-Process -FilePath cmd.exe -ArgumentList $args
        Write-CustomLog 'TrustedHosts configured'
    } else {
        Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
    }
}
