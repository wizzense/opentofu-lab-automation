<#
.SYNOPSIS
Extensible Cross-Platform Testing Framework for OpenTofu Lab Automation

.DESCRIPTION
This framework provides standardized patterns for testing runner scripts across platforms.
It automatically handles platform detection, mock setup, and common test scenarios.

.FEATURES
- Cross-platform compatibility (Windows, Linux, macOS)
- Automatic script discovery and validation
- Standardized mock patterns
- Configuration-driven testing
- Extensible test templates
- Performance and integration testing support
#>

# Framework Configuration
$script:TestFrameworkConfig = @{
    DefaultTimeout = 30
    MaxRetries = 3
    LogLevel = 'Information'
    EnableCodeCoverage = $true
    PlatformSpecific = @{
        Windows = @{
            RequiredModules = @('Hyper-V')
            SkippedFeatures = @()
        }
        Linux = @{
            RequiredModules = @()
            SkippedFeatures = @('Hyper-V', 'WindowsFeatures')
        }
        macOS = @{
            RequiredModules = @()
            SkippedFeatures = @('Hyper-V', 'WindowsFeatures')
        }
    }
}

# Platform Detection
$script:CurrentPlatform = if ($IsWindows) { 'Windows' } elseif ($IsLinux) { 'Linux' } elseif ($IsMacOS) { 'macOS' } else { 'Unknown' }
$script:IsCrossPlatform = $script:CurrentPlatform -ne 'Windows'

class TestScenario {
    [string]$Name
    [string]$Description
    [object]$Config
    [hashtable]$Mocks
    [hashtable]$ExpectedInvocations
    [bool]$ShouldThrow
    [string]$ExpectedError
    [string[]]$RequiredPlatforms
    [string[]]$ExcludedPlatforms
    [scriptblock]$CustomValidation
    
    TestScenario([string]$Name) {
        $this.Name = $Name
        $this.Mocks = @{}
        $this.ExpectedInvocations = @{}
        $this.RequiredPlatforms = @()
        $this.ExcludedPlatforms = @()
    }
    
    [bool] ShouldSkip() {
        if ($this.RequiredPlatforms.Count -gt 0 -and $script:CurrentPlatform -notin $this.RequiredPlatforms) {
            return $true
        }
        if ($this.ExcludedPlatforms.Count -gt 0 -and $script:CurrentPlatform -in $this.ExcludedPlatforms) {
            return $true
        }
        return $false
    }
}

function New-TestScenario {
    <#
    .SYNOPSIS
    Creates a new test scenario with standardized configuration
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [string]$Description,
        
        [object]$Config,
        
        [hashtable]$Mocks = @{},
        
        [hashtable]$ExpectedInvocations = @{},
        
        [switch]$ShouldThrow,
        
        [string]$ExpectedError,
        
        [string[]]$RequiredPlatforms = @(),
        
        [string[]]$ExcludedPlatforms = @(),
        
        [scriptblock]$CustomValidation
    )
    
    $scenario = [TestScenario]::new($Name)
    $scenario.Description = $Description
    $scenario.Config = $Config
    $scenario.Mocks = $Mocks
    $scenario.ExpectedInvocations = $ExpectedInvocations
    $scenario.ShouldThrow = $ShouldThrow
    $scenario.ExpectedError = $ExpectedError
    $scenario.RequiredPlatforms = $RequiredPlatforms
    $scenario.ExcludedPlatforms = $ExcludedPlatforms
    $scenario.CustomValidation = $CustomValidation
    
    return $scenario
}

function Invoke-ScriptTest {
    <#
    .SYNOPSIS
    Executes a test scenario against a runner script with comprehensive validation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory)]
        [TestScenario]$Scenario,
        
        [switch]$EnableVerboseLogging
    )
    
    if ($Scenario.ShouldSkip()) {
        Write-Warning "Skipping scenario '$($Scenario.Name)' - not compatible with platform: $script:CurrentPlatform"
        return
    }
    
    try {
        # Setup standard mocks
        New-StandardTestMocks -ModuleName 'LabRunner'
        
        # Apply scenario-specific mocks
        foreach ($mockName in $Scenario.Mocks.Keys) {
            if ($EnableVerboseLogging) {
                Write-Verbose "Setting up mock for: $mockName"
            }
            Mock $mockName $Scenario.Mocks[$mockName] -ModuleName 'LabRunner'
        }
        
        # Execute the script
        $result = $null
        $error = $null
        
        if ($Scenario.ShouldThrow) {
            if ($Scenario.ExpectedError) {
                { $result = & $ScriptPath -Config $Scenario.Config } | Should -Throw "*$($Scenario.ExpectedError)*"
            } else {
                { $result = & $ScriptPath -Config $Scenario.Config } | Should -Throw
            }
        } else {
            try {
                $result = & $ScriptPath -Config $Scenario.Config
            } catch {
                $error = $_
                if (-not $Scenario.ShouldThrow) {
                    throw "Script failed unexpectedly: $_"
                }
            }
        }
        
        # Verify expected invocations
        foreach ($funcName in $Scenario.ExpectedInvocations.Keys) {
            $expectedCount = $Scenario.ExpectedInvocations[$funcName]
            if ($EnableVerboseLogging) {
                Write-Verbose "Verifying invocation count for ${funcName}: expected $expectedCount"
            }
            
            if ($expectedCount -eq 0) {
                Should -Invoke -CommandName $funcName -Times 0 -ModuleName 'LabRunner'
            } else {
                Should -Invoke -CommandName $funcName -Times $expectedCount -ModuleName 'LabRunner'
            }
        }
        
        # Run custom validation if provided
        if ($Scenario.CustomValidation) {
            & $Scenario.CustomValidation $result $error
        }
        
    } catch {
        Write-Error "Test scenario '$($Scenario.Name)' failed: $_"
        throw
    }
}

