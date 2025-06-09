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

# Check if the directory is a git repository
if (-not (Test-Path (Join-Path $InfraPath ".git"))) {
    Write-Log "Directory is not a git repository. Cloning repository..."
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCmd) {
        gh repo clone $config.InfraRepoUrl $InfraPath
    } else {
        git clone $config.InfraRepoUrl $InfraPath
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone $($config.InfraRepoUrl)"
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
