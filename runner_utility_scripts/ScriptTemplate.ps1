if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

#Param([object]$Config)

# When this template is dot-sourced from within the LabRunner module itself the
# module is still in the process of loading and `Get-Module` will not return it
# yet.  Importing the manifest again would recursively nest the module and soon
# hit PowerShell's 10 level limit.  Detect this situation by inspecting the
# currently executing module before importing.
if (-not (Get-Module -Name LabRunner) -and
    ($null -eq $ExecutionContext.SessionState.Module -or
     $ExecutionContext.SessionState.Module.Name -ne 'LabRunner')) {
    Import-Module (Join-Path $PSScriptRoot '..\runner_utility_scripts\LabRunner.psd1')
}


function Invoke-LabStep {
    param([scriptblock]$Body, [object]$Config)
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

Invoke-LabStep -Config $Config -Body {
    Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"

}

