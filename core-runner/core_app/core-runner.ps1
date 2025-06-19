#Requires -Version 7.0

<#
.SYNOPSIS
    Core application runner for OpenTofu Lab Automation
    
.DESCRIPTION
    Main runner script that orchestrates lab setup, configuration, and script execution
    for the OpenTofu Lab Automation project.
    
.PARAMETER Quiet
    Run in quiet mode with minimal output
    
.PARAMETER Verbosity
    Set verbosity level: silent, normal, detailed
    
.PARAMETER ConfigFile
    Path to configuration file (defaults to default-config.json)
    
.PARAMETER Auto
    Run in automatic mode without prompts
    
.PARAMETER Scripts
    Specific scripts to run
    
.PARAMETER Force
    Force operations even if validations fail
    
.PARAMETER NonInteractive
    Run in non-interactive mode, suppress prompts and user input
    
.EXAMPLE
    .\core-runner.ps1
    
.EXAMPLE
    .\core-runner.ps1 -ConfigFile "custom-config.json" -Verbosity detailed
#>

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Verbose')]
param(
    [Parameter(ParameterSetName = 'Quiet')]
    [switch]$Quiet,

    [Parameter(ParameterSetName = 'Verbose')]
    [ValidateSet('silent', 'normal', 'detailed')]
    [string]$Verbosity = 'normal',
      [string]$ConfigFile,
    [switch]$Auto,
    [string]$Scripts,
    [switch]$Force,
    [switch]$NonInteractive
)

# Set up environment
$ErrorActionPreference = 'Stop'

# Auto-detect non-interactive mode if not explicitly set
if (-not $NonInteractive) {
    $NonInteractive = ($Host.Name -eq 'Default Host') -or 
                     ([Environment]::UserInteractive -eq $false) -or
                     ($env:PESTER_RUN -eq 'true') -or
                     ($PSCmdlet.WhatIf) -or
                     ($Auto.IsPresent)
}

# Determine repository root - go up one level from core_app to core-runner, then up one more to repo root
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$env:PROJECT_ROOT = $repoRoot
$env:PWSH_MODULES_PATH = "$repoRoot/core-runner/modules"

Write-Verbose "Repository root: $repoRoot"
Write-Verbose "Modules path: $env:PWSH_MODULES_PATH"

# Apply default ConfigFile if not provided
if (-not $PSBoundParameters.ContainsKey('ConfigFile')) {
    $ConfigFile = Join-Path $PSScriptRoot 'default-config.json'
    if (-not (Test-Path $ConfigFile)) {
        $ConfigFile = "$repoRoot/configs/default-config.json"
    }
}

# Apply quiet flag to verbosity
if ($Quiet) { 
    $Verbosity = 'silent' 
}

$script:VerbosityLevels = @{ silent = 0; normal = 1; detailed = 2 }
$script:ConsoleLevel = $script:VerbosityLevels[$Verbosity]

# Determine pwsh executable path for nested script execution
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) {
    $exeName = if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' }
    $pwshPath = Join-Path $PSHOME $exeName
}

if (-not (Test-Path $pwshPath)) {
    Write-Error 'PowerShell 7 not found. Please install PowerShell 7 or adjust PATH.'
    exit 1
}

# Re-launch under PowerShell 7 if running under Windows PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host 'Switching to PowerShell 7...' -ForegroundColor Yellow
    
    $argList = @()
    foreach ($kvp in $PSBoundParameters.GetEnumerator()) {
        if ($kvp.Value -is [System.Management.Automation.SwitchParameter]) {
            if ($kvp.Value.IsPresent) { 
                $argList += "-$($kvp.Key)" 
            }
        } else {
            $argList += "-$($kvp.Key)"
            $argList += $kvp.Value
        }
    }
    
    & $pwshPath -File $PSCommandPath @argList
    exit $LASTEXITCODE
}

# Import required modules
try {
    Write-Verbose 'Importing Logging module...'
    Import-Module "$env:PWSH_MODULES_PATH/Logging" -Force -ErrorAction Stop
    
    Write-Verbose 'Importing LabRunner module...'
    Import-Module "$env:PWSH_MODULES_PATH/LabRunner" -Force -ErrorAction Stop
    
    Write-CustomLog 'Core runner started' -Level INFO
} catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    Write-Error "Ensure modules exist at: $env:PWSH_MODULES_PATH"
    exit 1
}

# Set console verbosity level for LabRunner
$env:LAB_CONSOLE_LEVEL = $script:VerbosityLevels[$Verbosity]

