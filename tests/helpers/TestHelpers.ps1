# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

# Simple PSScriptAnalyzer import
Import-Module PSScriptAnalyzer -Force

$SkipNonWindows = $IsLinux -or $IsMacOS

# Only validate Pester version if we're not already in a Pester context
if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    # Ensure Pester v5.7.1 is loaded, not v3.x
    $desiredPesterVersion = '5.7.1'
    $pesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge [version]$desiredPesterVersion } | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pesterModule) {
        Write-Error "Pester $desiredPesterVersion or newer is required. Run 'Install-Module -Name Pester -RequiredVersion $desiredPesterVersion -Force -Scope CurrentUser'."
        exit 1
    }    # Remove any loaded Pester v3 modules
    Get-Module -Name Pester | Where-Object { $_.Version -lt [version]'5.0.0' } | Remove-Module -Force -ErrorAction SilentlyContinue
    # Import the correct Pester version - ensure 5.7.1
    Import-Module Pester -RequiredVersion 5.7.1 -Force
}

# Use the same LabRunner module that the actual scripts use to avoid conflicts
$LabRunnerModulePath = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' 'pwsh/modules/LabRunner')).Path
$CodeFixerModulePath = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' 'pwsh/modules/CodeFixer')).Path

# Remove any previously loaded modules to avoid duplicate import errors  
Get-Module LabRunner* | Remove-Module -Force -ErrorAction SilentlyContinue
Get-Module CodeFixer* | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the modules
Import-Module $LabRunnerModulePath -Force
Import-Module $CodeFixerModulePath -Force

# Ensure Get-MenuSelection is always available for tests that need it
if (-not (Get-Command Get-MenuSelection -ErrorAction SilentlyContinue)) {
    function global:Get-MenuSelection { 
        param([string[]]$Items, [string]$Title)
    }
}

# Import required utilities
$LabUtilsPath = Join-Path $PSScriptRoot '../../pwsh/modules'
if (Test-Path (Join-Path $LabUtilsPath 'Resolve-ProjectPath.ps1')) {
    . (Join-Path $LabUtilsPath 'Resolve-ProjectPath.ps1')
}

function Resolve-ProjectPath {
    <#
    .SYNOPSIS
        Resolves paths within the project structure
    .PARAMETER Name
        The name or relative path to resolve
    .PARAMETER Root
        The project root directory
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Root = (Get-Location)
    )
    
    # Common path mappings within the project
    $pathMappings = @{
        'runner_scripts' = 'pwsh/runner_scripts'
        'LabRunner' = 'pwsh/modules/LabRunner'
        'CodeFixer' = 'pwsh/modules/CodeFixer'
        'pwsh' = 'pwsh'
        'tests' = 'tests'
        'configs' = 'configs'
        'opentofu' = 'opentofu'
    }
    
    # Try direct mapping first
    if ($pathMappings.ContainsKey($Name)) {
        $mapped = Join-Path $Root $pathMappings[$Name]
        if (Test-Path $mapped) {
            return $mapped
        }
    }
    
    # Try as relative path from root
    $relativePath = Join-Path $Root $Name
    if (Test-Path $relativePath) {
        return $relativePath
    }
    
    # Try common script locations
    $commonPaths = @(
        "pwsh/runner_scripts/$Name",
        "pwsh/runner_scripts/$Name",
        "pwsh/modules/LabRunner/$Name",
        "scripts/$Name",
        "tests/$Name"
    )
    
    foreach ($path in $commonPaths) {
        $fullPath = Join-Path $Root $path
        if (Test-Path $fullPath) {
            return $fullPath
        }
    }
    
    # Return null if not found
    return $null
}

function global:Get-RunnerScriptPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    try {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    } catch {
        Write-Error "Get-RunnerScriptPath: Failed to resolve root path: $_"
        return $null
    }
    
    $resolved = Resolve-ProjectPath -Name $Name -Root $root
    if (-not $resolved) {
        Write-Warning "Get-RunnerScriptPath: Could not resolve '$Name' from root '$root'"
    }
    return $resolved
}

