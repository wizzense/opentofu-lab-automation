#Requires -Version 7.0

<#
.SYNOPSIS
    Gets information about the current platform.
    
.DESCRIPTION
    Determines the current operating system platform (Windows, Linux, macOS) using PowerShell built-in variables.
    
.EXAMPLE
    Get-PlatformInfo
#>
function Get-PlatformInfo {
    [CmdletBinding()]
    param()
    
    process {
        if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and -not (Get-Command uname -ErrorAction SilentlyContinue))) {
            return "Windows"
        } elseif ($IsMacOS -or (uname) -eq "Darwin") {
            return "macOS"
        } elseif ($IsLinux -or (uname) -match "Linux") {
            return "Linux"
        } else {
            return "Unknown"
        }
    }
}
