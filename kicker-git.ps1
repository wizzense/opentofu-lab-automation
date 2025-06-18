<#
.SYNOPSIS
    Modern bootstrap script for OpenTofu Lab Automation with CoreApp orchestration.

.DESCRIPTION
    This is the single entry point for downloading and setting up the entire OpenTofu Lab Automation suite.
    It leverages the new CoreApp orchestration architecture for robust, modern deployment.
    
    Features:
    - Cross-platform support (Windows, Linux, macOS)
    - Self-updating capabilities
    - Comprehensive error handling and logging
    - Integration with CoreApp orchestration
    - Non-interactive mode support
    - Robust dependency management
    - Health checks and validation

.PARAMETER ConfigFile
    Path to custom configuration file. If not specified, will use default configuration.

.PARAMETER Quiet
    Run in quiet mode with minimal output.

.PARAMETER NonInteractive
    Run without any interactive prompts (suitable for automation).

.PARAMETER Verbosity
    Controls output verbosity: silent, normal, detailed.

.PARAMETER SkipPrerequisites
    Skip automatic installation of prerequisites (Git, GitHub CLI, PowerShell).

.PARAMETER TargetBranch
    Specify which branch to bootstrap from (default: main).

.PARAMETER LocalPath
    Custom local path for repository clone (default: temp directory).

.PARAMETER WhatIf
    Show what would be done without making changes.

.PARAMETER Force
    Force re-clone even if repository already exists.

.EXAMPLE
    # The ultimate one-liner - download and execute directly
    iex (iwr 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1').Content

.EXAMPLE
    # Traditional download and execute
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1' -OutFile '.\kicker-git.ps1'; .\kicker-git.ps1"

.EXAMPLE
    # Bootstrap with custom configuration
    .\kicker-git.ps1 -ConfigFile "my-lab-config.json"

.EXAMPLE
    # Non-interactive automation-friendly bootstrap
    .\kicker-git.ps1 -NonInteractive -Verbosity silent

.EXAMPLE
    # Bootstrap from development branch
    .\kicker-git.ps1 -TargetBranch "develop" -Verbosity detailed

.EXAMPLE
    # CI/CD pipeline usage
    curl -sL https://raw.githubusercontent.com/wizzense/opentofu-lab-automation/main/kicker-git.ps1 | pwsh -
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigFile,
    [switch]$Quiet,
    [switch]$NonInteractive,
    [ValidateSet('silent', 'normal', 'detailed')]
    [string]$Verbosity = 'normal',
    [switch]$SkipPrerequisites,
    [string]$TargetBranch = 'main',
    [string]$LocalPath,
    [switch]$Force
)

#Requires -Version 5.1

# Bootstrap constants
$script:BootstrapVersion = '2.0.0'
$script:RepoUrl = 'https://github.com/wizzense/opentofu-lab-automation.git'
$script:RawBaseUrl = 'https://raw.githubusercontent.com/wizzense/opentofu-lab-automation'
$script:DefaultConfigUrl = "$script:RawBaseUrl/$TargetBranch/core-runner/core_app/default-config.json"

