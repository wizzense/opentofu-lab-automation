#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../lab_utils/Get-Platform.ps1

function Invoke-LabScript {
    param(
        [scriptblock]$Body,
        [pscustomobject]$Config
    )

    if ($Config -is [string]) {
        if (Test-Path $Config) {
            $Config = Get-Content -Raw -Path $Config | ConvertFrom-Json
        } else {
            try { $Config = $Config | ConvertFrom-Json } catch {}
        }
    }

    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        . $PSScriptRoot/Logger.ps1
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        & $Body $Config
    } catch {
        Write-CustomLog "ERROR: $_"
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

Set-Alias Invoke-LabStep Invoke-LabScript

Export-ModuleMember -Function Invoke-LabScript, Write-CustomLog, Get-Platform
Export-ModuleMember -Alias Invoke-LabStep
