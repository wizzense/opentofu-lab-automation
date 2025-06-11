#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../Get-Platform.ps1
. $PSScriptRoot/../Network.ps1
. $PSScriptRoot/InvokeOpenTofuInstaller.ps1

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

function Invoke-LabDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][scriptblock]$Action,
        [string]$Prefix = 'download',
        [string]$Extension
    )

    $ext = if ($Extension) {
        if ($Extension.StartsWith('.')) { $Extension } else { ".$Extension" }
    } else {
        try { [System.IO.Path]::GetExtension($Uri).Split('?')[0] } catch { '' }
    }

    $path = Join-Path $env:TEMP ("{0}_{1}{2}" -f $Prefix, [guid]::NewGuid(), $ext)
    Write-CustomLog "Downloading $Uri to $path"
    try {
        Invoke-LabWebRequest -Uri $Uri -OutFile $path -UseBasicParsing
        & $Action $path
    } finally {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Invoke-LabStep, Invoke-LabDownload, Write-CustomLog, Read-LoggedInput, Get-Platform, Invoke-LabWebRequest, Invoke-LabNpm