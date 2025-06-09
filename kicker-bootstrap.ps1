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
  [Console]::Write($prompt + '  ')
  Microsoft.PowerShell.Utility\Read-Host }

$ErrorActionPreference = 'Stop'  # So any error throws an exception
$ProgressPreference = 'SilentlyContinue'

# Resolve script root even when $PSScriptRoot is not populated (e.g. -Command)
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# Ensure the logger utility is available even when this script is executed
# standalone. If the logger script is missing, download it from the repository.
$loggerDir  = Join-Path $scriptRoot 'runner_utility_scripts'
$loggerPath = Join-Path $loggerDir  'Logger.ps1'
if (-not (Test-Path $loggerPath)) {
    if (-not (Test-Path $loggerDir)) {
        New-Item -ItemType Directory -Path $loggerDir -Force | Out-Null
    }
    $loggerUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/runner_utility_scripts/Logger.ps1'
    Invoke-WebRequest -Uri $loggerUrl -OutFile $loggerPath
}
try {
    . $loggerPath
} catch {
    Write-Error "Failed to load logger script: $_"
    exit 1
}

# Set default log file path if none is defined
if (-not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {
    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($IsWindows) { $logDir = 'C:\\temp' } else { $logDir = [System.IO.Path]::GetTempPath() }
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $global:LogFilePath = Join-Path $logDir 'lab.log'
}

# Fallback inline logger in case dot-sourcing failed
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param(
            [string]$Message,
            [string]$LogFile
        )
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $fmt = "[$ts] $Message"
        Write-Output $fmt
        if ($LogFile) {
            try {
                $fmt | Out-File -FilePath $LogFile -Encoding utf8 -Append
            } catch {
                Write-Error "Failed to write log to file: $_"
            }
        }
    }
}

# Load config helper
$labUtilsDir = Join-Path $scriptRoot 'lab_utils'
$labConfigScript = Join-Path $labUtilsDir 'Get-LabConfig.ps1'
$formatScript    = Join-Path $labUtilsDir 'Format-Config.ps1'
if (-not (Test-Path $labConfigScript)) {
    if (-not (Test-Path $labUtilsDir)) {
        New-Item -ItemType Directory -Path $labUtilsDir -Force | Out-Null
    }
    $labConfigUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/lab_utils/Get-LabConfig.ps1'
    Invoke-WebRequest -Uri $labConfigUrl -OutFile $labConfigScript
}
if (-not (Test-Path $formatScript)) {
    if (-not (Test-Path $labUtilsDir)) {
        New-Item -ItemType Directory -Path $labUtilsDir -Force | Out-Null
    }
    $formatUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/lab_utils/Format-Config.ps1'
    Invoke-WebRequest -Uri $formatUrl -OutFile $formatScript
}
. $labConfigScript
. $formatScript


# ------------------------------------------------
# (0) clever? message, take a second...
# ------------------------------------------------

Write-CustomLog "`nYo!"
Write-Continue "`n<press any key to continue>`n"
Write-CustomLog "I know you totally read the readme first, but just in case you didn't...`n"

