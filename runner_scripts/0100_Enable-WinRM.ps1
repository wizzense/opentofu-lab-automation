Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

# Param([pscustomobject]$Config)
# Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'LabRunner.psm1')

Write-CustomLog "Starting $MyInvocation.MyCommand"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"



# Check if WinRM is already configured
$winrmStatus = Get-Service -Name WinRM -ErrorAction SilentlyContinue

if ($winrmStatus -and $winrmStatus.Status -eq 'Running') {
    Write-CustomLog "WinRM is already enabled and running."
} else {
    Write-CustomLog "Enabling WinRM via Enable-PSRemoting -Force"

    # WinRM QuickConfig
    Enable-PSRemoting -Force
    Write-CustomLog "Enable-PSRemoting executed"
    
    # Optionally configure additional authentication methods, etc.:
    # e.g.: Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    
    Write-CustomLog "WinRM has been enabled."
}
    Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
}
