#!/usr/bin/env pwsh
# Ensure environment variables are set for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = Join-Path $PSScriptRoot "src/pwsh/modules"
}
<#
.SYNOPSIS
    Environment setup script for OpenTofu Lab Automation project.

.DESCRIPTION
    Installs all required dependencies for running tests and linting:
    - PowerShell modules (Pester, PSScriptAnalyzer, etc.)
    - Python dependencies (pytest, flake8, pylint, etc.)
    - Configures development environment
    - Sets up multiprocessing execution based on CPU cores

.PARAMETER InstallScope
    Installation scope for PowerShell modules: CurrentUser or AllUsers

.PARAMETER PythonPath
    Path to Python executable (optional, will auto-detect if not provided)

.PARAMETER SkipPython
    Skip Python dependency installation

.PARAMETER Force
    Force reinstallation of dependencies

.EXAMPLE
    ./Setup-Environment.ps1
    Install all dependencies for current user

.EXAMPLE
    ./Setup-Environment.ps1 -InstallScope AllUsers -Force    Force reinstall all dependencies system-wide
#>

param(
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$InstallScope = 'CurrentUser',
    
    [string]$PythonPath,
    
    [switch]$SkipPython,
    
    [switch]$Force
)

# Import existing logging (admin-friendly, no hardcoded paths)
$scriptRoot = $PSScriptRoot

# Bootstrap function for initial logging before modules are configured
function Write-CustomLog { 
    param($Message, $Level = 'INFO') 
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" 
}

Write-CustomLog "Starting OpenTofu Lab Automation environment setup" -Level INFO
Write-CustomLog "Installation scope: $InstallScope" -Level INFO

# Detect system information
$cpuCores = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum
$totalLogicalProcessors = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

Write-CustomLog "System Information:" -Level INFO
Write-CustomLog "  CPU Cores: $cpuCores" -Level INFO
Write-CustomLog "  Logical Processors: $totalLogicalProcessors" -Level INFO
Write-CustomLog "  PowerShell Version: $($PSVersionTable.PSVersion)" -Level INFO
Write-CustomLog "  OS: $($PSVersionTable.OS)" -Level INFO

# Set environment variables for multiprocessing
$env:LAB_CPU_CORES = $cpuCores
$env:LAB_LOGICAL_PROCESSORS = $totalLogicalProcessors
$env:LAB_MAX_PARALLEL_JOBS = [Math]::Min($cpuCores, 4)  # Cap at 4 for stability

Write-CustomLog "Setting multiprocessing environment variables:" -Level INFO
Write-CustomLog "  LAB_CPU_CORES: $env:LAB_CPU_CORES" -Level INFO
Write-CustomLog "  LAB_LOGICAL_PROCESSORS: $env:LAB_LOGICAL_PROCESSORS" -Level INFO
Write-CustomLog "  LAB_MAX_PARALLEL_JOBS: $env:LAB_MAX_PARALLEL_JOBS" -Level INFO

# Set up project environment variables for admin-friendly module discovery
Write-CustomLog "Configuring project environment for module discovery..." -Level INFO

# Set PROJECT_ROOT
$env:PROJECT_ROOT = $scriptRoot
[Environment]::SetEnvironmentVariable('PROJECT_ROOT', $scriptRoot, 'User')
Write-CustomLog "  PROJECT_ROOT: $env:PROJECT_ROOT" -Level INFO

# Set PWSH_MODULES_PATH to our project modules (relative path, no hardcoding)
$projectModulesPath = Join-Path $scriptRoot "src/pwsh/modules"
$env:PWSH_MODULES_PATH = $projectModulesPath
[Environment]::SetEnvironmentVariable('PWSH_MODULES_PATH', $projectModulesPath, 'User')
Write-CustomLog "  PWSH_MODULES_PATH: $env:PWSH_MODULES_PATH" -Level INFO

# Add project modules to PSModulePath so they can be imported by name (PERMANENTLY)
$currentPSModulePath = $env:PSModulePath
if ($currentPSModulePath -notlike "*$projectModulesPath*") {
    $separator = if ($IsWindows) { ';' } else { ':' }
    $newPSModulePath = "$projectModulesPath$separator$currentPSModulePath"
    $env:PSModulePath = $newPSModulePath
    [Environment]::SetEnvironmentVariable('PSModulePath', $newPSModulePath, 'User')
    Write-CustomLog "  Added project modules to PSModulePath (permanently)" -Level INFO
} else {
    Write-CustomLog "  Project modules already in PSModulePath" -Level INFO
}

