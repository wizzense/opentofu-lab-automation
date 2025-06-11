#. dot-source utilities
. $PSScriptRoot/ScriptTemplate.ps1
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../lab_utils/Get-Platform.ps1

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Get-Platform
