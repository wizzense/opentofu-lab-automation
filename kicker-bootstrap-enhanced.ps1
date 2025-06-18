<#
.SYNOPSIS
    Enhanced bootstrap script that serves as a bridge to CoreApp orchestration.

.DESCRIPTION
    This is an enhanced version of the original kicker-bootstrap.ps1 that maintains
    backward compatibility while leveraging the new CoreApp orchestration architecture.
    
    This script:
    1. Validates and installs prerequisites (Git, GitHub CLI, PowerShell 7)
    2. Clones or updates the repository 
    3. Delegates to CoreApp orchestration for the actual lab setup
    4. Provides comprehensive logging and error handling
    5. Supports both interactive and automated execution

.PARAMETER ConfigFile
    Path to configuration file (JSON format).

.PARAMETER Quiet
    Run in quiet mode with minimal output.

.PARAMETER WhatIf
    Show what would be done without making changes.

.PARAMETER NonInteractive
    Run without interactive prompts (suitable for automation).

.PARAMETER Verbosity
    Output verbosity level: silent, normal, detailed.

.PARAMETER SkipGitHubAuth
    Skip GitHub authentication check.

.PARAMETER Force
    Force operations even if components exist.

.EXAMPLE
    .\kicker-bootstrap-enhanced.ps1

.EXAMPLE
    .\kicker-bootstrap-enhanced.ps1 -ConfigFile "custom-config.json" -Verbosity detailed

.EXAMPLE
    .\kicker-bootstrap-enhanced.ps1 -NonInteractive -Quiet
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigFile,
    [switch]$Quiet,
    [switch]$NonInteractive,
    [ValidateSet('silent', 'normal', 'detailed')]
    [string]$Verbosity = 'normal',
    [switch]$SkipGitHubAuth,
    [switch]$Force
)

#Requires -Version 5.1

# Enhanced Bootstrap Constants
$script:EnhancedVersion = '2.1.0'
$script:TargetBranch = 'main'
$script:BaseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/refs/heads/'
$script:DefaultConfig = "$script:BaseUrl$script:TargetBranch/core-runner/core_app/default-config.json"

# Environment detection
$script:IsWindowsOS = $PSVersionTable.PSVersion.Major -le 5 -or 
                      ($PSVersionTable.PSVersion.Major -gt 5 -and $IsWindows)

# Auto-detect non-interactive mode
if (-not $NonInteractive) {
    $commandLine = [Environment]::GetCommandLineArgs() -join ' '
    if ($commandLine -match '-NonInteractive' -or 
        $Host.Name -eq 'Default Host' -or
        ([Environment]::UserInteractive -eq $false) -or
        $env:CI -eq 'true') {
        $NonInteractive = $true
        Write-Verbose 'Auto-detected non-interactive mode'
    }
}

# Set verbosity
if ($Quiet) { $Verbosity = 'silent' }
$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel = $script:VerbosityLevels[$Verbosity]

# Cross-platform utility functions
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
        [string[]]$ChildPaths
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

# Enhanced logging with structured output
function Write-EnhancedLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',
        
        [string]$Category = 'BOOTSTRAP'
    )
    
    $levelPriority = @{ 
        DEBUG = 2; INFO = 1; WARN = 1; ERROR = 0; SUCCESS = 1 
    }[$Level]
    
    # Only show DEBUG messages in detailed mode
    if ($Level -eq 'DEBUG' -and $script:ConsoleLevel -lt 2) {
        return
    }
    
    if ($script:ConsoleLevel -ge $levelPriority) {
        $timestamp = Get-Date -Format 'HH:mm:ss'
        $colorMap = @{ 
            INFO = 'White'; WARN = 'Yellow'; ERROR = 'Red'; 
            SUCCESS = 'Green'; DEBUG = 'Gray' 
        }
        
        $prefix = "[$timestamp] [$Category] $Level"
        Write-Host "$prefix`: $Message" -ForegroundColor $colorMap[$Level]
    }
    
    # Always log to file
    if ($script:LogFilePath -and (Test-Path (Split-Path $script:LogFilePath -Parent))) {
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Category] [$Level] $Message"
        Add-Content -Path $script:LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    }
}

# Initialize enhanced logging
$script:LogFilePath = Join-Path (Get-CrossPlatformTempPath) "opentofu-bootstrap-enhanced-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
New-Item -ItemType File -Path $script:LogFilePath -Force -ErrorAction SilentlyContinue | Out-Null

