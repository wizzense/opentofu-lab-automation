Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    if (-not (Get-Command Get-Platform -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/../lab_utils/Get-Platform.ps1"
    }
    Write-CustomLog 'Running 9999_Reset-Machine.ps1'
    $platform = Get-Platform
    Write-CustomLog "Detected platform: $platform"
    if ($platform -in @('Windows','Linux','MacOS')) {
        Write-CustomLog 'Initiating system reboot...'
        Restart-Computer
    } else {
        Write-CustomLog 'Unknown platform; cannot reset.'
        exit 1
    }
}
