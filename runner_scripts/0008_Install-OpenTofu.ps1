Param([object]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner/LabRunner.psd1"
Write-CustomLog "Starting $MyInvocation.MyCommand"
function Invoke-OpenTofuInstaller {
    param(
        [string]$CosignPath,
        [string]$OpenTofuVersion
    )
    $installer = (
        Resolve-Path (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1')
    ).Path
    Write-CustomLog "Running OpenTofuInstaller.ps1 with version $OpenTofuVersion"
    & $installer -installMethod standalone -cosignPath $CosignPath -opentofuVersion $OpenTofuVersion
    Write-CustomLog 'OpenTofu installer completed'
}

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
    }
}

if ($MyInvocation.InvocationName -ne '.') { Install-OpenTofu @PSBoundParameters }