# Auto-detect environment
$script:PlatformWindows = $PSVersionTable.PSVersion.Major -le 5 -or [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$script:PlatformLinux = $PSVersionTable.PSVersion.Major -gt 5 -and [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)
$script:PlatformMacOS = $PSVersionTable.PSVersion.Major -gt 5 -and [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)
$script:IsInteractive = $Host.UI.RawUI.KeyAvailable -and [Environment]::UserInteractive

# Auto-detect non-interactive mode
if (-not $NonInteractive -and (-not $script:IsInteractive -or $env:CI -eq 'true' -or $env:GITHUB_ACTIONS -eq 'true')) {
    $NonInteractive = $true
    Write-Verbose "Auto-detected non-interactive environment"
}

# Set verbosity
if ($Quiet) { $Verbosity = 'silent' }
$script:VerbosityLevel = @{ silent = 0; normal = 1; detailed = 2 }[$Verbosity]

# Cross-platform paths (defined early)
function Get-PlatformTempPath {
    if ($script:PlatformWindows) {
        if ($env:TEMP) {
            return $env:TEMP
        } else {
            return 'C:\temp'
        }
    } else {
        if ($env:TMPDIR) {
            return $env:TMPDIR
        } else {
            return '/tmp'
        }
    }
}

# Robust logging with fallback
function Write-BootstrapLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO',
        
        [switch]$NoTimestamp
    )
    
    $levelPriority = @{ INFO = 1; WARN = 1; ERROR = 0; SUCCESS = 1 }[$Level]
    
    if ($script:VerbosityLevel -ge $levelPriority) {
        $timestamp = if ($NoTimestamp) { '' } else { "[$(Get-Date -Format 'HH:mm:ss')] " }
        $colorMap = @{ INFO = 'White'; WARN = 'Yellow'; ERROR = 'Red'; SUCCESS = 'Green' }
        
        Write-Host "$timestamp$Level`: $Message" -ForegroundColor $colorMap[$Level]
    }
      # Always log to file if possible
    if ($script:LogFile -and (Test-Path (Split-Path $script:LogFile -Parent))) {
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

# Initialize logging after function definition
$script:LogFile = Join-Path (Get-PlatformTempPath) "opentofu-lab-bootstrap-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
New-Item -ItemType File -Path $script:LogFile -Force -ErrorAction SilentlyContinue | Out-Null

Write-BootstrapLog "OpenTofu Lab Automation Bootstrap v$script:BootstrapVersion" 'SUCCESS'
Write-BootstrapLog "Platform: $(if ($PSVersionTable.OS) { $PSVersionTable.OS } else { 'Windows' })" 'INFO'
Write-BootstrapLog "PowerShell: $($PSVersionTable.PSVersion)" 'INFO'

# Cross-platform paths
function Get-PlatformPowerShell {
    if ($script:PlatformWindows) {
        $pwshPaths = @(
            "$env:ProgramFiles\PowerShell\7\pwsh.exe",
            "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe",
            "pwsh.exe"
        )
        foreach ($path in $pwshPaths) {
            if (Get-Command $path -ErrorAction SilentlyContinue) {
                return $path
            }
        }
        return "powershell.exe"
    } else {
        $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwshCmd) {
            return $pwshCmd.Source
        } else {
            return '/usr/bin/pwsh'
        }
    }
}

# Error handling
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Dependency checking and installation
function Test-Prerequisite {
    param(
        [string]$Name,
        [string[]]$Commands,
        [string]$InstallUrl,
        [string]$InstallInstructions
    )
    
    Write-BootstrapLog "Checking prerequisite: $Name" 'INFO'
    
    foreach ($cmd in $Commands) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-BootstrapLog "✓ $Name is available ($cmd)" 'SUCCESS'
            return $true
        }
    }
    
    Write-BootstrapLog "✗ $Name not found" 'WARN'
    
    if ($SkipPrerequisites) {
        Write-BootstrapLog "Skipping $Name installation (SkipPrerequisites specified)" 'WARN'
        return $false
    }
    
    if ($NonInteractive) {
        Write-BootstrapLog "Cannot install $Name in non-interactive mode" 'ERROR'
        Write-BootstrapLog "Please install manually: $InstallInstructions" 'INFO'
        return $false
    }
    
    Write-BootstrapLog "Installation required for $Name" 'INFO'
    Write-BootstrapLog "Instructions: $InstallInstructions" 'INFO'
    
    if ($InstallUrl) {
        Write-BootstrapLog "Download: $InstallUrl" 'INFO'
    }
    
    return $false
}

