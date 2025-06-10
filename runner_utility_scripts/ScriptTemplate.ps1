function Invoke-LabStep {
    param([scriptblock]$Body, [pscustomobject]$Config)
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        . $PSScriptRoot/Logger.ps1
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        . $Body $Config
    } catch {
        Write-CustomLog "ERROR: $_"
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

