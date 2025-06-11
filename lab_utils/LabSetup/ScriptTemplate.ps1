if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

#Param([pscustomobject]$Config)

function Invoke-LabStep {
    param([scriptblock]$Body, [pscustomobject]$Config)
    if ($Config -is [string]) {
        if (Test-Path $Config) {
            $Config = Get-Content -Raw -Path $Config | ConvertFrom-Json
        } else {
            try { $Config = $Config | ConvertFrom-Json } catch {}
        }
    }
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        . (Join-Path $PSScriptRoot '..' '..' 'runner_utility_scripts' 'Logger.ps1')
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

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

}