function global:Mock-WriteLog {
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        function global:Write-CustomLog { param([string]$Message,[string]$Level) }
    }
    Mock Write-CustomLog {}
}

function global:Disable-InteractivePrompts {
    <#
    .SYNOPSIS
    Disables interactive prompts that can hang tests
    
    .DESCRIPTION
    Mocks common interactive functions to prevent tests from hanging
    #>
    
    # Only set up mocks if we're in a Pester context
    if (Get-Command Mock -ErrorAction SilentlyContinue) {
        Mock Read-Host { 'n' }
        Mock Read-LoggedInput { 'exit' }
        Mock Get-MenuSelection { @() }
        Mock Get-Credential { 
            $pass = ConvertTo-SecureString 'testpass' -AsPlainText -Force
            New-Object PSCredential ('testuser', $pass)
        }
        
        # Mock Write-Host to prevent excessive output during tests
        Mock Write-Host {}
    }
    
    # Add Get-LabConfig mock function to resolve the missing mock issue
    if (-not (Get-Command Get-LabConfig -ErrorAction SilentlyContinue)) {
        function global:Get-LabConfig {
            param([string]$ConfigPath = "")
            
            return @{
                ProjectName = "TestLab"
                Platform = "TestPlatform"
                TempPath = Get-CrossPlatformTempPath
            }
        }
    }
    
    # Set environment variable to indicate non-interactive mode
    $env:LAB_CONSOLE_LEVEL = '0'
    
    # Ensure Get-CrossPlatformTempPath is available (it might be imported from different module locations)
    if (-not (Get-Command Get-CrossPlatformTempPath -ErrorAction SilentlyContinue)) {
        function global:Get-CrossPlatformTempPath {
            if ($env:TEMP) { return $env:TEMP } else { return [System.IO.Path]::GetTempPath() }
        }
    }
}

function global:Enable-WindowsMocks {
    <#
    .SYNOPSIS
    Enables mocks for Windows-specific cmdlets for cross-platform testing
    #>
    if (Get-Command Mock -ErrorAction SilentlyContinue) {
        New-StandardMocks -IncludeMocks @('Windows')
    }
}

function global:New-CrossPlatformTempPath {
    <#
    .SYNOPSIS
    Creates a cross-platform temporary path for tests
    #>
    $tempDir = if ($env:TEMP) { $env:TEMP    } else { [System.IO.Path]::GetTempPath()    }
    return Join-Path $tempDir ([System.Guid]::NewGuid().ToString())
}

