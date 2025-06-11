Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

# Param([pscustomobject]$Config)
# Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

# Check current Remote Desktop status
$currentStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections"

if ($Config.AllowRemoteDesktop -eq $true) {
    if ($currentStatus.fDenyTSConnections -eq 0) {
        Write-CustomLog "Remote Desktop is already enabled."
    }
    else {
        Write-CustomLog "Enabling Remote Desktop via Set-ItemProperty"
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                         -Name "fDenyTSConnections" `
                         -Value 0
        Write-CustomLog "Remote Desktop enabled"
    }
}
else {
    Write-CustomLog "Remote Desktop is NOT enabled by config."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