function New-StandardTestMocks {
    <#
    .SYNOPSIS
    Creates comprehensive standard mocks for cross-platform testing
    #>
    param(
        [string]$ModuleName
    )
    
    $mockParams = if ($ModuleName) { @{ ModuleName = $ModuleName } } else { @{} }
    
    # Core system mocks
    Mock Write-CustomLog @mockParams {}
    Mock Write-Host @mockParams {}
    Mock Read-LoggedInput @mockParams { 'n' }
    Mock Get-MenuSelection @mockParams { @() }
    
    # Platform-specific mocks
    switch ($script:CurrentPlatform) {
        'Windows' {
            New-WindowsSpecificMocks -ModuleName $ModuleName
        }
        'Linux' {
            New-LinuxSpecificMocks -ModuleName $ModuleName
        }
        'macOS' {
            New-MacOSSpecificMocks -ModuleName $ModuleName
        }
    }
    
    # Common cross-platform mocks
    Mock Get-Command @mockParams { $null } -ParameterFilter { $Name -eq 'nonexistent' }
    Mock Start-Process @mockParams {}
    Mock Invoke-WebRequest @mockParams {}
    Mock Invoke-RestMethod @mockParams { @{ download_url = 'https://example.com/file.zip' } }
    Mock New-Item @mockParams {}
    Mock Remove-Item @mockParams {}
    Mock Copy-Item @mockParams {}
    Mock Test-Path @mockParams { $true }
}

function New-WindowsSpecificMocks {
    param([string]$ModuleName)
    
    $mockParams = if ($ModuleName) { @{ ModuleName = $ModuleName } } else { @{} }
    
    # Windows Services
    Mock Get-Service @mockParams {
        [PSCustomObject]@{
            Name = 'MockService'
            Status = 'Running'
        }
    }
    
    Mock Start-Service @mockParams {}
    Mock Stop-Service @mockParams {}
    Mock Restart-Service @mockParams {}
    
    # Windows Features
    Mock Get-WindowsOptionalFeature @mockParams {
        [PSCustomObject]@{
            FeatureName = 'Microsoft-Hyper-V'
            State = 'Enabled'
        }
    }
    
    Mock Enable-WindowsOptionalFeature @mockParams {}
    Mock Get-WindowsFeature @mockParams {
        [PSCustomObject]@{
            Name = 'MockFeature'
            InstallState = 'Installed'
        }
    }
    
    Mock Install-WindowsFeature @mockParams {}
    
    # Registry operations
    Mock Get-ItemProperty @mockParams {
        [PSCustomObject]@{
            fDenyTSConnections = 0
        }
    }
    
    Mock Set-ItemProperty @mockParams {}
    
    # Networking
    Mock New-NetFirewallRule @mockParams {
        [PSCustomObject]@{
            DisplayName = 'Mock Rule'
            Enabled = $true
        }
    }
    
    Mock Get-NetFirewallRule @mockParams {
        [PSCustomObject]@{
            DisplayName = 'Mock Rule'
            Enabled = $true
        }
    }
    
    Mock Remove-NetFirewallRule @mockParams {}
    Mock Set-DnsClientServerAddress @mockParams {}
    
    # Certificate operations
    Mock New-SelfSignedCertificate @mockParams {
        [PSCustomObject]@{
            Thumbprint = 'ABCD1234567890'
            Subject = 'CN=MockCert'
        }
    }
    
    # WSMan/PowerShell Remoting
    Mock Enable-PSRemoting @mockParams {}
    Mock Test-WSMan @mockParams { $true }
    
    # Hyper-V specific mocks
    if (Get-Module -ListAvailable -Name 'Hyper-V') {
        Mock Get-VM @mockParams { @() }
        Mock New-VM @mockParams {}
        Mock Start-VM @mockParams {}
        Mock Stop-VM @mockParams {}
    }
}

