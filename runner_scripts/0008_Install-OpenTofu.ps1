Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
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
    param([pscustomobject]$Config)

    Invoke-LabStep -Config $Config -Body {
        Write-CustomLog 'Running 0008_Install-OpenTofu.ps1'

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