# Load configuration
try {
    if (Test-Path $ConfigFile) {
        Write-CustomLog "Loading configuration from: $ConfigFile" -Level INFO
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    } else {
        Write-CustomLog "Configuration file not found: $ConfigFile" -Level WARN
        Write-CustomLog 'Using default configuration' -Level INFO
        $config = @{}
    }
} catch {
    Write-CustomLog "Failed to load configuration: $($_.Exception.Message)" -Level ERROR
    exit 1
}

# Main execution logic
try {
    Write-CustomLog 'Starting OpenTofu Lab Automation Core Runner' -Level SUCCESS
    Write-CustomLog "Repository root: $repoRoot" -Level INFO
    Write-CustomLog "Configuration file: $ConfigFile" -Level INFO
    Write-CustomLog "Verbosity level: $Verbosity" -Level INFO
    
    # Get available scripts
    $scriptsPath = Join-Path $PSScriptRoot 'scripts'
    if (Test-Path $scriptsPath) {
        $availableScripts = Get-ChildItem -Path $scriptsPath -Filter '*.ps1' | Sort-Object Name
        Write-CustomLog "Found $($availableScripts.Count) scripts" -Level INFO
        
        if ($Scripts) {
            # Run specific scripts
            $scriptList = $Scripts -split ','
            foreach ($scriptName in $scriptList) {
                $scriptPath = Join-Path $scriptsPath "$scriptName.ps1"
                if (Test-Path $scriptPath) {
                    Write-CustomLog "Executing script: $scriptName" -Level INFO
                    if ($PSCmdlet.ShouldProcess($scriptName, 'Execute script')) {
                        & $scriptPath -Config $config
                    }
                } else {
                    Write-CustomLog "Script not found: $scriptName" -Level WARN
                }
            }
        } elseif ($Auto) {
            # Run all scripts in auto mode
            Write-CustomLog 'Running all scripts in automatic mode' -Level INFO
            foreach ($script in $availableScripts) {
                Write-CustomLog "Executing script: $($script.BaseName)" -Level INFO
                if ($PSCmdlet.ShouldProcess($script.BaseName, 'Execute script')) {
                    & $script.FullName -Config $config
                }
            }        } else {
            # Check if running in non-interactive mode without specific scripts
            if ($NonInteractive -or $PSCmdlet.WhatIf) {
                Write-CustomLog 'Non-interactive mode: use -Scripts parameter to specify which scripts to run' -Level INFO
                Write-CustomLog 'No scripts specified for non-interactive execution' -Level WARN
                return  # Exit gracefully instead of interactive prompt
            } else {
                # Interactive mode - show menu
                Write-Host "`nAvailable Scripts:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $availableScripts.Count; $i++) {
                    $script = $availableScripts[$i]
                    Write-Host "  $($i + 1). $($script.BaseName)" -ForegroundColor Gray
                }
                
                Write-Host "`nEnter script numbers to run (comma-separated), 'all' for all scripts, or 'exit' to quit:" -ForegroundColor Yellow
                $selection = Read-Host 'Selection'
                
                if ($selection -eq 'exit') {
                    Write-CustomLog 'Exiting at user request' -Level INFO
                    return
                } elseif ($selection -eq 'all') {
                    foreach ($script in $availableScripts) {
                        Write-CustomLog "Executing script: $($script.BaseName)" -Level INFO
                        & $script.FullName -Config $config
                    }
                } else {
                    $selectedItems = $selection -split ',' | ForEach-Object { $_.Trim() }
                    foreach ($item in $selectedItems) {
                        $script = $null
                        if ($item -match '^\d+$' -and [int]$item -le $availableScripts.Count -and [int]$item -gt 0) {
                            $script = $availableScripts[[int]$item - 1]
                        } else {
                            $script = $availableScripts | Where-Object { $_.BaseName -eq $item -or $_.BaseName -like "$item*" } | Select-Object -First 1
                        }

                        if ($script) {
                            Write-CustomLog "Executing script: $($script.BaseName)" -Level INFO
                            & $script.FullName -Config $config
                        } else {
                            Write-CustomLog "Invalid selection: $item" -Level WARN
                        }
                    }
                }
            }
        }
    } else {
        Write-CustomLog "Scripts directory not found: $scriptsPath" -Level WARN
        Write-CustomLog 'No scripts to execute' -Level INFO
    }
    
    Write-CustomLog 'Core runner completed successfully' -Level SUCCESS
    
} catch {
    Write-CustomLog "Core runner failed: $($_.Exception.Message)" -Level ERROR
    Write-CustomLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
}