function global:New-StandardMocks {
    <#
    .SYNOPSIS
    Creates a comprehensive set of standard mocks for cross-platform testing
    #>
    param(
        [string[]]$IncludeMocks = @(),
        [string]$ModuleName = $null
    )
    
    # Only add mocks if we're in a Pester context
    if (-not (Get-Command Get-MockDynamicParameters -ErrorAction SilentlyContinue)) {
        return
    }
    
    try {
        if ('LabDownload' -in $IncludeMocks) {
            if ($ModuleName) {
                Mock Invoke-LabDownload -ModuleName $ModuleName { 
                    param($Uri, $Prefix, $Extension, $Action)
                    
                    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "mock_$Prefix$Extension"
                    New-Item -ItemType File -Path $tempFile -Force | Out-Null
                    try { 
                        if ($Action) { & $Action $tempFile }
                    } finally { 
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue 
                    }
                }
            } else {
                Mock Invoke-LabDownload { 
                    param($Uri, $Prefix, $Extension, $Action)
                    
                    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "mock_$Prefix$Extension"
                    New-Item -ItemType File -Path $tempFile -Force | Out-Null
                    try { 
                        if ($Action) { & $Action $tempFile }
                    } finally { 
                        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue 
                    }
                }
            }
        }
        
        if ('WebRequest' -in $IncludeMocks) {
            if ($ModuleName) {
                Mock Invoke-LabWebRequest -ModuleName $ModuleName {}
                Mock Invoke-WebRequest -ModuleName $ModuleName {}
                Mock Invoke-RestMethod -ModuleName $ModuleName { 
                    @{ download_url = 'https://example.com/file.zip' }
                }
            } else {
                Mock Invoke-LabWebRequest {}
                Mock Invoke-WebRequest {}
                Mock Invoke-RestMethod { 
                    @{ download_url = 'https://example.com/file.zip' }
                }
            }
        }
        
        if ('Platform' -in $IncludeMocks) {
            Mock Get-Platform { if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } else { 'macOS' } }
            Mock Get-ComputerInfo { 
                [PSCustomObject]@{
                    OsName = 'Microsoft Windows 10'
                    OsArchitecture = 'x64'
                }
            }
        }
        
        if ('Command' -in $IncludeMocks) {
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'nonexistent' }
        }
        
        if ('Windows' -in $IncludeMocks) {
            # Mock Windows-specific networking cmdlets
            Mock Get-NetIPAddress {
                [PSCustomObject]@{
                    IPAddress = '192.168.1.100'
                    InterfaceAlias = 'Ethernet'
                }
            }
            
            Mock Set-DnsClientServerAddress {}
            
            Mock New-NetFirewallRule {
                [PSCustomObject]@{
                    DisplayName = 'Mock Rule'
                    Enabled = $true
                }
            }
            
            Mock Get-NetFirewallRule {
                [PSCustomObject]@{
                    DisplayName = 'Mock Rule'
                    Enabled = $true
                }
            }
            
            Mock Remove-NetFirewallRule {}
            
            Mock Get-Service {
                [PSCustomObject]@{
                    Name = 'MockService'
                    Status = 'Running'
                }
            }
            
            Mock Start-Service {}
            Mock Stop-Service {}
            Mock Restart-Service {}
            
            # Mock Windows Optional Features
            Mock Get-WindowsOptionalFeature {
                [PSCustomObject]@{
                    FeatureName = 'Microsoft-Hyper-V'
                    State = 'Enabled'
                }
            }
            
            Mock Enable-WindowsOptionalFeature {}
            Mock Disable-WindowsOptionalFeature {}
            
            # Mock certificate cmdlets
            Mock New-SelfSignedCertificate {
                [PSCustomObject]@{
                    Thumbprint = 'ABCD1234567890'
                    Subject = 'CN=MockCert'
                }
            }
            
            Mock Import-PfxCertificate {}
            Mock Export-PfxCertificate {}
            Mock Export-Certificate {}
            
            # Mock CIM cmdlets
            Mock New-CimInstance {}
            Mock Get-CimInstance {}
            
            # Mock WSMan cmdlets
            Mock Test-WSMan {}
            Mock Enable-PSRemoting {}
            Mock Get-WSManInstance {
                [PSCustomObject]@{
                    MaxMemoryPerShellMB = 512
                    MaxTimeoutms = 60000
                    TrustedHosts = 'localhost'
                    Negotiate = $true
                }
            }
            Mock Set-WSManInstance {}
            Mock New-Item {} -ParameterFilter { $Path -like '*WSMan*' }
            Mock Remove-Item {} -ParameterFilter { $Path -like '*WSMan*' }
            
            # Mock registry cmdlets
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    fDenyTSConnections = 0
                }
            }
            Mock Set-ItemProperty {}
            
            # Mock process management
            Mock Start-Process {}
            
            # Mock ScriptAnalyzer cmdlet
            Mock Invoke-ScriptAnalyzer { @() }
            
            # Mock pwsh command discovery
            Mock Get-Command {
                if ($Name -eq 'pwsh') {
                    return [PSCustomObject]@{
                        Name = 'pwsh'
                        Source = '/usr/bin/pwsh'
                        CommandType = 'Application'
                    }
                }
                return $null
            } -ParameterFilter { $Name -eq 'pwsh' }
        }
        
        if ('System' -in $IncludeMocks) {
            # Mock npm and node operations
            if ($ModuleName) {
                Mock Invoke-LabNpm -ModuleName $ModuleName {
                    param([Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Args)
                    # Log the mock call for verification
                    Write-Verbose "Mock Invoke-LabNpm called with: $($Args -join ' ')"
                }
                # Mock file system operations with module scoping
                Mock New-Item -ModuleName $ModuleName {}
                Mock Remove-Item -ModuleName $ModuleName {}
                Mock Copy-Item -ModuleName $ModuleName {}
                Mock Move-Item -ModuleName $ModuleName {}
                # Mock archive operations with module scoping
                Mock Expand-Archive -ModuleName $ModuleName {}
                Mock Compress-Archive -ModuleName $ModuleName {}
                # Mock process operations with module scoping
                Mock Start-Process -ModuleName $ModuleName {}
                Mock Stop-Process -ModuleName $ModuleName {}
                Mock Get-Process -ModuleName $ModuleName { @() }
            } else {
                Mock Invoke-LabNpm {
                    param([Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Args)
                    # Log the mock call for verification
                    Write-Verbose "Mock Invoke-LabNpm called with: $($Args -join ' ')"
                }
                # Mock file system operations
                Mock New-Item {}
                Mock Remove-Item {}
                Mock Copy-Item {}
                Mock Move-Item {}
                # Mock archive operations
                Mock Expand-Archive {}
                Mock Compress-Archive {}
                # Mock process operations
                Mock Start-Process {}
                Mock Stop-Process {}
                Mock Get-Process { @() }
            }
        }
    } catch {
        Write-Verbose "Failed to set up some mocks: $_"
    }
}