# Required PowerShell modules
$requiredModules = @(
    @{ Name = 'Pester'; MinimumVersion = '5.0.0' },
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.18.0' },
    @{ Name = 'PowerShellGet'; MinimumVersion = '2.0.0' },
    @{ Name = 'PackageManagement'; MinimumVersion = '1.4.0' }
)

Write-CustomLog "Installing PowerShell modules..." -Level INFO

foreach ($module in $requiredModules) {
    $moduleName = $module.Name
    $minVersion = $module.MinimumVersion
    
    try {
        $installedModule = Get-Module -Name $moduleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($installedModule -and $installedModule.Version -ge [Version]$minVersion -and -not $Force) {
            Write-CustomLog "Module $moduleName (v$($installedModule.Version)) already installed and meets minimum requirements" -Level INFO
        } else {
            Write-CustomLog "Installing module: $moduleName (minimum version: $minVersion)" -Level INFO
            
            $installParams = @{
                Name = $moduleName
                Scope = $InstallScope
                Force = $Force
                AllowClobber = $true
            }
            
            if ($minVersion) {
                $installParams.MinimumVersion = $minVersion
            }
            
            Install-Module @installParams
            Write-CustomLog "Successfully installed $moduleName" -Level INFO
        }
    }
    catch {
        Write-CustomLog "Failed to install module $moduleName`: $_" -Level ERROR
        throw
    }
}

# Python dependencies setup
if (-not $SkipPython) {
    Write-CustomLog "Setting up Python environment..." -Level INFO
    
    # Auto-detect Python if not provided
    if (-not $PythonPath) {
        $pythonCommands = @('python', 'python3', 'py')
        foreach ($cmd in $pythonCommands) {
            try {
                $version = & $cmd --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $PythonPath = $cmd
                    Write-CustomLog "Detected Python: $cmd ($version)" -Level INFO
                    break
                }
            }
            catch {
                # Continue to next command
            }
        }
    }
    
    if (-not $PythonPath) {
        Write-CustomLog "Python not found. Please install Python or specify -PythonPath" -Level ERROR
        throw "Python not found"
    }
    
    # Check for virtual environment
    $venvPath = Join-Path $scriptRoot ".venv"
    if (-not (Test-Path $venvPath) -or $Force) {
        Write-CustomLog "Creating Python virtual environment..." -Level INFO
        & $PythonPath -m venv $venvPath
    } else {
        Write-CustomLog "Virtual environment already exists" -Level INFO
    }
    
    # Activate virtual environment and install dependencies
    $activateScript = if ($IsWindows) { 
        Join-Path $venvPath "Scripts/Activate.ps1" 
    } else { 
        Join-Path $venvPath "bin/Activate.ps1" 
    }
    
    $pythonExe = if ($IsWindows) {
        Join-Path $venvPath "Scripts/python.exe"
    } else {
        Join-Path $venvPath "bin/python"
    }
    
    if (Test-Path $activateScript) {
        Write-CustomLog "Installing Python dependencies..." -Level INFO
        
        $pythonDependencies = @(
            'pytest>=8.0.0',
            'flake8>=6.0.0',
            'pylint>=3.0.0',
            'black>=23.0.0',
            'isort>=5.0.0',
            'coverage>=7.0.0',
            'pytest-xdist>=3.0.0',  # For parallel test execution
            'pytest-cov>=4.0.0'     # For coverage reporting
        )
        
        foreach ($package in $pythonDependencies) {
            Write-CustomLog "Installing Python package: $package" -Level INFO
            & $pythonExe -m pip install $package
            if ($LASTEXITCODE -ne 0) {
                Write-CustomLog "Failed to install $package" -Level WARN
            }
        }
        
        Write-CustomLog "Python environment setup complete" -Level INFO
    } else {
        Write-CustomLog "Failed to find activation script at $activateScript" -Level ERROR
    }
}

# Create linting configuration files
Write-CustomLog "Creating linting configuration files..." -Level INFO

