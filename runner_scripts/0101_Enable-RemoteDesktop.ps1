Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

# Check current Remote Desktop status
$currentStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections"

if ($Config.AllowRemoteDesktop -eq $true) {
    if ($currentStatus.fDenyTSConnections -eq 0) {
        Write-Log "Remote Desktop is already enabled."
    }
    else {
        Write-Log "Enabling Remote Desktop..."
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                         -Name "fDenyTSConnections" `
                         -Value 0
    }
}
else {
    Write-Log "Remote Desktop is NOT enabled by config."
}