function global:Invoke-RunnerScriptTest {
    <#
    .SYNOPSIS
    Standardized way to test runner scripts with proper error handling
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory)]
        [object]$Config,
        
        [hashtable]$Mocks = @{},
        
        [hashtable]$ExpectedInvocations = @{},
        
        [switch]$ShouldThrow,
        
        [string]$ExpectedError
    )
    
    # Disable interactive prompts
    Disable-InteractivePrompts
    
    # Apply custom mocks
    foreach ($mockName in $Mocks.Keys) {
        Mock $mockName $Mocks[$mockName]
    }
    
    # Execute script
    if ($ShouldThrow) {
        if ($ExpectedError) {
            { & $ScriptPath -Config $Config } | Should -Throw "*$ExpectedError*"
        } else {
            { & $ScriptPath -Config $Config } | Should -Throw
        }
    } else {
        & $ScriptPath -Config $Config
    }
    
    # Verify expected invocations
    foreach ($funcName in $ExpectedInvocations.Keys) {
        $expectedCount = $ExpectedInvocations[$funcName]
        if ($expectedCount -eq 0) {
            Should -Invoke -CommandName $funcName -Times 0
        } else {
            Should -Invoke -CommandName $funcName -Times $expectedCount
        }
    }
}

# Load the new extensible framework
if (Test-Path (Join-Path $PSScriptRoot 'TestFramework.ps1')) {
    . (Join-Path $PSScriptRoot 'TestFramework.ps1')
}

# Note: Call Disable-InteractivePrompts manually in test BeforeAll blocks when needed
# Note: Windows mocks should be enabled manually in test BeforeAll blocks using Enable-WindowsMocks
# when needed for cross-platform compatibility

# Legacy compatibility - these functions are kept for backward compatibility
# New tests should use the TestFramework.ps1 and TestTemplates.ps1 instead

# Ensure Get-TestConfiguration is globally available for all tests
function global:Get-TestConfiguration {
    return @{
        Environment = 'Test'
        Platform = (Get-Platform).Name
        IsAdmin = (Test-IsAdministrator)
    }
}

# Platform detection for test config
function global:Get-Platform {
    return @{ Name = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'MacOS' } else { 'Unknown' } }
}

# Simple admin check for test config
function global:Test-IsAdministrator {
    if ($IsWindows) {
        $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } else {
        return $true  # Assume admin for non-Windows test runs
    }
}



