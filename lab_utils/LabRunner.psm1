#. dot-source utilities
. $PSScriptRoot/../runner_utility_scripts/Logger.ps1
. $PSScriptRoot/Get-Platform.ps1

if (-not $script:LabRunner__Loaded) {
    $script:LabRunner__Loaded = $true
    . "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
}

Export-ModuleMember -Function Invoke-LabScript, Invoke-LabStep, Write-CustomLog, Get-Platform
