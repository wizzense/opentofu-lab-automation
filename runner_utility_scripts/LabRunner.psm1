#. dot-source utilities

. (Join-Path $PSScriptRoot 'ScriptTemplate.ps1')   # pulls in Invoke-LabStep, etc.
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../lab_utils/Get-Platform.ps1

# Only this side (LabRunner) brings ScriptTemplate in.

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Read-LoggedInput, Get-Platform, Get-LabConfig
