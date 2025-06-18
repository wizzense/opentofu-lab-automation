#Requires -Version 7.0

<#
.SYNOPSIS
    Main bootstrap script for OpenTofu Lab Automation
    
.DESCRIPTION
    This script sets up the environment, downloads dependencies, and runs the core automation.
    It replaces the corrupted kicker-bootstrap.ps1 with a clean, working implementation.
    
.PARAMETER ConfigFile
    Path to configuration file (defaults to core-runner/core_app/default-config.json)
    
.PARAMETER Quiet
    Run in quiet mode
    
.PARAMETER WhatIf
    Show what would be done without doing it
    
.PARAMETER NonInteractive
    Run without user prompts
    
.PARAMETER Verbosity
    Verbosity level: silent, normal, detailed
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigFile,
    [switch]$Quiet,
    [switch]$NonInteractive,
    [ValidateSet('silent','normal','detailed')]
    [string]$Verbosity = 'normal'
)

# Configuration
$ErrorActionPreference = 'Stop'
$targetBranch = 'main'
$baseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/'

# Set up logging levels
$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel = $script:VerbosityLevels[$Verbosity]
if ($Quiet.IsPresent) { $script:ConsoleLevel = 0 }

# Auto-detect non-interactive mode if not explicitly set
if (-not $NonInteractive) {
    $commandLine = [Environment]::GetCommandLineArgs() -join ' '
    if ($commandLine -match '-NonInteractive' -or 
        $Host.Name -eq 'Default Host' -or
        ([Environment]::UserInteractive -eq $false)) {
        $NonInteractive = $true
        Write-Verbose "Auto-detected non-interactive mode"
    }
}

function Write-CustomLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    
    $levelValue = @{ INFO = 1; WARN = 1; ERROR = 0; SUCCESS = 1; DEBUG = 2 }[$Level]
    if ($levelValue -le $script:ConsoleLevel) {
        $color = @{ INFO = 'White'; WARN = 'Yellow'; ERROR = 'Red'; SUCCESS = 'Green'; DEBUG = 'Gray' }[$Level]
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    }
}

function Get-CrossPlatformTempPath {
    if ($env:TEMP) {
        return $env:TEMP
    } else {
        return [System.IO.Path]::GetTempPath()
    }
}

function Join-PathRobust {
    param(
        [string]$Path,
        [string[]]$ChildPath
    )
    
    $result = $Path
    foreach ($child in $ChildPath) {
        $result = Join-Path $result $child
    }
    return $result
}