# PSScriptAnalyzer settings (scientific, professional output)
$psAnalyzerSettings = @"
@{
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',  # We use Write-Host for colored console output
        'PSUseShouldProcessForStateChangingFunctions'  # Not all functions need this
    )
    IncludeDefaultRules = `$true
    Severity = @('Error', 'Warning', 'Information')
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = `$true
            OnSameLine = `$true
            NewLineAfter = `$true
            IgnoreOneLineBlock = `$true
        }
        PSPlaceCloseBrace = @{
            Enable = `$true
            NewLineAfter = `$false
            IgnoreOneLineBlock = `$true
            NoEmptyLineBefore = `$false
        }
        PSUseConsistentIndentation = @{
            Enable = `$true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }
        PSUseConsistentWhitespace = @{
            Enable = `$true
            CheckInnerBrace = `$true
            CheckOpenBrace = `$true
            CheckOpenParen = `$true
            CheckOperator = `$true
            CheckPipe = `$true
            CheckSeparator = `$true
        }
    }
}
"@

$psAnalyzerPath = Join-Path $scriptRoot "PSScriptAnalyzerSettings.psd1"
$psAnalyzerSettings | Out-File -FilePath $psAnalyzerPath -Encoding UTF8 -Force
Write-CustomLog "Created PSScriptAnalyzer settings: $psAnalyzerPath" -Level INFO

# Flake8 configuration for Python
$flake8Config = @"
[flake8]
max-line-length = 100
extend-ignore = E203, W503
exclude = 
    .git,
    __pycache__,
    .venv,
    .pytest_cache,
    build,
    dist
per-file-ignores =
    __init__.py:F401
"@

$flake8Path = Join-Path $scriptRoot ".flake8"
$flake8Config | Out-File -FilePath $flake8Path -Encoding UTF8 -Force
Write-CustomLog "Created Flake8 configuration: $flake8Path" -Level INFO

# Pylint configuration
$pylintConfig = @"
[MASTER]
load-plugins=

[MESSAGES CONTROL]
disable=C0103,R0903,W0613

[FORMAT]
max-line-length=100
indent-string='    '

[DESIGN]
max-args=10
max-locals=20
max-returns=10
max-branches=15
max-statements=60
"@

$pylintPath = Join-Path $scriptRoot ".pylintrc"
$pylintConfig | Out-File -FilePath $pylintPath -Encoding UTF8 -Force
Write-CustomLog "Created Pylint configuration: $pylintPath" -Level INFO

# Create multiprocessing test runner configuration
$testConfig = @"
@{
    # CPU-based parallel execution settings
    MaxParallelJobs = $env:LAB_MAX_PARALLEL_JOBS
    CpuCores = $env:LAB_CPU_CORES
    LogicalProcessors = $env:LAB_LOGICAL_PROCESSORS
    
    # Test execution settings
    PesterSettings = @{
        Run = @{
            Exit = `$false
            PassThru = `$true
        }
        Output = @{
            Verbosity = 'Normal'
        }
        TestResult = @{
            Enabled = `$true
            OutputFormat = 'NUnitXml'
            OutputPath = 'tests/results/pester-results.xml'
        }
        CodeCoverage = @{
            Enabled = `$true
            OutputFormat = 'JaCoCo'
            OutputPath = 'tests/results/pester-coverage.xml'
            Path = @('src/pwsh/**/*.ps1', 'src/pwsh/**/*.psm1')
        }
    }
    
    # Python test settings
    PytestSettings = @{
        Parallel = @{
            Workers = $env:LAB_MAX_PARALLEL_JOBS
            Distribution = 'loadscope'
        }
        Coverage = @{
            Source = 'src/python'
            Format = @('xml', 'html', 'term')
            OutputDir = 'tests/results'
        }
        Output = @{
            JunitXml = 'tests/results/pytest-results.xml'
            Verbosity = 'normal'
        }
    }
    
    # Linting settings
    LintingSettings = @{
        PSScriptAnalyzer = @{
            Path = @('src/pwsh/**/*.ps1', 'src/pwsh/**/*.psm1')
            Settings = 'PSScriptAnalyzerSettings.psd1'
            Severity = @('Error', 'Warning')
            Recurse = `$true
        }
        Python = @{
            Flake8 = @{
                Path = 'src/python'
                Config = '.flake8'
                MaxComplexity = 10
            }
            Pylint = @{
                Path = 'src/python'
                Config = '.pylintrc'
                FailUnder = 8.0
            }
            Black = @{
                Path = 'src/python'
                LineLength = 100
                Check = `$true
            }
        }
    }
}
"@

$testConfigPath = Join-Path $scriptRoot "TestConfiguration.psd1"
$testConfig | Out-File -FilePath $testConfigPath -Encoding UTF8 -Force
Write-CustomLog "Created test configuration: $testConfigPath" -Level INFO

# Verify installation
Write-CustomLog "Verifying installation..." -Level INFO

# Test PowerShell modules
foreach ($module in $requiredModules) {
    try {
        Import-Module $module.Name -Force
        Write-CustomLog "Successfully verified module: $($module.Name)" -Level INFO
    }
    catch {
        Write-CustomLog "Failed to import module $($module.Name): $_" -Level ERROR
    }
}

# Test project modules can be imported by name (admin-friendly)
Write-CustomLog "Testing project module discovery (admin-friendly imports)..." -Level INFO

# Get actual modules from the filesystem
$actualModules = @()
if (Test-Path $projectModulesPath) {
    $moduleDirectories = Get-ChildItem -Path $projectModulesPath -Directory
    foreach ($moduleDir in $moduleDirectories) {
        $psd1File = Join-Path $moduleDir.FullName "$($moduleDir.Name).psd1"
        if (Test-Path $psd1File) {
            $actualModules += $moduleDir.Name
        }
    }
}

Write-CustomLog "Found $($actualModules.Count) project modules: $($actualModules -join ', ')" -Level INFO

$moduleTestResults = @{}
foreach ($module in $actualModules) {
    try {
        # Remove if already loaded to test fresh import
        if (Get-Module $module) {
            Remove-Module $module -Force
        }
        
        # Test import by module name (no hardcoded paths!)
        Import-Module $module -Force -ErrorAction Stop
        Write-CustomLog "[PASS] Module '$module' imports successfully by name" -Level INFO
        $moduleTestResults[$module] = "SUCCESS"
        
        # Test key functions are available
        $moduleCommands = Get-Command -Module $module -ErrorAction SilentlyContinue
        if ($moduleCommands.Count -gt 0) {
            Write-CustomLog "  -> Exported $($moduleCommands.Count) commands" -Level INFO
        }
    }
    catch {
        Write-CustomLog "[FAIL] Module '$module' failed to import: $($_.Exception.Message)" -Level WARN
        $moduleTestResults[$module] = "FAILED: $($_.Exception.Message)"
    }
}

# Summary of module discovery test
$successCount = ($moduleTestResults.Values | Where-Object { $_ -eq "SUCCESS" }).Count
$totalCount = $moduleTestResults.Count
Write-CustomLog "Project module discovery test: $successCount/$totalCount modules can be imported by name" -Level INFO

if ($successCount -eq $totalCount) {
    Write-CustomLog "[SUCCESS] All project modules are discoverable without hardcoded paths" -Level INFO
    Write-CustomLog "Admins can now use: Import-Module <ModuleName> -Force" -Level INFO
} else {
    Write-CustomLog "[WARNING] Some project modules need attention:" -Level WARN
    foreach ($moduleResult in $moduleTestResults.GetEnumerator()) {
        if ($moduleResult.Value -ne "SUCCESS") {
            Write-CustomLog "  $($moduleResult.Key): $($moduleResult.Value)" -Level WARN
        }
    }
    Write-CustomLog "You may need to restart PowerShell to pick up PSModulePath changes" -Level WARN
}

# Test Python environment
if (-not $SkipPython -and (Test-Path $pythonExe)) {
    try {
        $pythonVersion = & $pythonExe --version
        Write-CustomLog "Python verification: $pythonVersion" -Level INFO
        
        $pipList = & $pythonExe -m pip list --format=freeze
        $installedPackages = $pipList | Where-Object { $_ -match '^(pytest|flake8|pylint|black|isort|coverage)' }
        Write-CustomLog "Installed Python packages: $($installedPackages.Count) packages" -Level INFO
    }
    catch {
        Write-CustomLog "Python verification failed: $_" -Level WARN
    }
}

Write-CustomLog "Environment setup completed successfully" -Level INFO
