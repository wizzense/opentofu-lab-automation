Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0008_Install-OpenTofu.ps1'

if ($Config.InstallOpenTofu -eq $true) {
    
    $Cosign = Join-Path $Config.CosignPath "cosign-windows-amd64.exe"
    $installer = Join-Path $PSScriptRoot "..\runner_utility_scripts\OpenTofuInstaller.ps1"
    $openTofuVersion = if ($Config.OpenTofuVersion) { $Config.OpenTofuVersion } else { 'latest' }
    & $installer -installMethod standalone -cosignPath $Cosign -opentofuVersion $openTofuVersion
} else {
    Write-CustomLog "InstallOpenTofu flag is disabled. Skipping OpenTofu installation."
}
}
