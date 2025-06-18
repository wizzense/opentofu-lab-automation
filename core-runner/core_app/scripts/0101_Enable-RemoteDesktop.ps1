#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter()]
    [object]$Config
)

$modulePath = Join-Path -Path $env:PWSH_MODULES_PATH -ChildPath "LabRunner"
Import-Module $modulePath -Force
Write-CustomLog "Starting $($MyInvocation.MyCommand.Name)"

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

    # Check current Remote Desktop status
    $currentStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections'

    if ($Config.AllowRemoteDesktop -eq $true) {
        if ($currentStatus.fDenyTSConnections -eq 0) {
            Write-CustomLog "Remote Desktop is already enabled."
        }
        else {
            Write-CustomLog "Enabling Remote Desktop via Set-ItemProperty"
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                             -Name 'fDenyTSConnections' `
                             -Value 0
            Write-CustomLog "Remote Desktop enabled"
        }
    }
    else {
        if ($currentStatus.fDenyTSConnections -ne 1) {
            Write-CustomLog "Disabling Remote Desktop via Set-ItemProperty"
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                             -Name 'fDenyTSConnections' `
                             -Value 1
            Write-CustomLog "Remote Desktop disabled"
        }
        else {
            Write-CustomLog "Remote Desktop is already disabled."
        }
    }

    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}

