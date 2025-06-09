<# 
.SYNOPSIS
  Kicker script for a fresh Windows Server Core setup with robust error handling.

  1) Loads config_files/default-config.json by default (override with -ConfigFile).
  2) Checks if command-line Git is installed and in PATH.
     - Installs a minimal version if missing.
     - Updates PATH if installed but not found in PATH.
  3) Checks if GitHub CLI is installed and in PATH.
     - Installs GitHub CLI if missing.
     - Updates PATH if installed but not found in PATH.
     - Prompts for authentication if not already authenticated.
  4) Clones a repository from config.json -> RepoUrl to config.json -> LocalPath (or a default path).
  5) Invokes runner.ps1 from that repo.
#>

$targetBranch = 'main'
$defaultConfig = "https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/main/config_files/default-config.json"

# example: https://raw.githubusercontent.com/wizzense/tofu-base-lab/refs/heads/main/configs/bootstrap-config.json


$prompt = "`n<press any key to continue>`n"


function Write-Continue($prompt) {
  Write-Host "$prompt  " -NoNewline
  Microsoft.PowerShell.Utility\Read-Host }

$ErrorActionPreference = 'Stop'  # So any error throws an exception
$ProgressPreference = 'SilentlyContinue'

# Ensure the logger utility is available even when this script is executed
# standalone. If the logger script is missing, download it from the repository.
$loggerDir = Join-Path $PSScriptRoot 'runner_utility_scripts'
$loggerPath = Join-Path $loggerDir 'Logger.ps1'
if (-not (Test-Path $loggerPath)) {
    if (-not (Test-Path $loggerDir)) {
        New-Item -ItemType Directory -Path $loggerDir -Force | Out-Null
    }
    $loggerUrl =
        'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/runner_utility_scripts/Logger.ps1'
    Invoke-WebRequest -Uri $loggerUrl -OutFile $loggerPath
}
. $loggerPath

# Load config helper
$labUtilsDir = Join-Path $PSScriptRoot 'lab_utils'
$labConfigScript = Join-Path $labUtilsDir 'Get-LabConfig.ps1'
if (-not (Test-Path $labConfigScript)) {
    if (-not (Test-Path $labUtilsDir)) {
        New-Item -ItemType Directory -Path $labUtilsDir -Force | Out-Null
    }
    $labConfigUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/lab_utils/Get-LabConfig.ps1'
    Invoke-WebRequest -Uri $labConfigUrl -OutFile $labConfigScript
}
. $labConfigScript


# ------------------------------------------------
# (0) clever? message, take a second...
# ------------------------------------------------

Write-Log "`nYo!"
Write-Continue "`n<press any key to continue>`n"
Write-Log "I know you totally read the readme first, but just in case you didn't...`n"

Write-Log """

Note: In order for most of this to work you will actually have to provide a config file. 
You can either modify this command to point to the remote/local path, or leave it as is. 

You will have an opportunity after this to actually view the config file and even modify it.

At the time of this writing that feature may be broken... oh well.

The script will do the following if you proceed:

  1) Loads config_files/default-config.json by default (override with -ConfigFile).
  2) Checks if command-line Git is installed and in PATH.
     - Installs a minimal version if missing.
     - Updates PATH if installed but not found in PATH.
  3) Checks if GitHub CLI is installed and in PATH.
     - Installs GitHub CLI if missing.
     - Updates PATH if installed but not found in PATH.
     - Prompts for authentication if not already authenticated.
  4) Clones a repository from config.json -> RepoUrl to config.json -> LocalPath (or a default path).
  5) Invokes runner.ps1 from that repo.

"""

# Prompt for input to provide remote/local or accept default

$configOption = Read-Host -prompt "`nEnter a remote URL or local path, or leave blank for default."

if ($configOption -ccontains "https://") {
    Invoke-WebRequest -Uri $configOption -OutFile '.\custom-config.json'
    $ConfigFile = (Join-Path $PSScriptRoot "custom-config.json")
}
elseif ($configOption -and (Test-Path -Path $configOption)) {
    $ConfigFile = $configOption
}
else {
    $localConfigDir = Join-Path $PSScriptRoot "config_files"
    if (!(Test-Path $localConfigDir)) {
        New-Item -ItemType Directory -Path $localConfigDir | Out-Null
    }
    $localConfigPath = Join-Path $localConfigDir "default-config.json"
    Invoke-WebRequest -Uri $defaultConfig -OutFile $localConfigPath
    $ConfigFile = $localConfigPath
}

