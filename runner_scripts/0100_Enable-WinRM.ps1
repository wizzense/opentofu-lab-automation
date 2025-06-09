Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)

. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

# Check if WinRM is already configured
$winrmStatus = Get-Service -Name WinRM -ErrorAction SilentlyContinue

if ($winrmStatus -and $winrmStatus.Status -eq 'Running') {
    Write-CustomLog "WinRM is already enabled and running."
} else {
    Write-CustomLog "Enabling WinRM..."
    
    # WinRM QuickConfig
    Enable-PSRemoting -Force
    
    # Optionally configure additional authentication methods, etc.:
    # e.g.: Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    
    Write-CustomLog "WinRM has been enabled."
}

}