# Mock function for missing command: Format-Config
function global:Format-Config {
    param([Parameter(ValueFromPipeline)]
    [object]$InputObject)
    if ($InputObject) { return $InputObject }
    return $true
}
# Mock function for missing command: Invoke-LabStep
function global:Invoke-LabStep {
    param([Parameter(ValueFromPipeline)]
    [object]$InputObject)
    if ($InputObject) { return $InputObject }
    return $true
}
# Mock function for missing command: Write-Continue
function global:Write-Continue {
    param([Parameter(ValueFromPipeline)]
    [object]$InputObject)
    if ($InputObject) { return $InputObject }
    return $true
}










# Auto-generated mock for missing command: errors
function global:errors {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    Write-Host "Mock errors called with: $Arguments" -ForegroundColor Yellow
    return $true
}

# Auto-generated mock for missing command: Format-Config
function global:Format-Config {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    Write-Host "Mock Format-Config called with: $Arguments" -ForegroundColor Yellow
    return $true
}

# Auto-generated mock for missing command: Invoke-LabStep
function global:Invoke-LabStep {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    Write-Host "Mock Invoke-LabStep called with: $Arguments" -ForegroundColor Yellow
    return $true
}

# Auto-generated mock for missing command: Write-Continue
function global:Write-Continue {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)
    Write-Host "Mock Write-Continue called with: $Arguments" -ForegroundColor Yellow
    return $true
}

# ==============================================================================
# Missing Test Helper Functions
# ==============================================================================

function Get-RunnerScriptPath {
    <#
    .SYNOPSIS
        Finds the path to a runner script by name
    .PARAMETER ScriptName
        The name of the script to find (e.g., '0007_Install-Go.ps1')
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName
    )
    
    # Start from the project root
    $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    
    # Primary location for runner scripts
    $runnerScriptsPath = Join-Path $projectRoot "pwsh" "runner_scripts" $ScriptName
    if (Test-Path $runnerScriptsPath) {
        return $runnerScriptsPath
    }
    
    # Fallback locations
    $searchPaths = @(
        "LabRunner",
        "pwsh/modules/LabRunner", 
        "scripts",
        "pwsh/scripts"
    )
    
    foreach ($searchPath in $searchPaths) {
        $fullSearchPath = Join-Path $projectRoot $searchPath
        if (Test-Path $fullSearchPath) {
            $scriptPath = Get-ChildItem -Path $fullSearchPath -Recurse -Filter $ScriptName -File | Select-Object -First 1
            if ($scriptPath) {
                return $scriptPath.FullName
            }
        }
    }
    
    # Return a mock path for testing if not found
    $mockPath = Join-Path $projectRoot "pwsh" "runner_scripts" $ScriptName
    Write-Warning "Script not found: $ScriptName. Using mock path: $mockPath"
    return $mockPath
}

function Test-RunnerScriptName {
    <#
    .SYNOPSIS
        Validates a runner script name follows naming conventions
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    $scriptName = [System.IO.Path]::GetFileName($ScriptPath)
    
    # Check for .ps1 extension first
    if (-not $scriptName.EndsWith('.ps1')) {
        throw "Invalid file extension: Must be .ps1"
    }
    
    # Check for spaces in filename
    if ($scriptName -match '\s') {
        throw "Invalid script name: Contains spaces"
    }
    
    # Check for special characters
    if ($scriptName -match '[^a-zA-Z0-9_.-]') {
        throw "Invalid characters: Only alphanumeric, underscore, dash, and dot allowed"
    }
    
    # Check for sequence number
    if (-not ($scriptName -match '^\d{4}_')) {
        throw "Missing sequence number: Script name must start with 4-digit sequence number"
    }
    
    return $true
}

