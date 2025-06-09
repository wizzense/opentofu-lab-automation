Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

<#
.SYNOPSIS
    Removes the cloned repo and infra directories.
.DESCRIPTION
    Deletes the repository directory derived from RepoUrl under LocalPath
    and the InfraRepoPath directory if they exist.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    $localBase = if ($Config.LocalPath) {
        $Config.LocalPath
    } else {
        Join-Path $env:USERPROFILE 'Documents\ServerSetup'
    }
    $localBase = [System.Environment]::ExpandEnvironmentVariables($localBase)
    $repoName  = ($Config.RepoUrl -split '/')[-1] -replace '\.git$',''
    $repoPath  = Join-Path $localBase $repoName

    if (Test-Path $repoPath) {
        Write-Log "Removing repo path '$repoPath'..."
        Remove-Item -Recurse -Force -Path $repoPath
    } else {
        Write-Log "Repo path '$repoPath' not found; skipping."
    }

    $infraPath = if ($Config.InfraRepoPath) { $Config.InfraRepoPath } else { 'C:\\Temp\\base-infra' }
    if (Test-Path $infraPath) {
        Write-Log "Removing infra path '$infraPath'..."
        Remove-Item -Recurse -Force -Path $infraPath
    } else {
        Write-Log "Infra path '$infraPath' not found; skipping."
    }

    Write-Log 'Cleanup completed successfully.'
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}

