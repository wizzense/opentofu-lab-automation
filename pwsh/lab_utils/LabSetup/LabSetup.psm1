#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../Get-Platform.ps1
. $PSScriptRoot/../Network.ps1

function Invoke-LabStep {
    param(
        [scriptblock]$Body,
        [object]$Config
    )

    






if ($Config -is [string]) {
        if (Test-Path $Config) {
            $Config = Get-Content -Raw -Path $Config | ConvertFrom-Json
        } else {
            try { $Config = $Config | ConvertFrom-Json } catch {}
        }
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        & $Body $Config
    } catch {
        Write-CustomLog "ERROR: $_" 'ERROR'
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Get-Platform, Invoke-LabWebRequest, Invoke-WebRequest, Invoke-LabNpm



