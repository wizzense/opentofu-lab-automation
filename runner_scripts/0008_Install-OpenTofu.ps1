Param([object]$Config)

Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"

# Param([pscustomobject]$Config)
# Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'LabRunner.psd1')

Write-CustomLog "Starting $MyInvocation.MyCommand"

function Install-OpenTofu {
    [CmdletBinding()]
    param([object]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

        if ($Config.InstallOpenTofu -eq $true) {
            $Cosign = Join-Path $Config.CosignPath "cosign-windows-amd64.exe"
            $openTofuVersion = if ($Config.OpenTofuVersion) { $Config.OpenTofuVersion } else { 'latest' }
            Invoke-OpenTofuInstaller -CosignPath $Cosign -OpenTofuVersion $openTofuVersion
        } else {
            Write-CustomLog "InstallOpenTofu flag is disabled. Skipping OpenTofu installation."
        }
        Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-OpenTofu @PSBoundParameters }
Write-CustomLog "Completed $($MyInvocation.MyCommand.Name)"
