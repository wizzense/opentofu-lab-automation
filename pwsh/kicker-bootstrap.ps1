<# 
.SYNOPSIS
  Kicker script for a fresh Windows Server Core setup with robust error handling.

$targetBranch = 'main'
$baseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/'1) Loads configs/config_files/default-config.json by default (override with -ConfigFile).
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

param(
    string$ConfigFile,
    switch$Quiet,
    switch$WhatIf,
    switch$NonInteractive,
    ValidateSet('silent','normal','detailed')
    string$Verbosity = 'normal'
)

# Auto-detect non-interactive mode if not explicitly set
if (-not $NonInteractive) {
    # Check if PowerShell was started with -NonInteractive
    $commandLine = Environment::GetCommandLineArgs() -join ' '
    if ($commandLine -match '-NonInteractive' -or 
        $Host.Name -eq 'Default Host' -or
        (Environment::UserInteractive -eq $false)) {
        $NonInteractive = $true
        Write-Verbose "Auto-detected non-interactive mode"
    }
}

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
        return System.IO.Path::GetTempPath()
    }
}

function Join-PathRobust {
    param(
        string$Path,
        string$ChildPaths
    )
    try {
        return Join-Path -Path $Path -ChildPath $ChildPaths -ErrorAction Stop
    } catch {
        foreach ($child in $ChildPaths) {
            $Path = Join-Path -Path $Path -ChildPath $child
        }
        return $Path
    }
}

function Get-SafeLabConfig {
    param(string$Path)
    try {
        return Get-LabConfig -Path $Path
    } catch {
        if ($_.Exception.Message -match 'positional parameter') {
            Write-CustomLog 'Falling back to PowerShell 5.1 config loader.' 'WARN'
            $content = Get-Content -Raw -LiteralPath $Path
            $cfg = $content  ConvertFrom-Json
            $labDir = Split-Path -Parent $labConfigScript
            $repoRoot = Resolve-Path (Join-PathRobust $labDir '..')
            $dirs = @{}
            if ($cfg.PSObject.Properties'Directories') {
                $cfg.Directories.PSObject.Properties  ForEach-Object { $dirs$_.Name = $_.Value }
            }
            $dirs'RepoRoot'       = $repoRoot.Path
            $dirs'RunnerScripts'  = Join-PathRobust $repoRoot.Path @('runner_scripts')
            $dirs'UtilityScripts' = Join-PathRobust $repoRoot.Path @('lab_utils','LabRunner')
            $dirs'ConfigFiles'    = Join-PathRobust $repoRoot.Path @('..','configs','config_files')
            $dirs'InfraRepo'      = if ($cfg.InfraRepoPath) { $cfg.InfraRepoPath } else { 'C:\\Temp\\base-infra' }
            Add-Member -InputObject $cfg -MemberType NoteProperty -Name Directories -Value (pscustomobject$dirs) -Force
            return $cfg
        } else {
            throw
        }
    }
}

if ($Quiet.IsPresent) { $Verbosity = 'silent' }

$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel    = $script:VerbosityLevels$Verbosity

$targetBranch = 'main'
$baseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/'
$defaultConfig = "${baseUrl}${targetBranch}/configs/config_files/default-config.json"


# example: https://raw.githubusercontent.com/wizzense/tofu-base-lab/refs/heads/main/configs/bootstrap-config.json