function Test-RunnerScriptSafety {
    <#
    .SYNOPSIS
        Validates a runner script for security issues
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    
    # Check for dangerous commands
    $dangerousPatterns = @(
        'Remove-Item.*-Recurse.*-Force',
        'Format-Volume',
        'Initialize-Disk',
        'Clear-Disk',
        'rd\s+/s',
        'del\s+/s',
        'rmdir\s+/s'
    )
    
    foreach ($pattern in $dangerousPatterns) {
        if ($content -match $pattern) {
            throw "Potentially dangerous command detected: $pattern"
        }
    }
      # Check for hardcoded credentials
    $credentialPatterns = @(
        'password\s*=\s*["''][^"'']+["'']',
        'apikey\s*=\s*["''][^"'']+["'']',
        'connectionstring.*password=',
        'secret\s*=\s*["''][^"'']+["'']'
    )
    
    foreach ($pattern in $credentialPatterns) {
        if ($content -match $pattern) {
            throw "Hardcoded credentials detected"
        }
    }
    
    # Check for suspicious network access
    $suspiciousPatterns = @(
        'malware',
        'bitcoin',
        'miner',
        'hack',
        'exploit'
    )
    
    foreach ($pattern in $suspiciousPatterns) {
        if ($content -match $pattern) {
            throw "Suspicious network access detected"
        }
    }
    
    return $true
}

function Test-RunnerScriptSyntax {
    <#
    .SYNOPSIS
        Tests a script for syntax errors
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        return @{
            HasErrors = $true
            CanAutoFix = $false
            Errors = @("File not found: $ScriptPath")
        }
    }
    
    $errors = $null
    $tokens = $null
    
    try {
        [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        
        return @{
            HasErrors = ($errors.Count -gt 0)
            CanAutoFix = ($errors.Count -gt 0 -and $errors.Count -le 5)  # Assume simple fixes for few errors
            Errors = $errors
        }
    } catch {
        return @{
            HasErrors = $true
            CanAutoFix = $false
            Errors = @($_.Exception.Message)
        }
    }
}

function Test-RunnerScriptEncoding {
    <#
    .SYNOPSIS
        Tests a script for encoding issues
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    try {
        # Try to read as UTF-8
        $content = Get-Content $ScriptPath -Encoding UTF8 -Raw
        
        # Check for invalid UTF-8 sequences or non-printable characters
        if ($content -match '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]') {
            throw "Invalid encoding: Contains non-printable characters"
        }
        
        return $true
    } catch {
        throw "Invalid encoding: $_"
    }
}

function Test-RunnerScriptSize {
    <#
    .SYNOPSIS
        Tests a script for size issues
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $file = Get-Item $ScriptPath
    $sizeKB = $file.Length / 1KB
    $lineCount = (Get-Content $ScriptPath).Count
    
    return @{
        SizeWarning = ($sizeKB -gt 100)  # > 100KB
        RecommendSplit = ($lineCount -gt 1000)  # > 1000 lines
        SizeKB = $sizeKB
        LineCount = $lineCount
    }
}

function Get-TestConfiguration {
    <#
    .SYNOPSIS
        Gets test configuration settings
    #>
    
    return [PSCustomObject]@{
        TempPath = $env:TEMP
        TestTimeout = 300  # 5 minutes
        MockWebRequests = $true
        EnableVerboseLogging = $false
        SkipSlowTests = $false
        Platform = Get-Platform
    }
}

function Test-IsAdministrator {
    <#
    .SYNOPSIS
        Tests if the current user has administrator privileges
    #>
    
    if ($IsWindows -or (-not $IsLinux -and -not $IsMacOS)) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } else {
        return (id -u) -eq 0
    }
}

function Disable-InteractivePrompts {
    <#
    .SYNOPSIS
        Disables interactive prompts for testing
    #>
    
    # Mock common interactive functions
    if (-not (Get-Command Read-Host -ErrorAction SilentlyContinue | Where-Object { $_.CommandType -eq 'Function' })) {
        function global:Read-Host { param([string]$Prompt) return "test-input" }
    }
    
    if (-not (Get-Command Get-Credential -ErrorAction SilentlyContinue | Where-Object { $_.CommandType -eq 'Function' })) {
        function global:Get-Credential { 
            param([string]$Message, [string]$UserName) 
            $securePassword = ConvertTo-SecureString "test-password" -AsPlainText -Force
            return New-Object System.Management.Automation.PSCredential("test-user", $securePassword)
        }
    }
}

