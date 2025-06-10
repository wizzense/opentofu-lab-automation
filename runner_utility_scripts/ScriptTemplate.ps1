function Invoke-LabStep {
    param([scriptblock]$Body, [pscustomobject]$Config)
    . $PSScriptRoot/Logger.ps1
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    try { & $Body $Config } catch { Write-CustomLog "ERROR: $_"; exit 1 }
}