function Write-Continue {
    param(string$Message = "Press any key to continue...")
    
    # Skip interactive prompts in WhatIf, NonInteractive modes, or when PowerShell is in NonInteractive mode
    if ($WhatIf -or $NonInteractive -or $Quiet -or 
        (Environment::UserInteractive -eq $false) -or
        ($Host.Name -eq "ConsoleHost" -and $Host.UI.RawUI.KeyAvailable -eq $false)) {
        Write-CustomLog "Skipping interactive prompt: $Message" 'INFO'
        return
    }
    
    # Check if we're actually running in an interactive environment before using Read-Host
    if (Environment::UserInteractive -and 
        $Host.Name -ne 'Default Host' -and
        (-not ($commandLine -match '-NonInteractive'))) {
        try {
            Write-Host $Message -ForegroundColor Yellow -NoNewline
            $null = Read-Host
        } catch {
            Write-CustomLog "Interactive prompt skipped due to exception: $($_.Exception.Message)" 'INFO'
        }
    } else {
        # In non-interactive mode, just log the message
        Write-CustomLog $Message 'INFO'
    }
}

$ErrorActionPreference = 'Stop'  # So any error throws an exception
$ProgressPreference = 'SilentlyContinue'

# Resolve script root even when $PSScriptRoot is not populated (e.g. -Command)
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot    } else { Split-Path -Parent $MyInvocation.MyCommand.Path    }
$isWindowsOS = System.Environment::OSVersion.Platform -eq 'Win32NT'

# Ensure the logger utility is available even when this script is executed
# standalone. If the logger script is missing, download it from the repository.
$loggerDir  = Join-Path (Join-Path $scriptRoot 'lab_utils') 'LabRunner'
$loggerPath = Join-Path $loggerDir 'Logger.ps1'
if (-not (Test-Path $loggerPath)) {
    if (-not (Test-Path $loggerDir)) {
        New-Item -ItemType Directory -Path $loggerDir -Force  Out-Null
    }
    $loggerUrl = "${baseUrl}${targetBranch}/pwsh/modules/LabRunner/Logger.ps1"
    Invoke-WebRequest -Uri $loggerUrl -OutFile $loggerPath
}
try {
    . "$loggerPath"
} catch {
    Write-Error "Failed to load logger script: $_"
    exit 1
}

# Set default log file path if none is defined
if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue) -and
    -not (Get-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue)) {
    $logDir = $env:LAB_LOG_DIR
    if (-not $logDir) {
        if ($isWindowsOS) { $logDir = 'C:\\temp' } else { $logDir = System.IO.Path::GetTempPath() }
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force  Out-Null }
    $script:LogFilePath = Join-Path $logDir 'lab.log'
}

# Fallback inline logger in case dot-sourcing failed
if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
    function Write-CustomLog {
        param(
            string$Message,
            ValidateSet('INFO','WARN','ERROR')



 string$Level = 'INFO'
        )
        $levelIdx = @{ INFO = 1; WARN = 1; ERROR = 0 }$Level
        if (-not (Get-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue)) {
            $logDir = $env:LAB_LOG_DIR
            if (-not $logDir) { $logDir = if ($isWindowsOS) { 'C:\\temp'    } else { System.IO.Path::GetTempPath()    } }
            $script:LogFilePath = Join-Path $logDir 'lab.log'
        }
        if (-not (Get-Variable -Name ConsoleLevel -Scope Script -ErrorAction SilentlyContinue)) {
            $script:ConsoleLevel = 1
        }
        $ts  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $fmt = "$ts $Level $Message"
        fmt | Out-File -FilePath $script:LogFilePath -Encoding utf8 -Append
        if ($levelIdx -le $script:ConsoleLevel) {
            $color = @{ INFO='Gray'; WARN='Yellow'; ERROR='Red' }$Level
            Write-Host $fmt -ForegroundColor $color
        }
    }    function Read-LoggedInput {
        CmdletBinding()
        param(
            Parameter(Mandatory)string$Prompt,
            switch$AsSecureString,
            string$DefaultValue = ""
        )

        # Check if we're in non-interactive mode
        if ($WhatIf -or $NonInteractive -or 
            (Environment::UserInteractive -eq $false) -or
            ($Host.Name -eq 'Default Host') -or
            ($commandLine -match '-NonInteractive')) {
            Write-CustomLog "Non-interactive mode detected. Using default value for: $Prompt" 'INFO'
            if ($AsSecureString -and -not string::IsNullOrEmpty($DefaultValue)) {
                return ConvertTo-SecureString -String $DefaultValue -AsPlainText -Force
            }
            return $DefaultValue
        }

        try {
            if ($AsSecureString) {
                Write-CustomLog "$Prompt (secure input)"
                return Read-Host -Prompt $Prompt -AsSecureString
            }

            $answer = Read-Host -Prompt $Prompt
            Write-CustomLog "$($Prompt): $answer"
            return $answer
        }
        catch {
            Write-CustomLog "Error reading input: $($_.Exception.Message). Using default value." 'WARN'
            if ($AsSecureString -and -not string::IsNullOrEmpty($DefaultValue)) {
                return ConvertTo-SecureString -String $DefaultValue -AsPlainText -Force
            }
            return $DefaultValue
        }
    }
}