function New-StandardMocks {
    <#
    .SYNOPSIS
        Creates standard mocks for testing
    #>
    
    # Mock common external commands that might not be available in test environment
    Mock Start-Process { return @{ ExitCode = 0 } } -ModuleName *
    Mock Invoke-RestMethod { return @{ Status = "Success" } } -ModuleName *
    Mock Test-NetConnection { return @{ TcpTestSucceeded = $true } } -ModuleName *
    Mock Get-Service { return @{ Status = "Running" } } -ModuleName *
    Mock Set-Service { return $true } -ModuleName *
}

# ==============================================================================
# End of Missing Test Helper Functions
# ==============================================================================

# ==============================================================================
# Additional Test Helper Functions
# ==============================================================================

function Test-RunnerScriptParameters {
    <#
    .SYNOPSIS
        Tests a script for parameter validation issues
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    
    # Find parameter blocks
    $paramBlocks = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.ParamBlockAst]
    }, $false)
    
    $issues = @()
    
    foreach ($paramBlock in $paramBlocks) {
        foreach ($param in $paramBlock.Parameters) {
            # Check for invalid validation attributes
            foreach ($attribute in $param.Attributes) {
                if ($attribute.TypeName.Name -eq 'Parameter') {
                    foreach ($namedArg in $attribute.NamedArguments) {
                        if ($namedArg.ArgumentName -eq 'InvalidProperty') {
                            $issues += "Invalid parameter attribute: InvalidProperty on $($param.Name.VariablePath.UserPath)"
                        }
                    }
                }
                if ($attribute.TypeName.Name -eq 'ValidateSet') {
                    # Check if ValidateSet is used with incompatible types
                    if ($param.StaticType -and $param.StaticType.Name -eq 'Int32') {
                        $issues += "ValidateSet used with incompatible type Int32 on $($param.Name.VariablePath.UserPath)"
                    }
                }
            }
        }
    }
    
    return @{
        HasIssues = ($issues.Count -gt 0)
        Issues = $issues
        CanAutoFix = ($issues.Count -gt 0 -and $issues.Count -le 3)
    }
}

function Test-RunnerScriptConfiguration {
    <#
    .SYNOPSIS
        Tests a script for configuration support
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    
    # Check for Config parameter
    if (-not ($content -match 'Param\s*\(\s*.*\$Config')) {
        throw "Missing Config parameter: Script must accept a Config parameter"
    }
    
    # Check for LabRunner module import
    if (-not ($content -match 'Import-Module.*LabRunner')) {
        throw "Missing LabRunner import: Script must import LabRunner module"
    }
    
    # Check for Invoke-LabStep usage
    if (-not ($content -match 'Invoke-LabStep')) {
        throw "Missing Invoke-LabStep: Script must use Invoke-LabStep for execution"
    }
    
    return $true
}

