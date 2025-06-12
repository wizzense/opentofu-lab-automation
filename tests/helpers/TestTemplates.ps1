<#
.SYNOPSIS
Test templates for creating consistent and extensible tests

.DESCRIPTION
This module provides templates for common test patterns, making it easy to add new tests
for runner scripts, configuration handlers, and platform-specific functionality.
#>

. (Join-Path $PSScriptRoot 'TestFramework.ps1')

function New-InstallerScriptTest {
    <#
    .SYNOPSIS
    Creates a standardized test for installer scripts
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [Parameter(Mandatory)]
        [string]$EnabledProperty,
        
        [Parameter(Mandatory)]
        [string]$InstallerCommand,
        
        [hashtable]$EnabledConfig = @{},
        
        [hashtable]$DisabledConfig = @{},
        
        [string[]]$RequiredPlatforms = @(),
        
        [string[]]$ExcludedPlatforms = @(),
        
        [hashtable]$AdditionalMocks = @{}
    )
    
    # Build default configurations
    $defaultEnabledConfig = @{ $EnabledProperty = $true }
    $defaultDisabledConfig = @{ $EnabledProperty = $false }
    
    $finalEnabledConfig = $defaultEnabledConfig + $EnabledConfig
    $finalDisabledConfig = $defaultDisabledConfig + $DisabledConfig
    
    # Create scenarios
    $scenarios = @()
    
    # Enabled scenario
    $enabledMocks = @{
        'Get-Command' = { $null }
        'Invoke-LabDownload' = { if ($Action) { & $Action 'test-installer.exe' } }
        $InstallerCommand = {}
    } + $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Installs when enabled' -Description "installs when $EnabledProperty is true" -Config $finalEnabledConfig -Mocks $enabledMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 1; $InstallerCommand = 1 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    # Disabled scenario
    $disabledMocks = @{
        'Invoke-LabDownload' = {}
        $InstallerCommand = {}
    } + $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Skips when disabled' -Description "skips when $EnabledProperty is false" -Config $finalDisabledConfig -Mocks $disabledMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 0; $InstallerCommand = 0 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    # Already installed scenario
    $installedMocks = @{
        'Get-Command' = { [PSCustomObject]@{ Name = 'test'; Source = '/usr/bin/test' } }
        'Invoke-LabDownload' = {}
        $InstallerCommand = {}
    } + $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Skips when already installed' -Description "does nothing when already installed" -Config $finalEnabledConfig -Mocks $installedMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 0; $InstallerCommand = 0 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-FeatureScriptTest {
    <#
    .SYNOPSIS
    Creates a standardized test for feature enablement scripts
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [Parameter(Mandatory)]
        [string]$EnabledProperty,
        
        [Parameter(Mandatory)]
        [string[]]$FeatureCommands,
        
        [hashtable]$EnabledConfig = @{},
        
        [hashtable]$DisabledConfig = @{},
        
        [string[]]$RequiredPlatforms = @('Windows'),
        
        [hashtable]$AdditionalMocks = @{}
    )
    
    # Build configurations
    $finalEnabledConfig = @{ $EnabledProperty = $true } + $EnabledConfig
    $finalDisabledConfig = @{ $EnabledProperty = $false } + $DisabledConfig
    
    $scenarios = @()
    
    # Feature enabled and not installed
    $enabledMocks = @{}
    $expectedInvocations = @{}
    
    foreach ($command in $FeatureCommands) {
        $enabledMocks[$command] = {}
        $expectedInvocations[$command] = 1
    }
    $enabledMocks += $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Enables feature when requested' -Description "enables feature when $EnabledProperty is true" -Config $finalEnabledConfig -Mocks $enabledMocks -ExpectedInvocations $expectedInvocations -RequiredPlatforms $RequiredPlatforms
    
    # Feature disabled
    $disabledMocks = @{}
    $disabledInvocations = @{}
    
    foreach ($command in $FeatureCommands) {
        $disabledMocks[$command] = {}
        $disabledInvocations[$command] = 0
    }
    $disabledMocks += $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Skips when disabled' -Description "skips when $EnabledProperty is false" -Config $finalDisabledConfig -Mocks $disabledMocks -ExpectedInvocations $disabledInvocations -RequiredPlatforms $RequiredPlatforms
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-ServiceScriptTest {
    <#
    .SYNOPSIS
    Creates a standardized test for service management scripts
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [string]$EnabledProperty,
        
        [hashtable]$EnabledConfig = @{},
        
        [string[]]$RequiredPlatforms = @('Windows'),
        
        [hashtable]$AdditionalMocks = @{}
    )
    
    $scenarios = @()
    
    # Service not running scenario
    $notRunningMocks = @{
        'Get-Service' = { [PSCustomObject]@{ Name = $ServiceName; Status = 'Stopped' } }
        'Start-Service' = {}
        'Enable-PSRemoting' = {}
    } + $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Starts stopped service' -Description "starts $ServiceName when not running" -Config $EnabledConfig -Mocks $notRunningMocks -ExpectedInvocations @{ 'Enable-PSRemoting' = 1 } -RequiredPlatforms $RequiredPlatforms
    
    # Service already running scenario
    $runningMocks = @{
        'Get-Service' = { [PSCustomObject]@{ Name = $ServiceName; Status = 'Running' } }
        'Start-Service' = {}
        'Enable-PSRemoting' = {}
    } + $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Skips running service' -Description "skips when $ServiceName already running" -Config $EnabledConfig -Mocks $runningMocks -ExpectedInvocations @{ 'Enable-PSRemoting' = 0 } -RequiredPlatforms $RequiredPlatforms
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-ConfigurationScriptTest {
    <#
    .SYNOPSIS
    Creates a standardized test for configuration scripts
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [Parameter(Mandatory)]
        [string]$EnabledProperty,
        
        [Parameter(Mandatory)]
        [string[]]$ConfigurationCommands,
        
        [hashtable]$EnabledConfig = @{},
        
        [hashtable]$DisabledConfig = @{},
        
        [string[]]$RequiredPlatforms = @(),
        
        [hashtable]$AdditionalMocks = @{}
    )
    
    $finalEnabledConfig = @{ $EnabledProperty = $true } + $EnabledConfig
    $finalDisabledConfig = @{ $EnabledProperty = $false } + $DisabledConfig
    
    $scenarios = @()
    
    # Configuration enabled
    $enabledMocks = @{}
    $expectedInvocations = @{}
    
    foreach ($command in $ConfigurationCommands) {
        $enabledMocks[$command] = {}
        $expectedInvocations[$command] = 1
    }
    $enabledMocks += $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Applies configuration when enabled' -Description "applies configuration when $EnabledProperty is true" -Config $finalEnabledConfig -Mocks $enabledMocks -ExpectedInvocations $expectedInvocations -RequiredPlatforms $RequiredPlatforms
    
    # Configuration disabled
    $disabledMocks = @{}
    $disabledInvocations = @{}
    
    foreach ($command in $ConfigurationCommands) {
        $disabledMocks[$command] = {}
        $disabledInvocations[$command] = 0
    }
    $disabledMocks += $AdditionalMocks
    
    $scenarios += New-TestScenario -Name 'Skips when disabled' -Description "skips when $EnabledProperty is false" -Config $finalDisabledConfig -Mocks $disabledMocks -ExpectedInvocations $disabledInvocations -RequiredPlatforms $RequiredPlatforms
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-CrossPlatformScriptTest {
    <#
    .SYNOPSIS
    Creates tests that validate cross-platform compatibility
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptName,
        
        [hashtable]$WindowsConfig = @{},
        
        [hashtable]$LinuxConfig = @{},
        
        [hashtable]$MacOSConfig = @{},
        
        [hashtable]$CommonMocks = @{}
    )
    
    $scenarios = @()
    
    # Windows-specific scenario
    if ($WindowsConfig.Count -gt 0) {
        $scenarios += New-TestScenario -Name 'Windows execution' -Description 'executes correctly on Windows' -Config $WindowsConfig -Mocks $CommonMocks -RequiredPlatforms @('Windows')
    }
    
    # Linux-specific scenario
    if ($LinuxConfig.Count -gt 0) {
        $scenarios += New-TestScenario -Name 'Linux execution' -Description 'executes correctly on Linux' -Config $LinuxConfig -Mocks $CommonMocks -RequiredPlatforms @('Linux')
    }
    
    # macOS-specific scenario
    if ($MacOSConfig.Count -gt 0) {
        $scenarios += New-TestScenario -Name 'macOS execution' -Description 'executes correctly on macOS' -Config $MacOSConfig -Mocks $CommonMocks -RequiredPlatforms @('macOS')
    }
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-IntegrationTest {
    <#
    .SYNOPSIS
    Creates integration tests that validate end-to-end functionality
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TestName,
        
        [Parameter(Mandatory)]
        [string[]]$ScriptSequence,
        
        [Parameter(Mandatory)]
        [object]$Config,
        
        [hashtable]$Mocks = @{},
        
        [scriptblock]$Validation,
        
        [string[]]$RequiredPlatforms = @()
    )
    
    Describe "Integration Test: $TestName" {
        BeforeAll {
            $script:TestConfig = $Config
            $script:ScriptPaths = @()
            
            foreach ($scriptName in $ScriptSequence) {
                $path = Get-RunnerScriptPath $scriptName
                if (-not $path -or -not (Test-Path $path)) {
                    throw "Integration test script not found: $scriptName"
                }
                $script:ScriptPaths += $path
            }
            
            Disable-InteractivePrompts
        }
        
        $skipReason = if ($RequiredPlatforms.Count -gt 0 -and $script:CurrentPlatform -notin $RequiredPlatforms) {
            "Not compatible with platform: $script:CurrentPlatform"
        } else {
            $null
        }
        
        It "executes script sequence successfully" -Skip:($null -ne $skipReason) {
            InModuleScope LabRunner {
                # Setup mocks
                New-StandardTestMocks -ModuleName 'LabRunner'
                
                foreach ($mockName in $Mocks.Keys) {
                    Mock $mockName $Mocks[$mockName] -ModuleName 'LabRunner'
                }
                
                # Execute scripts in sequence
                $results = @()
                foreach ($scriptPath in $script:ScriptPaths) {
                    try {
                        $result = & $scriptPath -Config $script:TestConfig
                        $results += $result
                    } catch {
                        throw "Integration test failed at script $scriptPath`: $_"
                    }
                }
                
                # Run custom validation if provided
                if ($Validation) {
                    & $Validation $results
                }
            }
        }
    }
}

# Export template functions
Export-ModuleMember -Function @(
    'New-InstallerScriptTest',
    'New-FeatureScriptTest', 
    'New-ServiceScriptTest',
    'New-ConfigurationScriptTest',
    'New-CrossPlatformScriptTest',
    'New-IntegrationTest'
)
