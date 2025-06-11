if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

#Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../lab_utils/LabRunner.psd1"

function Invoke-LabScript {
    param([scriptblock]$Body, [pscustomobject]$Config)
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
        . $Body $Config
    } catch {
        Write-CustomLog "ERROR: $_"
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

function Invoke-LabStep {
    param([scriptblock]$Body, [pscustomobject]$Config)
    Invoke-LabScript -Body $Body -Config $Config
}

Invoke-LabScript -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

}

