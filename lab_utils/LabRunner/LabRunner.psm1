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

    $suppress = $false
    if ($env:LAB_CONSOLE_LEVEL -eq '0') {
        $suppress = $true
    } elseif ($PSCommandPath -and (Split-Path $PSCommandPath -Leaf) -eq 'dummy.ps1') {
        $suppress = $true
    }

    $prevConsole = $null
    if ($suppress) {
        if (Get-Variable -Name ConsoleLevel -Scope Script -ErrorAction SilentlyContinue) {
            $prevConsole = $script:ConsoleLevel
        }
        $script:ConsoleLevel = -1
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        & $Body $Config
    } catch {
        if (-not $suppress) { Write-CustomLog "ERROR: $_" 'ERROR' }
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
        if ($suppress -and $null -ne $prevConsole) { $script:ConsoleLevel = $prevConsole }
    }
}

Export-ModuleMember -Function Invoke-LabStep, Write-CustomLog, Read-LoggedInput, Get-Platform, Invoke-LabWebRequest, Invoke-LabNpm