# Load config helper
$labUtilsDir = Join-Path $scriptRoot 'lab_utils'
$labConfigScript = Join-Path $labUtilsDir 'Get-LabConfig.ps1'
$formatScript    = Join-Path $labUtilsDir 'Format-Config.ps1'
if (-not (Test-Path $labConfigScript)) {
    if (-not (Test-Path $labUtilsDir)) {
        New-Item -ItemType Directory -Path $labUtilsDir -Force  Out-Null
    }
    $labConfigUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/pwsh/modules/LabRunner/Get-LabConfig.ps1'
    Invoke-WebRequest -Uri $labConfigUrl -OutFile $labConfigScript
}
if (-not (Test-Path $formatScript)) {
    if (-not (Test-Path $labUtilsDir)) {
        New-Item -ItemType Directory -Path $labUtilsDir -Force  Out-Null
    }
    $formatUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/pwsh/modules/CodeFixerFormat-Config.ps1'
    Invoke-WebRequest -Uri $formatUrl -OutFile $formatScript
}
. "$labConfigScript"
. "$formatScript"


# ------------------------------------------------
# (0) clever? message, take a second...
# ------------------------------------------------

Write-CustomLog "`nYo!"
# Only show interactive prompt if we're in interactive mode
Write-Continue "Press Enter to continue..." # Write-Continue already handles non-interactive mode checks internally
Write-CustomLog "Use `-Quiet` to reduce output."
Write-CustomLog "I know you totally read the readme first, but just in case you didn't...`n"

