<#
.SYNOPSIS
Centralized management for one-off scripts in OpenTofu Lab Automation.

.DESCRIPTION
This module provides functions to register, validate, and execute one-off scripts.
It ensures scripts are integrated into the project framework without breaking dependencies.

#>

function Register-OneOffScript {
    param(
        Parameter(Mandatory=$true)
        string$ScriptPath,

        Parameter(Mandatory=$true)
        string$Purpose,

        Parameter(Mandatory=$false)
        string$Dependencies = @(),

        Parameter(Mandatory=$false)
        string$ExecutionContext = "Default",

        Parameter(Mandatory=$false)
        string$MetadataFile = (Join-Path (Get-Location) "scripts/one-off-scripts.json")
    )

    $scriptMetadata = @{
        ScriptPath = $ScriptPath
        Purpose = $Purpose
        Dependencies = $Dependencies
        ExecutionContext = $ExecutionContext
        RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    if (-not (Test-Path $MetadataFile)) {
        $allScripts = @()
    } else {
        $allScripts = Get-Content $MetadataFile  ConvertFrom-Json
    }

    $allScripts += $scriptMetadata
    $allScripts  ConvertTo-Json -Depth 10  Set-Content $MetadataFile

    Write-Host "Script registered successfully: $ScriptPath" -ForegroundColor Green
}

function Test-OneOffScript {
    param(
        Parameter(Mandatory=$true)
        string$ScriptPath
    )

    if (-not (Test-Path $ScriptPath)) {
        Write-Host "Script not found: $ScriptPath" -ForegroundColor Red
        return $false
    }

    $content = Get-Content $ScriptPath -Raw
    if ($content -notmatch "Import-Module") {
        Write-Host "Script does not import required modules: $ScriptPath" -ForegroundColor Yellow
        return $false
    }

    if ($content -match "Invoke-ParallelScriptAnalyzer") {
        Write-Host "Script uses modern function: Invoke-ParallelScriptAnalyzer" -ForegroundColor Green
        return $true
    }

    Write-Host "Script uses deprecated function: Invoke-BatchScriptAnalysis" -ForegroundColor Red
    return $false
}

function Invoke-OneOffScript {
    param(
        Parameter(Mandatory=$true)
        string$ScriptPath
    )

    if (-not (Test-OneOffScript -ScriptPath $ScriptPath)) {
        Write-Host "Script validation failed: $ScriptPath" -ForegroundColor Red
        return
    }

    try {
        Write-Host "Executing script: $ScriptPath" -ForegroundColor Cyan
        & $ScriptPath
        Write-Host "Script executed successfully: $ScriptPath" -ForegroundColor Green
    } catch {
        Write-Host "Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