function Install-GitForWindows {
    if (-not $script:IsWindows) { return $false }
    
    Write-BootstrapLog "Installing Git for Windows..." 'INFO'
    
    try {
        $gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.47.1-64-bit.exe"
        $gitInstaller = Join-Path (Get-PlatformTempPath) "Git-Installer.exe"
        
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        Start-Process -FilePath $gitInstaller -ArgumentList "/SILENT", "/NORESTART" -Wait -NoNewWindow
        Remove-Item $gitInstaller -ErrorAction SilentlyContinue
        
        # Refresh PATH
        $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
        
        Write-BootstrapLog "Git installation completed" 'SUCCESS'
        return $true
    } catch {
        Write-BootstrapLog "Git installation failed: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Install-PowerShell7 {
    if (-not $script:IsWindows) { return $false }
    
    Write-BootstrapLog "Installing PowerShell 7..." 'INFO'
    
    try {
        $pwshUrl = "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.4.6-win-x64.msi"
        $pwshInstaller = Join-Path (Get-PlatformTempPath) "PowerShell-7-Installer.msi"
        
        Invoke-WebRequest -Uri $pwshUrl -OutFile $pwshInstaller -UseBasicParsing
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $pwshInstaller, "/quiet", "/norestart" -Wait -NoNewWindow
        Remove-Item $pwshInstaller -ErrorAction SilentlyContinue
        
        Write-BootstrapLog "PowerShell 7 installation completed" 'SUCCESS'
        return $true
    } catch {
        Write-BootstrapLog "PowerShell 7 installation failed: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

# Main prerequisite validation
function Test-Prerequisites {
    Write-BootstrapLog "=== Validating Prerequisites ===" 'INFO'
    
    $allGood = $true
    
    # PowerShell 7 (recommended but not required)
    if (-not (Test-Prerequisite -Name "PowerShell 7" -Commands @("pwsh") -InstallInstructions "Install from https://github.com/PowerShell/PowerShell/releases")) {
        if ($script:IsWindows -and -not $SkipPrerequisites) {
            Install-PowerShell7 | Out-Null
        }
    }
    
    # Git
    if (-not (Test-Prerequisite -Name "Git" -Commands @("git") -InstallUrl "https://git-scm.com/downloads" -InstallInstructions "Install Git from https://git-scm.com/downloads")) {
        if ($script:IsWindows -and -not $SkipPrerequisites) {
            if (-not (Install-GitForWindows)) {
                $allGood = $false
            }
        } else {
            $allGood = $false
        }
    }
    
    # GitHub CLI (optional but recommended)
    Test-Prerequisite -Name "GitHub CLI" -Commands @("gh") -InstallUrl "https://cli.github.com/" -InstallInstructions "Install from https://cli.github.com/" | Out-Null
    
    if (-not $allGood) {
        throw "Required prerequisites are missing. Please install them and re-run this script."
    }
    
    Write-BootstrapLog "✓ All required prerequisites are available" 'SUCCESS'
}

# Repository operations
function Get-RepositoryPath {
    if ($LocalPath) {
        $basePath = $LocalPath
    } else {
        $basePath = Get-PlatformTempPath
    }
    
    return Join-Path $basePath "opentofu-lab-automation"
}

function Sync-Repository {
    $repoPath = Get-RepositoryPath
    
    Write-BootstrapLog "=== Repository Synchronization ===" 'INFO'
    Write-BootstrapLog "Target path: $repoPath" 'INFO'
    Write-BootstrapLog "Branch: $TargetBranch" 'INFO'
    
    if (Test-Path $repoPath) {
        if ($Force) {
            Write-BootstrapLog "Removing existing repository (Force specified)" 'WARN'
            Remove-Item $repoPath -Recurse -Force        } else {
            Write-BootstrapLog "Repository exists, updating..." 'INFO'
            try {
                Push-Location $repoPath
                git fetch origin 2>&1 | Out-Null
                git reset --hard "origin/$TargetBranch" 2>&1 | Out-Null
                git clean -fdx 2>&1 | Out-Null
                Write-BootstrapLog "✓ Repository updated successfully" 'SUCCESS'
                Pop-Location
                return $repoPath
            } catch {
                Write-BootstrapLog "Update failed, will re-clone: $($_.Exception.Message)" 'WARN'
                Pop-Location
                Remove-Item $repoPath -Recurse -Force
            }
        }
    }
    
    Write-BootstrapLog "Cloning repository..." 'INFO'
    
    try {
        $parentPath = Split-Path $repoPath -Parent
        if (-not (Test-Path $parentPath)) {
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
        }
        
        git clone --branch $TargetBranch --single-branch --depth 1 $script:RepoUrl $repoPath 2>&1 | Out-Null
        
        if (-not (Test-Path $repoPath)) {
            throw "Repository clone appeared successful but path does not exist"
        }
        
        Write-BootstrapLog "✓ Repository cloned successfully" 'SUCCESS'
        return $repoPath
    } catch {
        throw "Failed to clone repository: $($_.Exception.Message)"
    }
}

# Configuration management
function Get-BootstrapConfig {
    param([string]$RepoPath)
    
    Write-BootstrapLog "=== Configuration Loading ===" 'INFO'
    
    if ($ConfigFile -and (Test-Path $ConfigFile)) {
        $configPath = $ConfigFile
        Write-BootstrapLog "Using specified config: $configPath" 'INFO'
    } else {
        # Look for config in repo
        $defaultConfigPath = Join-Path $RepoPath "core-runner/core_app/default-config.json"
        
        if (Test-Path $defaultConfigPath) {
            $configPath = $defaultConfigPath
            Write-BootstrapLog "Using repository default config" 'INFO'
        } else {
            # Download default config
            $tempConfig = Join-Path (Get-PlatformTempPath) "bootstrap-config.json"
            try {
                Invoke-WebRequest -Uri $script:DefaultConfigUrl -OutFile $tempConfig -UseBasicParsing
                $configPath = $tempConfig
                Write-BootstrapLog "Downloaded default configuration" 'INFO'
            } catch {
                Write-BootstrapLog "Could not download default config, using minimal config" 'WARN'
                return $null
            }
        }
    }
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-BootstrapLog "✓ Configuration loaded successfully" 'SUCCESS'
        return $config
    } catch {
        Write-BootstrapLog "Failed to parse configuration: $($_.Exception.Message)" 'ERROR'
        return $null
    }
}

# CoreApp orchestration
function Invoke-CoreAppBootstrap {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$RepoPath,
        [object]$Config
    )
    
    Write-BootstrapLog "=== CoreApp Orchestration Bootstrap ===" 'INFO'
    
    $runnerScript = Join-Path $RepoPath "core-runner/core_app/core-runner.ps1"
    
    if (-not (Test-Path $runnerScript)) {
        throw "CoreApp runner script not found at: $runnerScript"
    }
    
    Write-BootstrapLog "Invoking CoreApp orchestration..." 'INFO'
    
    try {
        Push-Location $RepoPath
          # Prepare arguments for CoreApp
        $coreAppArgs = @(
            '-NoLogo'
            '-NoProfile'
            '-File', $runnerScript
        )
        
        if ($Config) {
            $tempConfigPath = Join-Path (Get-PlatformTempPath) "bootstrap-runtime-config.json"
            $Config | ConvertTo-Json -Depth 10 | Set-Content $tempConfigPath
            $coreAppArgs += @('-ConfigFile', $tempConfigPath)
        }
        
        $coreAppArgs += @('-Verbosity', $Verbosity)
        
        if ($NonInteractive) {
            $coreAppArgs += '-NonInteractive'
        }
        
        # Use the best available PowerShell
        $pwshPath = Get-PlatformPowerShell
        Write-BootstrapLog "Using PowerShell: $pwshPath" 'INFO'
        
        if ($PSCmdlet.ShouldProcess("CoreApp Orchestration", "Start")) {
            $process = Start-Process -FilePath $pwshPath -ArgumentList $coreAppArgs -Wait -NoNewWindow -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-BootstrapLog "✓ CoreApp orchestration completed successfully" 'SUCCESS'
            } else {
                throw "CoreApp orchestration failed with exit code: $($process.ExitCode)"
            }
        }
        
        Pop-Location
    } catch {
        Pop-Location
        throw "CoreApp orchestration failed: $($_.Exception.Message)"
    }
}

