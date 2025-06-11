#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../lab_utils/Get-Platform.ps1

# LabRunner should be imported by runner scripts before dot-sourcing
# ScriptTemplate.ps1. Avoid dot-sourcing here to prevent circular imports.

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Get-Platform
