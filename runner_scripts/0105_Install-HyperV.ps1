Param([pscustomobject]$Config)
Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'LabRunner.psm1')
Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

if ($Config.InstallHyperV -eq $true) {
    Write-CustomLog "Checking if Hyper-V is already installed..."

    # Get the installation state of Hyper-V
    $feature = Get-WindowsFeature -Name Hyper-V

    if ($feature -and $feature.Installed) {
        Write-CustomLog "Hyper-V is already installed. Skipping installation."
        exit 0
    }

    Write-CustomLog "Hyper-V is not installed. Proceeding with installation..."

    $enableMgtTools = $true
    if ($Config.PSObject.Properties.Name -contains 'HyperV' -and
        $Config.HyperV.PSObject.Properties.Name -contains 'EnableManagementTools') {
        $enableMgtTools = [bool]$Config.HyperV.EnableManagementTools
    }
    $restart = $false  # Change to $true if you want an automatic restart

    try {

        if ($restart) {
            Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools:$enableMgtTools -Restart -ErrorAction Continue
        } else {
            Install-WindowsFeature -Name "Hyper-V" -IncludeManagementTools:$enableMgtTools -ErrorAction Continue
        }
    }
    catch {
        Write-CustomLog "Only works on Windows Server."
    }


    Write-CustomLog "Hyper-V installation complete. A restart is typically required to finalize installation."
} else {
    Write-CustomLog "InstallHyperV flag is disabled. Skipping Hyper-V installation."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