# Demonstrate CoreApp orchestration features
function Show-CoreAppDemo {
    param([string]$RepoPath)
    
    if ($NonInteractive -or $script:VerbosityLevel -eq 0) {
        return
    }
    
    Write-BootstrapLog "" 'INFO' -NoTimestamp
    Write-BootstrapLog "🌟 Would you like to see the CoreApp orchestration in action? (y/N)" 'INFO' -NoTimestamp
    
    $response = Read-Host
    if ($response -match '^[Yy]') {
        Write-BootstrapLog "Demonstrating CoreApp orchestration features..." 'INFO'
        
        try {
            Push-Location $RepoPath
            
            # Import CoreApp module
            $coreAppPath = Join-Path $RepoPath "core-runner/core_app"
            Import-Module $coreAppPath -Force
            
            Write-BootstrapLog "✓ CoreApp module imported" 'SUCCESS'
            
            # Initialize and show module status
            Write-BootstrapLog "Initializing core application..." 'INFO'
            $initResult = Initialize-CoreApplication
            
            if ($initResult.Success) {
                Write-BootstrapLog "✓ Core application initialized" 'SUCCESS'
                Write-BootstrapLog "Loaded modules: $($initResult.LoadedModules -join ', ')" 'INFO'
            }
            
            # Show module status
            Write-BootstrapLog "Module Status:" 'INFO'
            $moduleStatus = Get-CoreModuleStatus
            $moduleStatus | ForEach-Object {
                $icon = if ($_.Status -eq 'Loaded') { '✓' } else { '⚠' }
                $color = if ($_.Status -eq 'Loaded') { 'SUCCESS' } else { 'WARN' }
                Write-BootstrapLog "  $icon $($_.Name): $($_.Status)" $color
            }
            
            Write-BootstrapLog "✓ CoreApp demonstration completed" 'SUCCESS'
            Pop-Location
            
        } catch {
            Write-BootstrapLog "Demo failed: $($_.Exception.Message)" 'WARN'
            Pop-Location
        }
    }
}