Write-EnhancedLog "Enhanced Bootstrap v$script:EnhancedVersion starting" 'SUCCESS'
Write-EnhancedLog "Platform: $($PSVersionTable.OS ?? 'Windows PowerShell')" 'INFO'
Write-EnhancedLog "PowerShell: $($PSVersionTable.PSVersion)" 'INFO'
Write-EnhancedLog "Verbosity: $Verbosity, NonInteractive: $NonInteractive" 'DEBUG'

# Error handling
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Continue {
    param([string]$Message = 'Press any key to continue...')
    
    if ($WhatIf -or $NonInteractive -or $Quiet -or 
        ([Environment]::UserInteractive -eq $false) -or
        ($Host.Name -eq 'ConsoleHost' -and -not $Host.UI.RawUI.KeyAvailable)) {
        Write-EnhancedLog "Skipping interactive prompt: $Message" 'DEBUG'
        return
    }
    
    if ([Environment]::UserInteractive -and $Host.Name -ne 'Default Host') {
        try {
            Write-Host $Message -ForegroundColor Yellow -NoNewline
            $null = Read-Host
        } catch {
            Write-EnhancedLog "Interactive prompt skipped: $($_.Exception.Message)" 'DEBUG'
        }
    }
}

# Enhanced configuration loading with better error handling
function Get-SafeLabConfig {
    param([string]$Path)
    
    try {
        Write-EnhancedLog "Loading configuration from: $Path" 'DEBUG'
        
        if (-not (Test-Path $Path)) {
            throw "Configuration file not found: $Path"
        }
        
        $content = Get-Content -Raw -LiteralPath $Path
        $config = $content | ConvertFrom-Json
        
        # Enhance config with computed paths
        $labDir = Split-Path -Parent $Path
        $repoRoot = if ($labDir -match 'core-runner') {
            Resolve-Path (Join-PathRobust $labDir '..')
        } else {
            Resolve-Path $labDir
        }
        
        # Add enhanced directory structure
        $dirs = @{}
        if ($config.PSObject.Properties['Directories']) {
            $config.Directories.PSObject.Properties | ForEach-Object { 
                $dirs[$_.Name] = $_.Value 
            }
        }
        
        $dirs['RepoRoot'] = $repoRoot.Path
        $dirs['CoreApp'] = Join-PathRobust $repoRoot.Path @('core-runner', 'core_app')
        $dirs['Modules'] = Join-PathRobust $repoRoot.Path @('core-runner', 'modules')
        $dirs['Tests'] = Join-PathRobust $repoRoot.Path @('tests')
        $dirs['OpenTofu'] = Join-PathRobust $repoRoot.Path @('opentofu')
        $dirs['Configs'] = Join-PathRobust $repoRoot.Path @('configs')
        
        $directoryObject = New-Object PSCustomObject -Property $dirs
        Add-Member -InputObject $config -MemberType NoteProperty -Name Directories -Value $directoryObject -Force
        
        Write-EnhancedLog "Configuration loaded successfully" 'SUCCESS'
        return $config
        
    } catch {
        Write-EnhancedLog "Configuration loading failed: $($_.Exception.Message)" 'ERROR'
        throw
    }
}

# Enhanced prerequisite checking
function Test-EnhancedPrerequisites {
    Write-EnhancedLog "=== Prerequisite Validation ===" 'INFO'
    
    $prerequisites = @(
        @{
            Name = 'Git'
            Commands = @('git')
            WindowsPath = 'C:\Program Files\Git\cmd\git.exe'
            Required = $true
        },
        @{
            Name = 'GitHub CLI'
            Commands = @('gh')
            Required = $false
        },
        @{
            Name = 'PowerShell 7'
            Commands = @('pwsh')
            Required = $false
        }
    )
    
    $missingRequired = @()
    
    foreach ($prereq in $prerequisites) {
        $found = $false
        
        foreach ($cmd in $prereq.Commands) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                Write-EnhancedLog "✓ $($prereq.Name) found: $cmd" 'SUCCESS'
                $found = $true
                break
            }
        }
        
        if (-not $found -and $script:IsWindowsOS -and $prereq.WindowsPath) {
            if (Test-Path $prereq.WindowsPath) {
                Write-EnhancedLog "✓ $($prereq.Name) found: $($prereq.WindowsPath)" 'SUCCESS'
                $found = $true
            }
        }
        
        if (-not $found) {
            if ($prereq.Required) {
                Write-EnhancedLog "✗ $($prereq.Name) not found (REQUIRED)" 'ERROR'
                $missingRequired += $prereq.Name
            } else {
                Write-EnhancedLog "⚠ $($prereq.Name) not found (optional)" 'WARN'
            }
        }
    }
    
    if ($missingRequired.Count -gt 0) {
        $missing = $missingRequired -join ', '
        throw "Missing required prerequisites: $missing. Please install them before continuing."
    }
    
    Write-EnhancedLog "✓ All required prerequisites validated" 'SUCCESS'
}

