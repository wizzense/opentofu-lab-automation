function Invoke-LabStep {
    param([scriptblock]$Body, [pscustomobject]$Config)
    . $PSScriptRoot/Logger.ps1

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        & $Body
    } catch {
        Write-CustomLog "ERROR: $_"
        exit 1
    } finally {
        Set-StrictMode -Off
        $ErrorActionPreference = $prevEAP
    }
}

