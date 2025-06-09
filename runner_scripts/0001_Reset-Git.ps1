Param(
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$Config
)
. "$PSScriptRoot\..\runner_utility_scripts\Logger.ps1"

# Determine InfraPath
$InfraPath = if ($Config.InfraRepoPath) { $Config.InfraRepoPath } else { "C:\Temp\base-infra" }

# Ensure the local directory exists; create if it does not
Write-Log "Ensuring local path '$InfraPath' exists..."
if (-not (Test-Path $InfraPath)) {
    Write-Log "Path not found. Creating directory..."
    New-Item -ItemType Directory -Path $InfraPath -Force | Out-Null
}

# Clone the infrastructure repository if $InfraPath is not already a Git repo
if (-not (Test-Path (Join-Path $InfraPath '.git'))) {
    Write-Log "Directory is not a git repository. Cloning repository..."

    # Prefer GitHub CLI if present; otherwise use plain git
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCmd) {
        gh repo clone $config.InfraRepoUrl $InfraPath
    } else {
        git clone $config.InfraRepoUrl $InfraPath
    }

    # Validate that the clone succeeded
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $InfraPath '.git'))) {
        Write-Error "Failed to clone repository from $($config.InfraRepoUrl)"
        throw
    }

    Write-Log "Clone completed successfully."
}
        exit 1
    }
} else {
    Write-Log "Git repository found. Updating repository..."
    Push-Location $InfraPath
    try {
        git reset --hard
        git clean -fd
        git pull
    } catch {
        Write-Error "An error occurred while updating the repository: $_"
    } finally {
        Pop-Location
    }
}
