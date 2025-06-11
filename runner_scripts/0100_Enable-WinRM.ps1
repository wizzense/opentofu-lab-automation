Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0100_Enable-WinRM.ps1'



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
}
