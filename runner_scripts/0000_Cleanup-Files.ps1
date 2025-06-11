Param([pscustomobject]$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psd1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0000_Cleanup-Files.ps1'

<#
.SYNOPSIS
    Removes the cloned repo and infra directories.
.DESCRIPTION
    Deletes the repository directory derived from RepoUrl under LocalPath
    and the InfraRepoPath directory if they exist.
#>


Push-Location -Path ([System.IO.Path]::GetTempPath())

try {
    $localBase = if ($Config.LocalPath) {
        $Config.LocalPath
    } else {
        if ($IsWindows) {
            if ($env:TEMP) { $env:TEMP } else { 'C:\\temp' }
        } else {
            [System.IO.Path]::GetTempPath()
        }

    }
    $localBase = [System.Environment]::ExpandEnvironmentVariables($localBase)
    $repoName  = ($Config.RepoUrl -split '/')[-1] -replace '\.git$',''
    $repoPath  = Join-Path $localBase $repoName

    if (Test-Path $repoPath) {
        Write-CustomLog "Removing repo path '$repoPath'..."
        Remove-Item -Recurse -Force -Path $repoPath
    } else {
        Write-CustomLog "Repo path '$repoPath' not found; skipping."
    }

    $infraPath = if ($Config.InfraRepoPath) { $Config.InfraRepoPath } else { 'C:\\Temp\\base-infra' }
    if (Test-Path $infraPath) {
        Write-CustomLog "Removing infra path '$infraPath'..."
        Remove-Item -Recurse -Force -Path $infraPath
    } else {
        Write-CustomLog "Infra path '$infraPath' not found; skipping."
    }

    Write-CustomLog 'Cleanup completed successfully.'
}
catch {
    Write-Error -Message "Cleanup failed: $($PSItem.Exception.Message)`n$($PSItem.ScriptStackTrace)"
    exit 1
}
finally {
    try {
        Pop-Location -ErrorAction Stop
    } catch {
        Set-Location $env:TEMP
    }
}
}
