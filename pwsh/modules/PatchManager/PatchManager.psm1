#
# OpenTofu Lab Automation - PatchManager Module
# 

<#
.SYNOPSIS
    Main module file for the PatchManager module.
.DESCRIPTION
    This module provides functions for managing patches, fixes, and maintenance tasks in the OpenTofu Lab Automation project.
    It unifies and standardizes the approach to solving common issues and provides a robust foundation for automating
    maintenance tasks.
#>

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the private files first, then public files
foreach ($import in @($Private + $Public)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

# Export Public functions
$PublicFunctions = $Public | ForEach-Object { $_.BaseName }
Export-ModuleMember -Function $PublicFunctions
