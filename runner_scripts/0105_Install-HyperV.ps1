Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

if ($Config.InstallHyperV -eq $true) {
    Write-Log "Checking if Hyper-V is already installed..."

    # Get the installation state of Hyper-V
    $feature = Get-WindowsFeature -Name Hyper-V

    if ($feature -and $feature.Installed) {
        Write-Log "Hyper-V is already installed. Skipping installation."
        exit 0
    }

    Write-Log "Hyper-V is not installed. Proceeding with installation..."

    $enableMgtTools = $Config.HyperV.EnableManagementTools -eq $true
    $restart = $false  # Change to $true if you want an automatic restart

    try {

        if ($restart) {
            Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools:$enableMgtTools -Restart -ErrorAction Continue
        } else {
            Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools:$enableMgtTools -ErrorAction Continue
        }
    }
    catch {
        Write-Log "Only works on Windows Server."
    }


    Write-Log "Hyper-V installation complete. A restart is typically required to finalize installation."
}