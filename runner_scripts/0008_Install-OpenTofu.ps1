param(

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

if ($Config.InstallOpenTofu -eq $true) {
    
    $Cosign = Join-Path $Config.CosignPath "cosign-windows-amd64.exe"
    $installer = Join-Path $PSScriptRoot "..\runner_utility_scripts\OpenTofuInstaller.ps1"
    & $installer -installMethod standalone -cosignPath $Cosign
}
