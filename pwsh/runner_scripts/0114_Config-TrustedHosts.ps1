Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"
Param([object]$Config)

Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

    if ($Config.SetTrustedHosts -eq $true) {
        $args = "/d /c winrm set winrm/config/client @{TrustedHosts=`"$($Config.TrustedHosts)`"}"
        Write-CustomLog "Configuring TrustedHosts with: $args"
        Start-Process -FilePath cmd.exe -ArgumentList $args
        Write-CustomLog 'TrustedHosts configured'
    } else {
        Write-CustomLog "SetTrustedHosts flag is disabled. Skipping TrustedHosts configuration."
    }
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