# Enhanced Git operations with better error handling
function Update-RepositoryRobust {
    param(
        [string]$RepoPath,
        [string]$Branch,
        [string]$GitPath = 'git'
    )
    
    Write-EnhancedLog "Updating repository: $RepoPath" 'INFO'
    
    try {
        Push-Location $RepoPath
        
        # Check for local changes in config files
        $configChanges = & $GitPath status --porcelain "configs/" 2>$null
        $backupDir = $null
        
        if ($configChanges -and (Test-Path 'configs/')) {
            $backupDir = Join-Path $RepoPath 'config_backup_temp'
            Write-EnhancedLog "Backing up local config changes" 'WARN'
            
            if (Test-Path $backupDir) { 
                Remove-Item -Recurse -Force $backupDir 
            }
            Copy-Item -Path 'configs/' -Destination $backupDir -Recurse -Force
            
            & $GitPath stash push -u -- 'configs/' | Out-Null
        }
        
        # Update repository
        Write-EnhancedLog "Fetching latest changes from origin/$Branch" 'INFO'
        & $GitPath fetch origin $Branch --quiet
        & $GitPath reset --hard "origin/$Branch" --quiet
        & $GitPath clean -fdx --quiet
        
        # Restore config changes if any
        if ($configChanges -and (Test-Path $backupDir)) {
            Write-EnhancedLog 'Restoring backed up config files' 'INFO'
            Copy-Item -Path (Join-Path $backupDir '*') -Destination 'configs/' -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Recurse -Force $backupDir -ErrorAction SilentlyContinue
            & $GitPath stash drop --quiet 2>$null | Out-Null
        }
        
        Write-EnhancedLog "✓ Repository updated successfully" 'SUCCESS'
        
    } catch {
        Write-EnhancedLog "Repository update failed: $($_.Exception.Message)" 'ERROR'
        throw
    } finally {
        Pop-Location
    }
}

# Enhanced repository operations
function Sync-RepositoryEnhanced {
    param(
        [string]$RepoUrl,
        [string]$LocalPath,
        [string]$Branch = 'main'
    )
    
    Write-EnhancedLog "=== Repository Synchronization ===" 'INFO'
    Write-EnhancedLog "Repository: $RepoUrl" 'INFO'
    Write-EnhancedLog "Local path: $LocalPath" 'INFO'
    Write-EnhancedLog "Branch: $Branch" 'INFO'
    
    $repoName = ($RepoUrl -split '/')[-1] -replace '\.git$', ''
    $repoPath = Join-Path $LocalPath $repoName
    
    if (Test-Path $repoPath) {
        if ($Force) {
            Write-EnhancedLog "Removing existing repository (Force specified)" 'WARN'
            Remove-Item $repoPath -Recurse -Force
        } else {
            Write-EnhancedLog "Repository exists, attempting update..." 'INFO'
            try {
                Update-RepositoryRobust -RepoPath $repoPath -Branch $Branch
                return $repoPath
            } catch {
                Write-EnhancedLog "Update failed, will re-clone: $($_.Exception.Message)" 'WARN'
                Remove-Item $repoPath -Recurse -Force
            }
        }
    }
    
    Write-EnhancedLog "Cloning repository..." 'INFO'
    
    try {
        if (-not (Test-Path $LocalPath)) {
            New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
        }
        
        $gitArgs = @('clone', '--branch', $Branch, '--single-branch', '--depth', '1', $RepoUrl, $repoPath)
        & git @gitArgs
        
        if (-not (Test-Path $repoPath)) {
            throw "Repository clone succeeded but path does not exist: $repoPath"
        }
        
        Write-EnhancedLog "✓ Repository cloned successfully" 'SUCCESS'
        return $repoPath
        
    } catch {
        throw "Failed to clone repository: $($_.Exception.Message)"
    }
}