Write-CustomLog """

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
    $ConfigFile = (Join-Path $scriptRoot "custom-config.json")
}
elseif ($configOption -and (Test-Path -Path $configOption)) {
    $ConfigFile = $configOption
}
else {
    $localConfigDir = Join-Path $scriptRoot "config_files"
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
Write-CustomLog "==== Loading configuration file ===="
try {
    $config = Get-LabConfig -Path $ConfigFile
    Write-CustomLog "Config file loaded from $ConfigFile."
    Write-CustomLog (Format-Config -Config $config)
} catch {
    Write-Error "ERROR: Failed to load configuration file - $($_.Exception.Message)"
    exit 1
}

# ------------------------------------------------
# (2) Check & Install Git for Windows
# ------------------------------------------------


Write-CustomLog "==== Checking if Git is installed ===="
$gitPath = "C:\Program Files\Git\cmd\git.exe"

if (Test-Path $gitPath) {
    Write-CustomLog "Git is already installed at: $gitPath"
} else {

    if ($Config.InstallGit -eq $true) {
        Write-CustomLog "Git is not installed. Downloading and installing Git for Windows..."

        $gitInstallerUrl = "https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe"
        $gitInstallerPath = Join-Path -Path $env:TEMP -ChildPath "GitInstaller.exe"

        Invoke-WebRequest -Uri $gitInstallerUrl -OutFile $gitInstallerPath -UseBasicParsing
        Write-CustomLog "Installing Git silently..."
        Start-Process -FilePath $gitInstallerPath -ArgumentList "/SILENT" -Wait -NoNewWindow

        Remove-Item -Path $gitInstallerPath -ErrorAction SilentlyContinue
        Write-CustomLog "Git installation completed."
    }
}

# Double-check Git
try {
    $gitVersion = & "$gitPath" --version
    Write-CustomLog $gitVersion
    Write-CustomLog "Git is installed and working."
} catch {
    Write-Error "ERROR: Git installation failed or is not accessible. Exiting."
    exit 1
}

# ------------------------------------------------
# (3) Check GitHub CLI and call by explicit path
# ------------------------------------------------
Write-CustomLog "==== Checking if GitHub CLI is installed ===="
$ghExePath = "C:\Program Files\GitHub CLI\gh.exe"

if (!(Test-Path $ghExePath)) {
    if ($Config.InstallGitHubCLI -eq $true) {
        Write-CustomLog "GitHub CLI not found. Downloading from $($config.GitHubCLIInstallerUrl)..."
        $ghCliInstaller = Join-Path -Path $env:TEMP -ChildPath "GitHubCLIInstaller.msi"
        Invoke-WebRequest -Uri $config.GitHubCLIInstallerUrl -OutFile $ghCliInstaller -UseBasicParsing

        Write-CustomLog "Installing GitHub CLI silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$ghCliInstaller`" /quiet /norestart /log `"$env:TEMP\ghCliInstall.log`"" -Wait -Verb RunAs
        Remove-Item -Path $ghCliInstaller -ErrorAction SilentlyContinue

        Write-CustomLog "GitHub CLI installation completed."
    }

} else {
    Write-CustomLog "GitHub CLI found at '$ghExePath'."
}

if (!(Test-Path $ghExePath)) {
    Write-Error "ERROR: gh.exe not found at '$ghExePath'. Installation may have failed."
    exit 1
}

# ------------------------------------------------
# (3.5) Check & Prompt for GitHub CLI Authentication
# ------------------------------------------------
Write-CustomLog "==== Checking GitHub CLI Authentication ===="
try {
    # If not authenticated, 'gh auth status' returns non-zero exit code
    & "$ghExePath" auth status 2>&1
    Write-CustomLog "GitHub CLI is authenticated."
}
catch {
    Write-CustomLog "GitHub CLI is not authenticated."

    # Optional: Prompt user for a personal access token
    $pat = Read-Host "Enter your GitHub Personal Access Token (or press Enter to skip):"

    if (-not [string]::IsNullOrWhiteSpace($pat)) {
        Write-CustomLog "Attempting PAT-based GitHub CLI login..."
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
        Write-CustomLog "No PAT provided. Attempting interactive login..."
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
        Write-CustomLog "GitHub CLI is now authenticated."
    }
    catch {
        Write-Error "ERROR: GitHub authentication failed. Please run '$ghExePath auth login' manually and re-run."
        exit 1
    }
}

# ------------------------------------------------
# (4) Clone or Update Repository (using explicit Git/gh)
# ------------------------------------------------
Write-CustomLog "==== Cloning or updating the target repository ===="

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
Write-CustomLog "Ensuring local path '$localPath' exists..."
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
    Write-CustomLog "Cloning repository from $($config.RepoUrl) to $repoPath..."

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    & "$ghExePath" repo clone $config.RepoUrl $repoPath 2>&1 | Tee-Object -FilePath "$env:TEMP\gh_clone_log.txt"

    $ErrorActionPreference = $prevEAP

    # Fallback to git if the GitHub CLI clone appears to have failed
    if (!(Test-Path $repoPath)) {
        Write-CustomLog "GitHub CLI clone failed. Trying git clone..."
        & "$gitPath" clone $config.RepoUrl $repoPath 2>&1 | Tee-Object -FilePath "$env:TEMP\git_clone_log.txt"

        if (!(Test-Path $repoPath)) {
            Write-Error "ERROR: Repository cloning failed. Check logs: $env:TEMP\gh_clone_log.txt and $env:TEMP\git_clone_log.txt"
            exit 1
        }
    }
} else {
    Write-CustomLog "Repository already exists. Pulling latest changes..."
    Push-Location $repoPath
    & "$gitPath" pull origin $targetBranch
    Pop-Location
}

# Ensure the desired branch is checked out and up to date
Push-Location $repoPath
& "$gitPath" fetch --all | Out-Null

# Avoid noisy checkout messages when already on the target branch
$currentBranch = (& "$gitPath" rev-parse --abbrev-ref HEAD).Trim()
$checkoutCode = 0
if ($currentBranch -ne $targetBranch) {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $null = & "$gitPath" checkout $targetBranch 2>&1
    $checkoutCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
}

if ($checkoutCode -ne 0) {
    Write-Warning "Branch '$targetBranch' not found. Using current branch."
} else {
    & "$gitPath" pull origin $targetBranch | Out-Null
}
Pop-Location

# ------------------------------------------------
# (5) Invoke the Runner Script
# ------------------------------------------------
Write-CustomLog "==== Invoking the runner script ===="
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

Write-CustomLog "Running $runnerScriptName from $repoPath ..."
. .\$runnerScriptName -ConfigFile $ConfigFile

Write-CustomLog "`n=== Kicker script finished successfully! ==="
exit 0