Write-CustomLog """

Note: In order for most of this to work you will actually have to provide a config file. 
You can either modify this command to point to the remote/local path, or leave it as is. 

You will have an opportunity after this to actually view the config file and even modify it.

At the time of this writing that feature may be broken... oh well.

The script will do the following if you proceed:

  1) Loads configs/config_files/default-config.json by default (override with -ConfigFile).
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
if ($WhatIf -or $NonInteractive -or Environment::UserInteractive -eq $false) {
    Write-CustomLog "Non-interactive mode: Using default configuration" 'INFO'
    $configOption = ""
} else {
    $configOption = Read-LoggedInput -Prompt "`nEnter a remote URL or local path, or leave blank for default." -DefaultValue ""
}

if ($configOption -match "https://") {
    Invoke-WebRequest -Uri $configOption -OutFile '.\custom-config.json'
    $ConfigFile = (Join-Path $scriptRoot "custom-config.json")
} elseif ($configOption -and (Test-Path -Path $configOption)) {
    $ConfigFile = $configOption
} else {
    $localConfigDir = Join-Path (Join-Path $scriptRoot "configs") "config_files"
    if (!(Test-Path $localConfigDir)) {
        New-Item -ItemType Directory -Path localConfigDir | Out-Null
    }
    $configFiles = Get-ChildItem -Path $localConfigDir -Filter '*.json' -File
    if ($configFiles.Count -gt 1) {
        Write-CustomLog "Multiple configuration files found:" "INFO"
        for ($i = 0; $i -lt $configFiles.Count; $i++) {
            $num = $i + 1
            Write-Host "$num) $($configFiles$i.Name)" -ForegroundColor White
        }
        
        if ($WhatIf -or $NonInteractive) {
            Write-CustomLog "Non-interactive mode: Using first configuration file" 'INFO'
            $ConfigFile = $configFiles0.FullName
        } else {            $ans = Read-LoggedInput -Prompt "Select configuration number" -DefaultValue "1"
            if ($ans -match '^0-9+$' -and int$ans -ge 1 -and int$ans -le $configFiles.Count) {
                $ConfigFile = $configFilesint$ans - 1.FullName
            } else {
                $ConfigFile = $configFiles0.FullName
            }
        }
    } elseif ($configFiles.Count -eq 1) {
        $ConfigFile = $configFiles0.FullName
    } else {
        $localConfigPath = Join-Path $localConfigDir "default-config.json"
        if (-not (Test-Path $localConfigPath)) {
            Invoke-WebRequest -Uri $defaultConfig -OutFile $localConfigPath
        }
        $ConfigFile = $localConfigPath
    }
}

# ------------------------------------------------
# (1) Load Configuration
# ------------------------------------------------
Write-CustomLog "==== Loading configuration file ===="

# Exit early if this is just a WhatIf run
if ($WhatIf) {
    Write-CustomLog "WhatIf mode: Configuration validation complete" 'INFO'
    Write-CustomLog "WhatIf mode: Would proceed with Git, GitHub CLI, and repository operations" 'INFO'
    Write-CustomLog "WhatIf mode: Exiting without making changes" 'INFO'
    exit 0
}

# Validate the config path first so users get a clear error when the file is
# missing or the path contains characters PowerShell interprets as parameters.
if (-not (Test-Path -LiteralPath $ConfigFile)) {
    Write-Error "ERROR: Configuration file not found at '$ConfigFile'. Use -ConfigFile to specify a valid path."
    exit 1
}

try {
    $resolvedConfigPath = (Resolve-Path -LiteralPath $ConfigFile).Path
    $config = Get-SafeLabConfig "$resolvedConfigPath"
    Write-CustomLog "Config file loaded from $resolvedConfigPath."
    Write-CustomLog (Format-Config -Config $config)
} catch {
    $errorPath = if ($resolvedConfigPath) { $resolvedConfigPath    } else { $ConfigFile    }
    Write-Error "ERROR: Failed to load configuration file '$errorPath' - $($_.Exception.Message)"
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
        $gitInstallerPath = Join-Path -Path (Get-CrossPlatformTempPath) -ChildPath "GitInstaller.exe"

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
# (2.5) Ensure PowerShell 7 is present
# ------------------------------------------------

$isWindowsOS = System.Environment::OSVersion.Platform -eq 'Win32NT'
if (-not $isWindowsOS) {

    Write-Error "PowerShell 7 installation via this script is only supported on Windows."
    exit 1
}

Write-CustomLog "==== Checking if PowerShell 7 is installed ===="
$pwshPath = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"

if (!(Test-Path $pwshPath)) {
    if ($Config.InstallPwsh -eq $true) {
        $pwshInstallerUrl = "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.5.1-win-x64.msi"
        $pwshInstallerPath = Join-Path -Path (Get-CrossPlatformTempPath) -ChildPath "PowerShellInstaller.msi"
        Invoke-WebRequest -Uri $pwshInstallerUrl -OutFile $pwshInstallerPath -UseBasicParsing
        Write-CustomLog "Installing PowerShell 7 silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$pwshInstallerPath`" /quiet /norestart" -Wait -Verb RunAs
        Remove-Item -Path $pwshInstallerPath -ErrorAction SilentlyContinue
        Write-CustomLog "PowerShell 7 installation completed."
    } else {
        Write-Error "PowerShell 7 is required. Set InstallPwsh=true in the config."
        exit 1
    }
}

if (!(Test-Path $pwshPath)) {
    Write-Error "ERROR: PowerShell 7 installation failed or is not accessible."
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
        $ghCliInstaller = Join-Path -Path (Get-CrossPlatformTempPath) -ChildPath "GitHubCLIInstaller.msi"
        Invoke-WebRequest -Uri $config.GitHubCLIInstallerUrl -OutFile $ghCliInstaller -UseBasicParsing

        Write-CustomLog "Installing GitHub CLI silently..."
        Start-Process msiexec.exe -ArgumentList "/i `"$ghCliInstaller`" /quiet /norestart /log `"$(Get-CrossPlatformTempPath)\ghCliInstall.log`"" -Wait -Verb RunAs
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

    if ($WhatIf -or $NonInteractive) {
        Write-CustomLog "Non-interactive mode: Skipping GitHub authentication" 'WARN'
        Write-CustomLog "Note: Repository operations may fail without authentication" 'WARN'
    } else {
    # Optional: Prompt user for a personal access token
        $pat = if ($NonInteractive -or Environment::UserInteractive -eq $false) {
            # In non-interactive mode, check for environment variable
            $env:GITHUB_PAT
        } else {
            Read-LoggedInput -Prompt "Enter your GitHub Personal Access Token (or press Enter to skip):" -DefaultValue ""
        }

        if (-not string::IsNullOrWhiteSpace($pat)) {
            Write-CustomLog "Attempting PAT-based GitHub CLI login..."
            try {
                $pat  & "$ghExePath" auth login --hostname github.com --git-protocol https --with-token
            }
            catch {
                Write-Error "ERROR: PAT-based login failed. Please verify your token or try interactive login."
                exit 1
            }
        }
        else {
            # No PAT, attempt normal interactive login in the console
            if ($NonInteractive -or Environment::UserInteractive -eq $false) {
                Write-CustomLog "No PAT provided and in non-interactive mode. Repository operations may fail." 'WARN'
            } else {
                Write-CustomLog "No PAT provided. Attempting interactive login..."
                try {
                    & "$ghExePath" auth login --hostname github.com --git-protocol https
                }
                catch {
                    Write-Error "ERROR: Interactive login failed: $($_.Exception.Message)"
                    exit 1
                }
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
}

# ------------------------------------------------
# Helper to update repo while preserving local config changes
function Update-RepoPreserveConfig {
    param(
        string$RepoPath,
        string$Branch,
        string$GitPath
    )
    



Push-Location $RepoPath
    $configChanges = & $GitPath status --porcelain "configs/config_files" 2>$null
    $backupDir = $null
    if ($configChanges -and (Test-Path 'configs/config_files')) {
        $backupDir = Join-Path $RepoPath 'config_backup'
        Write-CustomLog "Backing up local config changes to $backupDir" 'INFO'
        if (Test-Path $backupDir) { Remove-Item -Recurse -Force $backupDir }
        Copy-Item -Path 'configs/config_files' -Destination $backupDir -Recurse -Force
        & $GitPath stash push -u -- 'configs/config_files'  Out-Null
    }
    & $GitPath pull origin $Branch --quiet 2>&1 >> "$(Get-CrossPlatformTempPath)\git.log"
    if ($configChanges -and (Test-Path $backupDir)) {
        Write-CustomLog 'Restoring backed up config files' 'INFO'
        Copy-Item -Path (Join-Path $backupDir '*') -Destination 'configs/config_files' -Recurse -Force
        Remove-Item -Recurse -Force $backupDir -ErrorAction SilentlyContinue
        & $GitPath stash drop --quiet  Out-Null
    }
    Pop-Location
}

# ------------------------------------------------
# (4) Clone or Update Repository (using explicit Git/gh)
# ------------------------------------------------
Write-CustomLog "==== Cloning or updating the target repository ===="

try {
    & "$ghExePath" auth status 2>&1  Out-Null
} catch {
    Write-Error "GitHub CLI is not authenticated. Please run '$ghExePath auth login' and re-run this script."
    exit 1
}

if (-not $config.RepoUrl) {
    Write-Error "ERROR: config.json does not specify 'RepoUrl'."
    exit 1
}

# Define local path (fallback if not in config)
$localPath = $config.LocalPath

$localPath = if (-not $localPath -or string::IsNullOrWhiteSpace($localPath)) {
    if ($isWindowsOS) {
        Get-CrossPlatformTempPath
    } else {
        System.IO.Path::GetTempPath()
    }
} else {
    $localPath

}
$localPath = System.Environment::ExpandEnvironmentVariables($localPath)


# Ensure local directory exists
Write-CustomLog "Ensuring local path '$localPath' exists..."
if (!(Test-Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath -Force  Out-Null
}

# Define repo path
$repoName = ($config.RepoUrl -split '/')-1 -replace "\.git$", ""
$repoPath = Join-Path $localPath $repoName

if (-not $repoPath) {
    Write-Error "ERROR: Repository path could not be determined. Check config.json and retry."
    exit 1
}

# Configure git safe.directory to avoid dubious ownership errors
# Use GetFullPath so path need not exist yet
$resolvedRepoPath = System.IO.Path::GetFullPath($repoPath)
& "$gitPath" config --global --add safe.directory $resolvedRepoPath 2>$null

if (!(Test-Path $repoPath)) {
    Write-CustomLog "Cloning repository from $($config.RepoUrl) to $repoPath..."

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    & "$ghExePath" repo clone $config.RepoUrl $repoPath -- -q 2>&1  Tee-Object -FilePath "$(Get-CrossPlatformTempPath)\gh_clone_log.txt"
    $ghExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP

    if ($ghExit -ne 0 -or !(Test-Path $repoPath)) {
        Write-CustomLog "GitHub CLI clone failed or directory not created. Trying git clone..."
        
        # Remove existing directory if it exists and is empty/problematic
        if (Test-Path $repoPath) {
            try {
                Remove-Item -Path $repoPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-CustomLog "Removed existing problematic directory: $repoPath"
            } catch {
                Write-CustomLog "Warning: Could not remove existing directory: $repoPath"
            }
        }
        
        & "$gitPath" clone $config.RepoUrl $repoPath --quiet 2>&1  Tee-Object -FilePath "$(Get-CrossPlatformTempPath)\git_clone_log.txt"
        $gitExit = $LASTEXITCODE
        
        # Handle Windows-specific checkout failures due to invalid filenames
        if ($gitExit -ne 0 -and $isWindowsOS -and (Test-Path $repoPath)) {
            Write-CustomLog "Git clone failed, likely due to Windows filename restrictions. Attempting recovery..."
            Push-Location $repoPath
            try {
                # Restore files that can be checked out on Windows
                & "$gitPath" restore --source=HEAD :/ 2>&1  Out-Null
                Write-CustomLog "Attempted file restoration. Repository may be partially functional."
                $gitExit = 0  # Consider this a success for Windows
            } catch {
                Write-CustomLog "File restoration failed: $_"
            } finally {
                Pop-Location
            }
        }
        
        if ($gitExit -ne 0 -or !(Test-Path $repoPath)) {
            Write-Error "ERROR: Repository cloning failed. Check logs: $(Get-CrossPlatformTempPath)\gh_clone_log.txt and $(Get-CrossPlatformTempPath)\git_clone_log.txt"
            if (Test-Path "$(Get-CrossPlatformTempPath)\gh_clone_log.txt") {
                Write-Host '--- gh_clone_log.txt ---' -ForegroundColor Yellow
                Get-Content "$(Get-CrossPlatformTempPath)\gh_clone_log.txt"  Out-Host
            }
            if (Test-Path "$(Get-CrossPlatformTempPath)\git_clone_log.txt") {
                Write-Host '--- git_clone_log.txt ---' -ForegroundColor Yellow
                Get-Content "$(Get-CrossPlatformTempPath)\git_clone_log.txt"  Out-Host
            }
            exit 1
        }
    }
}
# Immediately check directory contents after clone
if ((Get-ChildItem -Path $repoPath -Recurse -ErrorAction SilentlyContinue  Measure-Object).Count -eq 0) {
    Write-Error "ERROR: Repo directory $repoPath is empty after clone. Check clone logs above."
    if (Test-Path "$(Get-CrossPlatformTempPath)\gh_clone_log.txt") {
        Write-Host '--- gh_clone_log.txt ---' -ForegroundColor Yellow
        Get-Content "$(Get-CrossPlatformTempPath)\gh_clone_log.txt"  Out-Host
    }
    if (Test-Path "$(Get-CrossPlatformTempPath)\git_clone_log.txt") {
        Write-Host '--- git_clone_log.txt ---' -ForegroundColor Yellow
        Get-Content "$(Get-CrossPlatformTempPath)\git_clone_log.txt"  Out-Host
    }
    exit 1
}

# Ensure the desired branch is checked out and up to date
Push-Location $repoPath
& "$gitPath" fetch --all --quiet 2>&1 >> "$env:TEMP\git.log"

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
    & "$gitPath" pull origin $targetBranch --quiet 2>&1 >> "$env:TEMP\git.log"
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

# Robust path resolution for runner script
if (System.IO.Path::IsPathRooted($runnerScriptName)) {
    $runnerScriptPath = $runnerScriptName
} else {
    $runnerScriptPath = Join-Path $repoPath $runnerScriptName
}

Write-Host "DEBUG ConfigFile: $ConfigFile" -ForegroundColor Cyan
Write-Host "DEBUG repoPath: $repoPath" -ForegroundColor Cyan
Write-Host "DEBUG runnerScriptName: $runnerScriptName" -ForegroundColor Cyan
Write-Host "DEBUG runnerScriptPath: $runnerScriptPath" -ForegroundColor Cyan
if ($ConsoleLevel -ge $script:VerbosityLevels'detailed') {
    Write-Host "DEBUG Directory contents of repoPath (${repoPath}):" -ForegroundColor Cyan
    Get-ChildItem -Path $repoPath -Recurse  Select-Object FullName
}

if (!(Test-Path $runnerScriptPath)) {
    Write-Error "ERROR: Could not find runner script at $runnerScriptPath. Exiting."
    Write-Host "DEBUG Directory contents of repoPath (${repoPath}):" -ForegroundColor Yellow
    Get-ChildItem -Path $repoPath -Recurse  Format-List FullName  Out-Host
    Write-Host @"
Possible causes:
- The repository clone failed or is incomplete.
- The repository does not contain $runnerScriptName at its root or subdirectory.
- The wrong branch or an empty repo was cloned.
- Config file RunnerScriptName is incorrect: $runnerScriptName

Next steps:
- Check the output above for missing files.
- Verify your config.RepoUrl is correct and points to a valid repository.
- Try deleting ${repoPath} and rerunning this script.
"@ -ForegroundColor Yellow
    exit 1
}

Write-CustomLog "Running $runnerScriptPath ..."

$scriptArguments = @('-NoLogo','-NoProfile','-File', $runnerScriptPath, '-ConfigFile', $ConfigFile, '-Verbosity', $Verbosity)
$proc = Start-Process -FilePath $pwshPath -ArgumentList $scriptArguments -Wait -NoNewWindow -PassThru
$exitCode = $proc.ExitCode

if ($exitCode -ne 0) {
    Write-CustomLog "Runner script failed with exit code $exitCode"
    exit $exitCode
}

Write-CustomLog "`n=== Kicker script finished successfully! ==="
exit 0














