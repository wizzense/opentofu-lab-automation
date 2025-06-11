#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../lab_utils/Get-Platform.ps1

if (-not $script:LabRunner__Loaded) {
    $script:LabRunner__Loaded = $true
    . "$PSScriptRoot/ScriptTemplate.ps1"
}

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Get-Platform
