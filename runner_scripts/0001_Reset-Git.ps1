Param([pscustomobject]$Config)
. "$PSScriptRoot/../runner_utility_scripts/ScriptTemplate.ps1"
Invoke-LabStep -Config $Config -Body {
    Write-CustomLog 'Running 0001_Reset-Git.ps1'

# Determine InfraPath
$InfraPath = if ($Config.InfraRepoPath) { $Config.InfraRepoPath } else { "C:\Temp\base-infra" }

# Ensure the local directory exists; create if it does not
Write-CustomLog "Ensuring local path '$InfraPath' exists..."
if (-not (Test-Path $InfraPath)) {
    Write-CustomLog "Path not found. Creating directory..."
    New-Item -ItemType Directory -Path $InfraPath -Force | Out-Null
}


# Check if the directory is a git repository
# Clone the infrastructure repository if $InfraPath is not already a Git repo
if (-not (Test-Path (Join-Path $InfraPath '.git'))) {
    Write-CustomLog "Directory is not a git repository. Cloning repository..."

    # Prefer GitHub CLI if present; otherwise use plain git
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        # Ensure the GitHub CLI is authenticated to avoid Git credential prompts
        gh auth status 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "GitHub CLI is not authenticated. Please run 'gh auth login' and re-run this script."
            exit 1
        }
        gh repo clone $config.InfraRepoUrl $InfraPath
    } else {
        git clone $config.InfraRepoUrl $InfraPath
    }

    # Validate that the clone succeeded
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $InfraPath '.git'))) {
        Write-Error "Failed to clone repository from $($config.InfraRepoUrl)"
        throw
    }

    Write-CustomLog "Clone completed successfully."
}

else {
    Write-CustomLog "Git repository found. Updating repository..."
    Push-Location $InfraPath
    try {
        Write-CustomLog 'git reset --hard'
        git reset --hard
        Write-CustomLog 'git clean -fd'
        git clean -fd
        Write-CustomLog 'git pull'
        git pull
    } catch {
        Write-Error "An error occurred while updating the repository: $_"
    } finally {
        Pop-Location
    }
}
}
