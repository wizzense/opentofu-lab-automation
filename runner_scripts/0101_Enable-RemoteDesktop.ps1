Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

# Check current Remote Desktop status
$currentStatus = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections"

if ($Config.AllowRemoteDesktop -eq $true) {
    if ($currentStatus.fDenyTSConnections -eq 0) {
        Write-CustomLog "Remote Desktop is already enabled."
    }
    else {
        Write-CustomLog "Enabling Remote Desktop..."
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
                         -Name "fDenyTSConnections" `
                         -Value 0
    }
}
else {
    Write-CustomLog "Remote Desktop is NOT enabled by config."
}
}