# CoreApp orchestration integration
function Invoke-CoreAppOrchestration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$RepoPath,
        [object]$Config
    )
    
    Write-EnhancedLog "=== CoreApp Orchestration ===" 'INFO'
    
    $coreAppRunner = Join-Path $RepoPath "core-runner/core_app/core-runner.ps1"
    
    if (-not (Test-Path $coreAppRunner)) {
        # Fallback to legacy runner
        $legacyRunner = Join-Path $RepoPath "core-runner/core-runner.ps1"
        if (Test-Path $legacyRunner) {
            Write-EnhancedLog "Using legacy runner (CoreApp not found)" 'WARN'
            $coreAppRunner = $legacyRunner
        } else {
            throw "No valid runner script found in repository"
        }
    }
    
    Write-EnhancedLog "Runner script: $coreAppRunner" 'DEBUG'
    
    if (-not $PSCmdlet.ShouldProcess("CoreApp Orchestration", "Execute")) {
        Write-EnhancedLog "WhatIf: Would execute CoreApp orchestration" 'INFO'
        return
    }
    
    try {
        # Prepare configuration file for runner
        $tempConfigPath = $null
        if ($Config) {
            $tempConfigPath = Join-Path (Get-CrossPlatformTempPath) "enhanced-bootstrap-config.json"
            $Config | ConvertTo-Json -Depth 10 | Set-Content $tempConfigPath
        }
        
        # Build arguments for runner
        $runnerArgs = @(
            '-NoLogo'
            '-NoProfile'
            '-File', $coreAppRunner
        )
        
        if ($tempConfigPath) {
            $runnerArgs += @('-ConfigFile', $tempConfigPath)
        }
        
        $runnerArgs += @('-Verbosity', $Verbosity)
        
        if ($NonInteractive) {
            $runnerArgs += '-NonInteractive'
        }
        
        # Choose PowerShell executable
        $pwshExecutable = if (Get-Command 'pwsh' -ErrorAction SilentlyContinue) {
            'pwsh'
        } else {
            'powershell'
        }
        
        Write-EnhancedLog "Executing: $pwshExecutable with CoreApp orchestration" 'INFO'
        
        Push-Location $RepoPath
        $process = Start-Process -FilePath $pwshExecutable -ArgumentList $runnerArgs -Wait -NoNewWindow -PassThru
        Pop-Location
        
        # Cleanup temp config
        if ($tempConfigPath -and (Test-Path $tempConfigPath)) {
            Remove-Item $tempConfigPath -ErrorAction SilentlyContinue
        }
        
        if ($process.ExitCode -eq 0) {
            Write-EnhancedLog "✓ CoreApp orchestration completed successfully" 'SUCCESS'
        } else {
            throw "CoreApp orchestration failed with exit code: $($process.ExitCode)"
        }
        
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        if ($tempConfigPath -and (Test-Path $tempConfigPath)) {
            Remove-Item $tempConfigPath -ErrorAction SilentlyContinue
        }
        throw "CoreApp orchestration failed: $($_.Exception.Message)"
    }
}

# Configuration loading with fallback
function Get-BootstrapConfiguration {
    Write-EnhancedLog "=== Configuration Loading ===" 'INFO'
    
    $configPath = $null
    
    # Priority 1: Explicit config file
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        $configPath = $ConfigFile
        Write-EnhancedLog "Using specified config: $configPath" 'INFO'
    }
    # Priority 2: Look for configs in current directory
    elseif (-not $ConfigFile) {
        $localConfigs = Get-ChildItem -Path "." -Filter "*.json" | Where-Object { $_.Name -match "config" }
        
        if ($localConfigs.Count -eq 1) {
            $configPath = $localConfigs[0].FullName
            Write-EnhancedLog "Using local config: $configPath" 'INFO'
        } elseif ($localConfigs.Count -gt 1 -and -not $NonInteractive) {
            Write-EnhancedLog "Multiple config files found:" 'INFO'
            for ($i = 0; $i -lt $localConfigs.Count; $i++) {
                Write-Host "  $($i + 1). $($localConfigs[$i].Name)" -ForegroundColor Cyan
            }
            
            do {
                $selection = Read-Host "Select config file (1-$($localConfigs.Count), or Enter for default)"
                if ([string]::IsNullOrWhiteSpace($selection)) {
                    break
                }
                if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $localConfigs.Count) {
                    $configPath = $localConfigs[[int]$selection - 1].FullName
                    Write-EnhancedLog "Using selected config: $configPath" 'INFO'
                    break
                }
                Write-Host "Invalid selection. Please try again." -ForegroundColor Yellow
            } while ($true)
        }
    }
    
    # Fallback: Download default config
    if (-not $configPath) {
        Write-EnhancedLog "Downloading default configuration" 'INFO'
        $configPath = Join-Path (Get-CrossPlatformTempPath) "bootstrap-default-config.json"
        try {
            Invoke-WebRequest -Uri $script:DefaultConfig -OutFile $configPath -UseBasicParsing
            Write-EnhancedLog "✓ Default config downloaded" 'SUCCESS'
        } catch {
            Write-EnhancedLog "Could not download default config: $($_.Exception.Message)" 'WARN'
            return $null
        }
    }
    
    # Load and validate configuration
    try {
        $config = Get-SafeLabConfig -Path $configPath
        Write-EnhancedLog "✓ Configuration loaded and validated" 'SUCCESS'
        return $config
    } catch {
        Write-EnhancedLog "Configuration validation failed: $($_.Exception.Message)" 'ERROR'
        throw
    }
}