# ------------------------------------------------
# (1) Load Configuration
# ------------------------------------------------
Write-Log "==== Loading configuration file ===="
try {
    $config = Get-LabConfig -Path $ConfigFile
    Write-Log "Config file loaded from $ConfigFile."
} catch {
    Write-Error "ERROR: $($_.Exception.Message)"
    exit 1
}

# ------------------------------------------------
# (2) Check & Install Git for Windows
# ------------------------------------------------


Write-Log "==== Checking if Git is installed ===="
$gitPath = "C:\Program Files\Git\cmd\git.exe"

if (Test-Path $gitPath) {
    Write-Log "Git is already installed at: $gitPath"
} else {

    if ($Config.InstallGit -eq $true) {
        Write-Log "Git is not installed. Downloading and installing Git for Windows..."

        $gitInstallerUrl = "https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe"
        $gitInstallerPath = Join-Path -Path $env:TEMP -ChildPath "GitInstaller.exe"

        Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitInstallerPath -UseBasicParsing
        Write-Log "Installing Git silently..."
        Start-Process -FilePath $gitInstallerPath -ArgumentList "/SILENT" -Wait -NoNewWindow

        Remove-Item -Path $gitInstallerPath -ErrorAction SilentlyContinue
        Write-Log "Git installation completed."
    }
}

# Double-check Git
try {
    $gitVersion = & "$gitPath" --version
    Write-Log $gitVersion
    Write-Log "Git is installed and working."
} catch {
    Write-Error "ERROR: Git installation failed or is not accessible. Exiting."
    exit 1
}

# ------------------------------------------------
# (3) Check GitHub CLI and call by explicit path
# ------------------------------------------------
Write-Log "==== Checking if GitHub CLI is installed ===="
$ghExePath = "C:\Program Files\GitHub CLI\gh.exe"

if (!(Test-Path $ghExePath)) {
    if ($Config.InstallGitHubCLI -eq $true) {
        Write-Log "GitHub CLI not found. Downloading from $($config.GitHubCLIInstallerUrl)..."
        $ghCliInstaller = Join-Path -Path $env:TEMP -ChildPath "GitHubCLIInstaller.msi"
        Invoke-WebRequest -Uri $config.GitHubCLIInstallerUrl -OutFile $ghCliInstaller -UseBasicParsing

        Write-Log "Installing GitHub CLI silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$ghCliInstaller`" /quiet /norestart /log `"$env:TEMP\ghCliInstall.log`"" -Wait -Verb RunAs
        Remove-Item -Path $ghCliInstaller -ErrorAction SilentlyContinue

        Write-Log "GitHub CLI installation completed."
    }

} else {
    Write-Log "GitHub CLI found at '$ghExePath'."
}

if (!(Test-Path $ghExePath)) {
    Write-Error "ERROR: gh.exe not found at '$ghExePath'. Installation may have failed."
    exit 1
}

# ------------------------------------------------
# (3.5) Check & Prompt for GitHub CLI Authentication
# ------------------------------------------------
Write-Log "==== Checking GitHub CLI Authentication ===="
try {
    # If not authenticated, 'gh auth status' returns non-zero exit code
    & "$ghExePath" auth status 2>&1
    Write-Log "GitHub CLI is authenticated."
}
catch {
    Write-Log "GitHub CLI is not authenticated."

    # Optional: Prompt user for a personal access token
    $pat = Read-Host "Enter your GitHub Personal Access Token (or press Enter to skip):"

    if (-not [string]::IsNullOrWhiteSpace($pat)) {
        Write-Log "Attempting PAT-based GitHub CLI login..."
        try {
            $pat | & "$ghExePath" auth login --hostname github.com --git-protocol https --with-token
        }
        catch {
            Write-Error "ERROR: PAT-based login failed. Please verify your token or try interactive login."
            exit 1
        }
    }
    else {
        # No PAT, attempt normal interactive login in the console
        Write-Log "No PAT provided. Attempting interactive login..."
        try {
            & "$ghExePath" auth login --hostname github.com --git-protocol https
        }
        catch {
            Write-Error "ERROR: Interactive login failed: $($_.Exception.Message)"
            exit 1
        }
    }

    # After the login attempt, re-check auth
    try {
        & "$ghExePath" auth status 2>&1
        Write-Log "GitHub CLI is now authenticated."
    }
    catch {
        Write-Error "ERROR: GitHub authentication failed. Please run '$ghExePath auth login' manually and re-run."
        exit 1
    }
}

