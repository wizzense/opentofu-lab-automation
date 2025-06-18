#Requires -Version 7





Import-Module "$env:PROJECT_ROOT/core-runner/modules/LabRunner/" -Force
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
    Write-CustomLog 'Remote Desktop remains disabled as per configuration.'
}

Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