# Health check and validation
function Test-BootstrapHealth {
    param([string]$RepoPath)
    
    Write-BootstrapLog "=== Health Check ===" 'INFO'
    
    $healthItems = @(
        @{ Path = Join-Path $RepoPath "core-runner/core_app/CoreApp.psm1"; Name = "CoreApp Module" }
        @{ Path = Join-Path $RepoPath "core-runner/modules"; Name = "Core Modules Directory" }
        @{ Path = Join-Path $RepoPath "tests"; Name = "Test Framework" }
        @{ Path = Join-Path $RepoPath "opentofu"; Name = "OpenTofu Configuration" }
    )
    
    $healthGood = $true
    
    foreach ($item in $healthItems) {
        if (Test-Path $item.Path) {
            Write-BootstrapLog "✓ $($item.Name)" 'SUCCESS'
        } else {
            Write-BootstrapLog "✗ $($item.Name) - Missing: $($item.Path)" 'ERROR'
            $healthGood = $false
        }
    }
    
    if ($healthGood) {
        Write-BootstrapLog "✓ All health checks passed" 'SUCCESS'
    } else {
        Write-BootstrapLog "⚠ Some health checks failed - proceeding anyway" 'WARN'
    }
    
    return $healthGood
}

# Main bootstrap workflow
function Start-Bootstrap {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-BootstrapLog "=== OpenTofu Lab Automation Bootstrap ===" 'SUCCESS'
    
    try {
        # Step 1: Validate prerequisites
        Test-Prerequisites
        
        # Step 2: Sync repository
        $repoPath = Sync-Repository
        
        # Step 3: Load configuration
        $config = Get-BootstrapConfig -RepoPath $repoPath
        
        # Step 4: Health check
        Test-BootstrapHealth -RepoPath $repoPath | Out-Null
        
        # Step 5: Invoke CoreApp orchestration
        if (-not $PSCmdlet.ShouldProcess("Bootstrap Process", "Complete")) {
            Write-BootstrapLog "WhatIf: Would complete bootstrap with CoreApp orchestration" 'INFO'
            return
        }
        
        Invoke-CoreAppBootstrap -RepoPath $repoPath -Config $config
        
        # Step 6: Demonstrate CoreApp features (interactive only)
        Show-CoreAppDemo -RepoPath $repoPath
          # Success!
        Write-BootstrapLog "=== Bootstrap Completed Successfully ===" 'SUCCESS'
        Write-BootstrapLog "Repository location: $repoPath" 'INFO'
        Write-BootstrapLog "Log file: $script:LogFile" 'INFO'
        
        if ($script:VerbosityLevel -ge 1) {
            Write-BootstrapLog "" 'INFO' -NoTimestamp
            Write-BootstrapLog "🎉 OpenTofu Lab Automation is ready! 🎉" 'SUCCESS' -NoTimestamp
            Write-BootstrapLog "" 'INFO' -NoTimestamp
            Write-BootstrapLog "🚀 CoreApp Orchestration System:" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Import-Module '$repoPath/core-runner/core_app'" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Initialize-CoreApplication    # Initialize all modules" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Get-CoreModuleStatus         # Check module health" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Invoke-UnifiedMaintenance    # Run maintenance tasks" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Start-DevEnvironmentSetup    # Set up dev environment" 'INFO' -NoTimestamp
            Write-BootstrapLog "" 'INFO' -NoTimestamp
            Write-BootstrapLog "🔧 Quick Start Commands:" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Run tests: cd '$repoPath'; pwsh -Command 'Invoke-Pester'" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Open in VS Code: code '$repoPath/opentofu-lab-automation.code-workspace'" 'INFO' -NoTimestamp
            Write-BootstrapLog "  • Explore OpenTofu configs: $repoPath/opentofu/" 'INFO' -NoTimestamp
            Write-BootstrapLog "" 'INFO' -NoTimestamp
            Write-BootstrapLog "📚 Documentation: $repoPath/docs/" 'INFO' -NoTimestamp
            Write-BootstrapLog "🐛 Issues: https://github.com/wizzense/opentofu-lab-automation/issues" 'INFO' -NoTimestamp
        }
        
    } catch {
        Write-BootstrapLog "Bootstrap failed: $($_.Exception.Message)" 'ERROR'
        Write-BootstrapLog "Log file: $script:LogFile" 'INFO'
        exit 1
    }
}

# Script entry point
if ($MyInvocation.InvocationName -ne '.') {
    Start-Bootstrap
}