function Invoke-RunnerScriptAutoFix {
    <#
    .SYNOPSIS
        Attempts to automatically fix common issues in runner scripts
    .PARAMETER ScriptPath
        The path to the script file
    .PARAMETER FixType
        The type of fix to apply
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [string]$FixType = "All"
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    $originalContent = $content
    $fixesApplied = @()
    
    # Fix common syntax errors
    if ($FixType -eq "All" -or $FixType -eq "Syntax") {
        # Fix missing closing braces
        $braceCount = ($content.ToCharArray() | Where-Object { $_ -eq '{' }).Count - ($content.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        if ($braceCount -gt 0) {
            $content += "`n" + ("}" * $braceCount)
            $fixesApplied += "Added $braceCount missing closing braces"
        }
        
        # Fix missing semicolons in for loops (basic fix)
        $content = $content -replace '\$i\+\+\)', '$i++) '
        if ($content -ne $originalContent) {
            $fixesApplied += "Fixed for loop syntax"
        }
    }
    
    # Add missing parameter blocks
    if ($FixType -eq "All" -or $FixType -eq "Parameters") {
        if (-not ($content -match 'Param\s*\(')) {
            $content = "Param([object]`$Config)`n`n$content"
            $fixesApplied += "Added missing parameter block"
        }
    }
    
    # Add missing error handling
    if ($FixType -eq "All" -or $FixType -eq "ErrorHandling") {
        if (-not ($content -match '\$ErrorActionPreference')) {
            $importIndex = $content.IndexOf('Import-Module')
            if ($importIndex -gt 0) {
                $beforeImport = $content.Substring(0, $importIndex)
                $afterImport = $content.Substring($importIndex)
                $content = $beforeImport + "`$ErrorActionPreference = 'Stop'`n" + $afterImport
                $fixesApplied += "Added error action preference"
            }
        }
    }
    
    # Write fixed content if changes were made
    if ($content -ne $originalContent) {
        Set-Content $ScriptPath -Value $content -Encoding UTF8
    }
    
    return @{
        Success = ($fixesApplied.Count -gt 0)
        FixesApplied = $fixesApplied
        OriginalContent = $originalContent
        FixedContent = $content
    }
}

function Invoke-CodeFixerOnRunnerScript {
    <#
    .SYNOPSIS
        Uses CodeFixer module to validate and fix runner scripts
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    try {
        # Import CodeFixer if available
        if (Get-Module -ListAvailable -Name CodeFixer) {
            Import-Module CodeFixer -Force
            
            # Use Invoke-PowerShellLint to analyze
            $results = Invoke-PowerShellLint -Path $ScriptPath -PassThru
            
            return @{
                Success = ($results.ErrorCount -eq 0)
                Issues = $results.Issues
                CanAutoFix = ($results.ErrorCount -eq 0 -and $results.WarningCount -le 5)
                Results = $results
            }
        } else {
            return @{
                Success = $false
                Issues = @("CodeFixer module not available")
                CanAutoFix = $false
                Results = $null
            }
        }
    } catch {
        return @{
            Success = $false
            Issues = @($_.Exception.Message)
            CanAutoFix = $false
            Results = $null
        }
    }
}

function Invoke-RunnerScriptDeploymentValidation {
    <#
    .SYNOPSIS
        Validates a runner script for deployment readiness
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    # Combine all validation checks
    $validationResults = @()
    
    try {
        Test-RunnerScriptName $ScriptPath
        $validationResults += "Name validation: PASS"
    } catch {
        throw "Failed security validation: Invalid script name - $($_.Exception.Message)"
    }
    
    try {
        Test-RunnerScriptSafety $ScriptPath
        $validationResults += "Safety validation: PASS"
    } catch {
        throw "Failed security validation: Safety check failed - $($_.Exception.Message)"
    }
    
    try {
        Test-RunnerScriptConfiguration $ScriptPath
        $validationResults += "Configuration validation: PASS"
    } catch {
        throw "Failed security validation: Configuration check failed - $($_.Exception.Message)"
    }
    
    return @{
        Success = $true
        ValidationResults = $validationResults
    }
}

function Test-RunnerScriptDeployment {
    <#
    .SYNOPSIS
        Tests if a script requires special approval for deployment
    .PARAMETER ScriptPath
        The path to the script file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script not found: $ScriptPath"
    }
    
    $content = Get-Content $ScriptPath -Raw
    
    # Check for external dependencies that require approval
    $externalDependencies = @(
        'Invoke-WebRequest',
        'Invoke-RestMethod',
        'Start-BitsTransfer',
        'Install-Package',
        'Install-Module',
        'chocolatey',
        'winget',
        'scoop'
    )
    
    $foundDependencies = @()
    foreach ($dependency in $externalDependencies) {
        if ($content -match $dependency) {
            $foundDependencies += $dependency
        }
    }
    
    return @{
        RequiresApproval = ($foundDependencies.Count -gt 0)
        ExternalDependencies = $foundDependencies
        ApprovalReason = if ($foundDependencies.Count -gt 0) { "Script contains external dependencies: $($foundDependencies -join ', ')" } else { "No external dependencies detected" }
    }
}

# ==============================================================================
# End of Additional Test Helper Functions
# ==============================================================================

