# Main enhanced bootstrap workflow
function Start-EnhancedBootstrap {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    Write-EnhancedLog "=== Enhanced Bootstrap Workflow ===" 'SUCCESS'
    
    try {
        # Step 1: Validate prerequisites
        Test-EnhancedPrerequisites
        
        # Step 2: Load configuration
        $config = Get-BootstrapConfiguration
        
        if (-not $config) {
            Write-EnhancedLog "Proceeding with minimal configuration" 'WARN'
            $config = [PSCustomObject]@{
                RepoUrl = 'https://github.com/wizzense/opentofu-lab-automation.git'
                LocalPath = Get-CrossPlatformTempPath
            }
        }
        
        # Step 3: Sync repository
        $localPath = $config.LocalPath ?? (Get-CrossPlatformTempPath)
        $repoUrl = $config.RepoUrl ?? 'https://github.com/wizzense/opentofu-lab-automation.git'
        
        $repoPath = Sync-RepositoryEnhanced -RepoUrl $repoUrl -LocalPath $localPath -Branch $script:TargetBranch
        
        # Step 4: Validate repository structure
        $coreComponents = @(
            'core-runner/core_app',
            'core-runner/modules',
            'tests',
            'opentofu'
        )
        
        foreach ($component in $coreComponents) {
            $componentPath = Join-Path $repoPath $component
            if (Test-Path $componentPath) {
                Write-EnhancedLog "✓ Component found: $component" 'SUCCESS'
            } else {
                Write-EnhancedLog "⚠ Component missing: $component" 'WARN'
            }
        }
        
        # Step 5: Execute CoreApp orchestration
        if ($PSCmdlet.ShouldProcess("Enhanced Bootstrap", "Complete")) {
            Invoke-CoreAppOrchestration -RepoPath $repoPath -Config $config
        }
        
        # Success summary
        Write-EnhancedLog "=== Enhanced Bootstrap Completed ===" 'SUCCESS'
        Write-EnhancedLog "Repository: $repoPath" 'INFO'
        Write-EnhancedLog "Log file: $script:LogFilePath" 'INFO'
        
        if ($script:ConsoleLevel -ge 1) {
            Write-EnhancedLog "" 'INFO'
            Write-EnhancedLog "Next steps:" 'INFO'
            Write-EnhancedLog "  • Explore the lab: cd '$repoPath'" 'INFO'
            Write-EnhancedLog "  • Run tests: Invoke-Pester" 'INFO'
            Write-EnhancedLog "  • Check OpenTofu: cd opentofu && tofu plan" 'INFO'
        }
        
    } catch {
        Write-EnhancedLog "Enhanced bootstrap failed: $($_.Exception.Message)" 'ERROR'
        Write-EnhancedLog "Stack trace: $($_.ScriptStackTrace)" 'DEBUG'
        Write-EnhancedLog "Log file: $script:LogFilePath" 'INFO'
        exit 1
    }
}

# Script entry point with compatibility check
if ($MyInvocation.InvocationName -ne '.') {
    # Validate PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Error "This script requires PowerShell 5.1 or later. Current version: $($PSVersionTable.PSVersion)"
        exit 1
    }
    
    # Execute enhanced bootstrap
    Start-EnhancedBootstrap
}
