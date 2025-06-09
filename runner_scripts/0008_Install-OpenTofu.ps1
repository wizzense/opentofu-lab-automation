param(

    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\lab_utils\Invoke-LabScript.ps1"

Invoke-LabScript -Config $Config -ScriptBlock {

if ($Config.InstallOpenTofu -eq $true) {
    
    $Cosign = Join-Path $Config.CosignPath "cosign-windows-amd64.exe"
    $installer = Join-Path $PSScriptRoot "..\runner_utility_scripts\OpenTofuInstaller.ps1"
    & $installer -installMethod standalone -cosignPath $Cosign
} else {
    Write-CustomLog "InstallOpenTofu flag is disabled. Skipping OpenTofu installation."
}
}

