#. dot-source utilities
. $PSScriptRoot/Logger.ps1
. $PSScriptRoot/../Get-Platform.ps1
. $PSScriptRoot/../Network.ps1
. $PSScriptRoot/InvokeOpenTofuInstaller.ps1
. $PSScriptRoot/../Format-Config.ps1

function Get-CrossPlatformTempPath {
    <#
    .SYNOPSIS
    Returns the appropriate temporary directory path for the current platform.
    
    .DESCRIPTION
    Provides a cross-platform way to get the temporary directory, handling cases where
    $env:TEMP might not be set (e.g., on Linux/macOS).
    #>
    if ($env:TEMP) { 
        return $env:TEMP 
    } else { 
        return [System.IO.Path]::GetTempPath() 
    }
}

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
    }    $tempDir = Get-CrossPlatformTempPath
    $path = Join-Path $tempDir ("{0}_{1}{2}" -f $Prefix, [guid]::NewGuid(), $ext)
    Write-CustomLog "Downloading $Uri to $path"
    try {
        Invoke-LabWebRequest -Uri $Uri -OutFile $path -UseBasicParsing
        & $Action $path
    } finally {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-CrossPlatformCommand {
    <#
    .SYNOPSIS
    Safely invokes platform-specific cmdlets with fallback behavior
    
    .DESCRIPTION
    Checks if a cmdlet is available before invoking it, allowing scripts to be more
    cross-platform compatible. Provides mock-friendly execution for testing.
    
    .PARAMETER CommandName
    The name of the cmdlet to invoke
    
    .PARAMETER Parameters
    Hashtable of parameters to pass to the cmdlet
    
    .PARAMETER MockResult
    Result to return when the cmdlet is not available (for testing/cross-platform compatibility)
    
    .PARAMETER SkipOnUnavailable
    If true, silently skip execution when cmdlet is unavailable instead of throwing
    #>
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,
        
        [hashtable]$Parameters = @{},
        
        [object]$MockResult = $null,
        
        [switch]$SkipOnUnavailable
    )
    
    if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
        return & $CommandName @Parameters
    } elseif ($MockResult -ne $null) {
        Write-CustomLog "Command '$CommandName' not available, returning mock result" 'WARN'
        return $MockResult
    } elseif ($SkipOnUnavailable) {
        Write-CustomLog "Command '$CommandName' not available, skipping" 'WARN'
        return $null
    } else {
        throw "Command '$CommandName' is not available on this platform"
    }
}

# Import nested module for Resolve-ProjectPath
try {
    Import-Module (Join-Path $PSScriptRoot '../Resolve-ProjectPath.psm1') -Force -ErrorAction Stop
} catch {
    Write-Verbose "Failed to import Resolve-ProjectPath.psm1: $_"
}

Export-ModuleMember -Function Invoke-LabStep, Invoke-LabDownload, Write-CustomLog, Read-LoggedInput, Get-Platform, Invoke-LabWebRequest, Invoke-LabNpm, Resolve-ProjectPath, Get-CrossPlatformTempPath, Invoke-CrossPlatformCommand, Expand-All, Format-Config, Normalize-RelativePath, Get-LabConfig, Download-Archive, Get-GhDownloadArgs