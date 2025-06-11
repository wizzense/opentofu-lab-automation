# Dot-source Logger and Get-Platform utilities
. $PSScriptRoot/../../runner_utility_scripts/Logger.ps1
. $PSScriptRoot/../Get-Platform.ps1

function Invoke-LabScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Config,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        . $PSScriptRoot/../../runner_utility_scripts/Logger.ps1
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Write-CustomLog "Running $($MyInvocation.MyCommand.Name)"
        & $ScriptBlock $Config
    } catch {
        Write-CustomLog "ERROR: $($_)" 'ERROR'
        throw
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

Export-ModuleMember -Function Invoke-LabScript, Write-CustomLog, Get-Platform