function New-LinuxSpecificMocks {
    param([string]$ModuleName)
    
    $mockParams = if ($ModuleName) { @{ ModuleName = $ModuleName } } else { @{} }
    
    # Linux package managers
    Mock Get-Command @mockParams {
        [PSCustomObject]@{
            Name = 'apt-get'
            Source = '/usr/bin/apt-get'
            CommandType = 'Application'
        }
    } -ParameterFilter { $Name -eq 'apt-get' }
    
    Mock Get-Command @mockParams {
        [PSCustomObject]@{
            Name = 'yum'
            Source = '/usr/bin/yum'
            CommandType = 'Application'
        }
    } -ParameterFilter { $Name -eq 'yum' }
    
    # systemd services
    Mock Get-Command @mockParams {
        [PSCustomObject]@{
            Name = 'systemctl'
            Source = '/usr/bin/systemctl'
            CommandType = 'Application'
        }
    } -ParameterFilter { $Name -eq 'systemctl' }
}

function New-MacOSSpecificMocks {
    param([string]$ModuleName)
    
    $mockParams = if ($ModuleName) { @{ ModuleName = $ModuleName } } else { @{} }
    
    # Homebrew
    Mock Get-Command @mockParams {
        [PSCustomObject]@{
            Name = 'brew'
            Source = '/usr/local/bin/brew'
            CommandType = 'Application'
        }
    } -ParameterFilter { $Name -eq 'brew' }
    
    # macOS system commands
    Mock Get-Command @mockParams {
        [PSCustomObject]@{
            Name = 'launchctl'
            Source = '/bin/launchctl'
            CommandType = 'Application'
        }
    } -ParameterFilter { $Name -eq 'launchctl' }
}

function Test-RunnerScript {
    <#
    .SYNOPSIS
    Comprehensive testing function for runner scripts with multiple scenarios
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [TestScenario[]]$Scenarios = @(),
        
        [switch]$IncludeStandardTests,
        
        [switch]$EnableVerboseLogging
    )
    
    $scriptPath = Get-RunnerScriptPath $ScriptName
    if (-not $scriptPath -or -not (Test-Path $scriptPath)) {
        throw "Script under test not found: $ScriptName (resolved path: $scriptPath)"
    }
    
    Describe "Runner Script: $ScriptName" {
        BeforeAll {
            $script:ScriptPath = $scriptPath
            $script:ScriptName = $ScriptName
            
            # Disable interactive prompts for all tests
            Disable-InteractivePrompts
        }
        
        if ($IncludeStandardTests) {
            Context 'Standard Validation Tests' {
                It 'parses without syntax errors' {
                    $errors = $null
                    [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
                    ($errors ? $errors.Count : 0) | Should -Be 0
                }
                
                It 'has required Config parameter' {
                    $content = Get-Content $script:ScriptPath -Raw
                    # Look for Param declaration with Config parameter
                    $content | Should -Match 'Param\s*\([^)]*Config[^)]*\)'
                }
                
                It 'imports LabRunner module' {
                    $content = Get-Content $script:ScriptPath -Raw
                    $content | Should -Match 'Import-Module.*LabRunner'
                }
                
                It 'contains Invoke-LabStep call' {
                    $content = Get-Content $script:ScriptPath -Raw
                    $content | Should -Match 'Invoke-LabStep'
                }
            }
        }
        
        # Execute custom scenarios
        foreach ($scenario in $Scenarios) {
            $skipReason = if ($scenario.ShouldSkip()) { 
                "Not compatible with platform: $script:CurrentPlatform" 
            } else { 
                $null 
            }
            
            Context "Scenario: $($scenario.Name)" {
                It $scenario.Description -Skip:($null -ne $skipReason) {
                    InModuleScope LabRunner {
                        Invoke-ScriptTest -ScriptPath $script:ScriptPath -Scenario $scenario -EnableVerboseLogging:$EnableVerboseLogging
                    }
                }
            }
        }
    }
}

function New-CommonTestScenarios {
    <#
    .SYNOPSIS
    Creates common test scenarios that apply to most runner scripts
    #>
    param(
        [object]$EnabledConfig,
        [object]$DisabledConfig,
        [string]$EnabledProperty,
        [hashtable]$AdditionalMocks = @{}
    )
    
    $scenarios = @()
    
    if ($EnabledConfig) {
        $scenarios += New-TestScenario -Name 'Enabled' -Description "executes when $EnabledProperty is true" -Config $EnabledConfig -Mocks $AdditionalMocks
    }
    
    if ($DisabledConfig) {
        $scenarios += New-TestScenario -Name 'Disabled' -Description "skips when $EnabledProperty is false" -Config $DisabledConfig -Mocks $AdditionalMocks
    }
    
    return $scenarios
}

# Only export functions if running as a module
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as script - functions are already available
} else {
    # Running as module - export functions
    Export-ModuleMember -Function @(
        'New-TestScenario',
        'Invoke-ScriptTest', 
        'New-StandardTestMocks',
        'Test-RunnerScript',
        'New-CommonTestScenarios'
    )
}
