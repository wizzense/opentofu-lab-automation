<#
.SYNOPSIS
Example of modern test using the extensible framework

.DESCRIPTION
This demonstrates how to use the new testing framework for installer scripts.
Compare this with the original Install-Go.Tests.ps1 to see the improvements.
#>

. (Join-Path $PSScriptRoot '..' 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot '..' 'helpers' 'TestHelpers.ps1')

. (Join-Path $PSScriptRoot '..' 'helpers' 'TestTemplates.ps1')

# Simple, declarative test using the framework
New-InstallerScriptTest -ScriptName '0007_Install-Go.ps1' -EnabledProperty 'InstallGo' -InstallerCommand 'Start-Process' -SoftwareCommandName 'go' -EnabledConfig @{
    Go = @{ 
        InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' 
    }
} -RequiredPlatforms @('Windows') -AdditionalMocks @{
    'Get-Command' = { 
        param($Name)
        



if ($Name -eq 'go') { return $null } 
        return [PSCustomObject]@{ Name = $Name; Source = "/usr/bin/$Name" }
    }
}