function Test-GitInstalled {
    try {
        $null = & git --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Install-GitIfNeeded {
    if (Test-GitInstalled) {
        Write-CustomLog "Git is already installed" "SUCCESS"
        return
    }
    
    Write-CustomLog "Git not found. Installing minimal Git..." "WARN"
    
    if ($NonInteractive) {
        Write-CustomLog "Non-interactive mode: Cannot install Git automatically" "ERROR"
        throw "Git is required but not installed"
    }
    
    # Download and install minimal Git
    $tempPath = Get-CrossPlatformTempPath
    $gitInstaller = Join-Path $tempPath "MinGit.zip"
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/MinGit-2.42.0.2-64-bit.zip"
    
    try {
        Write-CustomLog "Downloading MinGit..." "INFO"
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        $gitPath = Join-Path $env:ProgramFiles "MinGit"
        if (-not (Test-Path $gitPath)) {
            New-Item -ItemType Directory -Path $gitPath -Force | Out-Null
        }
        
        Write-CustomLog "Extracting Git to $gitPath..." "INFO"
        Expand-Archive -Path $gitInstaller -DestinationPath $gitPath -Force
        
        # Add to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$gitPath*") {
            $newPath = "$currentPath;$gitPath\cmd"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            $env:PATH = "$env:PATH;$gitPath\cmd"
        }
        
        Write-CustomLog "Git installed successfully" "SUCCESS"
        
    } catch {
        Write-CustomLog "Failed to install Git: $($_.Exception.Message)" "ERROR"
        throw
    } finally {
        if (Test-Path $gitInstaller) {
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-DefaultConfigPath {
    param([string]$RepoPath)
    
    # Try different possible locations for the config file
    $possiblePaths = @(
        (Join-Path $RepoPath "core-runner\core_app\default-config.json"),
        (Join-Path $RepoPath "configs\default-config.json"),
        (Join-Path $RepoPath "default-config.json")
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # If no local config found, use remote default
    return "${baseUrl}${targetBranch}/core-runner/core_app/default-config.json"
}

function Get-ConfigurationFromPath {
    param([string]$Path)
    
    try {
        if ($Path -like "http*") {
            Write-CustomLog "Downloading configuration from $Path..." "INFO"
            $configContent = Invoke-WebRequest -Uri $Path -UseBasicParsing | Select-Object -ExpandProperty Content
        } else {
            Write-CustomLog "Loading configuration from $Path..." "INFO"
            $configContent = Get-Content -Path $Path -Raw
        }
        
        return $configContent | ConvertFrom-Json
        
    } catch {
        Write-CustomLog "Failed to load configuration from $Path`: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-RepositoryClone {
    param(
        [string]$RepoUrl,
        [string]$LocalPath,
        [string]$Branch = 'main'
    )
    
    Write-CustomLog "Cloning repository..." "INFO"
    Write-CustomLog "  From: $RepoUrl" "INFO"
    Write-CustomLog "  To: $LocalPath" "INFO"
    Write-CustomLog "  Branch: $Branch" "INFO"
    
    if (Test-Path $LocalPath) {
        Write-CustomLog "Local repository already exists at $LocalPath" "WARN"
        if ($NonInteractive) {
            Write-CustomLog "Updating existing repository..." "INFO"
            Push-Location $LocalPath
            try {
                & git fetch origin 2>$null
                & git reset --hard "origin/$Branch" 2>$null
                Write-CustomLog "Repository updated successfully" "SUCCESS"
            } catch {
                Write-CustomLog "Failed to update repository: $($_.Exception.Message)" "WARN"
            } finally {
                Pop-Location
            }
        } else {
            $response = Read-Host "Remove existing directory and re-clone? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Remove-Item $LocalPath -Recurse -Force
            } else {
                Write-CustomLog "Using existing repository" "INFO"
                return $LocalPath
            }
        }
    }
    
    try {
        & git clone --branch $Branch $RepoUrl $LocalPath 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone failed with exit code $LASTEXITCODE"
        }
        Write-CustomLog "Repository cloned successfully" "SUCCESS"
        return $LocalPath
    } catch {
        Write-CustomLog "Failed to clone repository: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Invoke-CoreRunner {
    param(
        [string]$RepoPath,
        [string]$ConfigFile
    )
    
    $coreRunnerPath = Join-Path $RepoPath "core-runner\core_app\core-runner.ps1"
    
    if (-not (Test-Path $coreRunnerPath)) {
        # Try alternative paths
        $alternativePaths = @(
            (Join-Path $RepoPath "core-runner\core-runner.ps1"),
            (Join-Path $RepoPath "runner.ps1")
        )
        
        foreach ($altPath in $alternativePaths) {
            if (Test-Path $altPath) {
                $coreRunnerPath = $altPath
                break
            }
        }
        
        if (-not (Test-Path $coreRunnerPath)) {
            Write-CustomLog "Core runner script not found in repository" "ERROR"
            throw "Core runner script not found"
        }
    }
    
    Write-CustomLog "Executing core runner: $coreRunnerPath" "INFO"
    
    # Set up environment variables for the core runner
    $env:PROJECT_ROOT = $RepoPath
    $env:PWSH_MODULES_PATH = Join-Path $RepoPath "core-runner\modules"
    
    try {        if ($WhatIfPreference) {
            Write-CustomLog "WHAT-IF: Would execute core runner with config: $ConfigFile" "INFO"
        } else {
            $params = @{
                ConfigFile = $ConfigFile
                Verbosity = $Verbosity
            }
            if ($NonInteractive) { $params['NonInteractive'] = $true }
            if ($Quiet) { $params['Quiet'] = $true }
            
            & $coreRunnerPath @params
        }
    } catch {
        Write-CustomLog "Core runner execution failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Main execution
try {
    Write-CustomLog "OpenTofu Lab Automation - Bootstrap" "INFO"
    Write-CustomLog "====================================" "INFO"
    Write-CustomLog ""
    
    # Step 1: Ensure Git is installed
    Install-GitIfNeeded
    
    # Step 2: Determine configuration
    if (-not $ConfigFile) {
        $ConfigFile = Get-DefaultConfigPath $PSScriptRoot
    }
    
    Write-CustomLog "Using configuration: $ConfigFile" "INFO"
    $config = Get-ConfigurationFromPath $ConfigFile
    
    # Step 3: Clone repository if needed
    $repoUrl = if ($config.RepoUrl) { $config.RepoUrl } else { "https://github.com/wizzense/opentofu-lab-automation.git" }
    $localPath = if ($config.LocalPath) { $config.LocalPath } else { Join-Path (Get-CrossPlatformTempPath) "opentofu-lab-automation" }
    
    $repoPath = Invoke-RepositoryClone -RepoUrl $repoUrl -LocalPath $localPath -Branch $targetBranch
    
    # Step 4: Update config file path to use local version if it was remote
    if ($ConfigFile -like "http*") {
        $localConfigPath = Get-DefaultConfigPath $repoPath
        if (Test-Path $localConfigPath) {
            $ConfigFile = $localConfigPath
            Write-CustomLog "Switched to local configuration: $ConfigFile" "INFO"
        }
    }
    
    # Step 5: Execute core runner
    Invoke-CoreRunner -RepoPath $repoPath -ConfigFile $ConfigFile
    
    Write-CustomLog ""
    Write-CustomLog "Bootstrap completed successfully" "SUCCESS"
    
} catch {
    Write-CustomLog ""
    Write-CustomLog "Bootstrap failed: $($_.Exception.Message)" "ERROR"
    Write-CustomLog "Stack trace:" "DEBUG"
    Write-CustomLog $_.ScriptStackTrace "DEBUG"
    exit 1
}