# ------------------------------------------------
# (4) Clone or Update Repository (using explicit Git/gh)
# ------------------------------------------------
Write-Log "==== Cloning or updating the target repository ===="

if (-not $config.RepoUrl) {
    Write-Error "ERROR: config.json does not specify 'RepoUrl'."
    exit 1
}

# Define local path (fallback if not in config)
$localPath = $config.LocalPath
if (-not $localPath -or [string]::IsNullOrWhiteSpace($localPath)) {
    $localPath = Join-Path $env:USERPROFILE 'Documents\ServerSetup'
}
$localPath = [System.Environment]::ExpandEnvironmentVariables($localPath)


# Ensure local directory exists
Write-Log "Ensuring local path '$localPath' exists..."
if (!(Test-Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath -Force | Out-Null
}

# Define repo path
$repoName = ($config.RepoUrl -split '/')[-1] -replace "\.git$", ""
$repoPath = Join-Path $localPath $repoName

if (-not $repoPath) {
    Write-Error "ERROR: Repository path could not be determined. Check config.json and retry."
    exit 1
}

if (!(Test-Path $repoPath)) {
    Write-Log "Cloning repository from $($config.RepoUrl) to $repoPath..."

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    & "$ghExePath" repo clone $config.RepoUrl $repoPath 2>&1 | Tee-Object -FilePath "$env:TEMP\gh_clone_log.txt"

    $ErrorActionPreference = $prevEAP

    # Fallback to git if the GitHub CLI clone appears to have failed
    if (!(Test-Path $repoPath)) {
        Write-Log "GitHub CLI clone failed. Trying git clone..."
        & "$gitPath" clone $config.RepoUrl $repoPath 2>&1 | Tee-Object -FilePath "$env:TEMP\git_clone_log.txt"

        if (!(Test-Path $repoPath)) {
            Write-Error "ERROR: Repository cloning failed. Check logs: $env:TEMP\gh_clone_log.txt and $env:TEMP\git_clone_log.txt"
            exit 1
        }
    }
} else {
    Write-Log "Repository already exists. Pulling latest changes..."
    Push-Location $repoPath
    & "$gitPath" pull origin $targetBranch
    Pop-Location
}

# Ensure the desired branch is checked out and up to date
Push-Location $repoPath
& "$gitPath" fetch --all
# Checkout the target branch without failing if we are already on it
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$checkoutOutput = & "$gitPath" checkout $targetBranch 2>&1
$checkoutCode = $LASTEXITCODE
$ErrorActionPreference = $prevEAP

if ($checkoutCode -ne 0) {
    Write-Warning "Branch '$targetBranch' not found. Using current branch."
} else {
    # Suppress noisy output like 'Already on ...' but still ensure the branch is up to date
    & "$gitPath" pull origin $targetBranch | Out-Null
}
Pop-Location

# ------------------------------------------------
# (5) Invoke the Runner Script
# ------------------------------------------------
Write-Log "==== Invoking the runner script ===="
$runnerScriptName = $config.RunnerScriptName
if (-not $runnerScriptName) {
    Write-Warning "No runner script specified in config. Exiting gracefully."
    exit 0
}

Set-Location $repoPath
if (!(Test-Path $runnerScriptName)) {
    Write-Error "ERROR: Could not find $runnerScriptName in $repoPath. Exiting."
    exit 1
}

Write-Log "Running $runnerScriptName from $repoPath ..."
. .\$runnerScriptName -ConfigFile $ConfigFile

Write-Log "`n=== Kicker script finished successfully! ==="
exit 0
