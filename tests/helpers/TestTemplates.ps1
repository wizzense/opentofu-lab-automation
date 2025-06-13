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
        [Parameter(Mandatory)



]
        [string]$ScriptName,
        
        [Parameter(Mandatory)]
        [string]$EnabledProperty,
        
        [Parameter(Mandatory)]
        [string]$InstallerCommand, # e.g., Start-Process, Invoke-MSI, etc.

        [Parameter(Mandatory)]
        [string]$SoftwareCommandName, # e.g., 'go', 'terraform', 'code'
        
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
    
    # --- Enabled scenario (Software NOT installed) ---
    $enabledScenarioMocks = @{
        # Mock Get-Command: Software is NOT installed initially
        # Any other Get-Command calls will fall through to the default mock (returns $null)
        # or to a user-provided Get-Command in AdditionalMocks
        'Get-Command' = { 
            param($Name)
            



if ($Name -eq $SoftwareCommandName) { return $null } 
            # If AdditionalMocks has a Get-Command, use it for other names
            if ($AdditionalMocks.ContainsKey('Get-Command')) {
                return (& $AdditionalMocks['Get-Command'] $Name)
            }
            return $null # Default behavior for other commands
        }
        'Invoke-LabDownload' = { if ($Action) { & $Action 'test-installer.exe' } }
        $InstallerCommand = {} # Mock the specific installer command used by the script
    }
    # Merge other additional mocks, giving precedence to AdditionalMocks
    $AdditionalMocks.GetEnumerator() | ForEach-Object {
        if ($_.Name -ne 'Get-Command') { # Get-Command is handled specially above
            $enabledScenarioMocks[$_.Name] = $_.Value
        }
    }
    
    $scenarios += New-TestScenario -Name "Installs $SoftwareCommandName when enabled" -Description "installs $SoftwareCommandName when $EnabledProperty is true" -Config $finalEnabledConfig -Mocks $enabledScenarioMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 1; $InstallerCommand = 1 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    # --- Disabled scenario ---
    $disabledScenarioMocks = @{
        # Get-Command behavior doesn't strictly matter as script shouldn't try to install
        # but we can keep it consistent or simple.
        'Get-Command' = { 
            param($Name)
            



# If AdditionalMocks has a Get-Command, use it
            if ($AdditionalMocks.ContainsKey('Get-Command')) {
                return (& $AdditionalMocks['Get-Command'] $Name)
            }
            return $null
        }
        'Invoke-LabDownload' = {}
        $InstallerCommand = {}
    }
    $AdditionalMocks.GetEnumerator() | ForEach-Object {
        if ($_.Name -ne 'Get-Command') {
            $disabledScenarioMocks[$_.Name] = $_.Value
        }
    }
    
    $scenarios += New-TestScenario -Name "Skips $SoftwareCommandName when disabled" -Description "skips $SoftwareCommandName when $EnabledProperty is false" -Config $finalDisabledConfig -Mocks $disabledScenarioMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 0; $InstallerCommand = 0 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    # --- Already installed scenario ---
    $alreadyInstalledMocks = @{
        # Mock Get-Command: Software IS already installed
        'Get-Command' = { 
            param($Name)
            



if ($Name -eq $SoftwareCommandName) { return [PSCustomObject]@{ Name = $SoftwareCommandName; Source = "/fake/path/to/$SoftwareCommandName" } } 
            # If AdditionalMocks has a Get-Command, use it for other names
            if ($AdditionalMocks.ContainsKey('Get-Command')) {
                return (& $AdditionalMocks['Get-Command'] $Name)
            }
            return $null # Default behavior for other commands
        }
        'Invoke-LabDownload' = {}
        $InstallerCommand = {}
    }
    $AdditionalMocks.GetEnumerator() | ForEach-Object {
        if ($_.Name -ne 'Get-Command') {
            $alreadyInstalledMocks[$_.Name] = $_.Value
        }
    }
    
    $scenarios += New-TestScenario -Name "Skips $SoftwareCommandName when already installed" -Description "does nothing when $SoftwareCommandName is already installed" -Config $finalEnabledConfig -Mocks $alreadyInstalledMocks -ExpectedInvocations @{ 'Invoke-LabDownload' = 0; $InstallerCommand = 0 } -RequiredPlatforms $RequiredPlatforms -ExcludedPlatforms $ExcludedPlatforms
    
    Test-RunnerScript -ScriptName $ScriptName -Scenarios $scenarios -IncludeStandardTests
}

function New-FeatureScriptTest {
    <#
    .SYNOPSIS
    Creates a standardized test for feature enablement scripts
    #>
    param(
        [Parameter(Mandatory)



]
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
        [Parameter(Mandatory)



]
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
        [Parameter(Mandatory)



]
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
        [Parameter(Mandatory)



]
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
        [Parameter(Mandatory)



]
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
            # Ensure PSScriptRoot is correctly defined for module context if necessary
            # If this script is intended to be a module, it should be saved as .psm1
            # and imported using Import-Module.
            # For now, assuming it's sourced and PSScriptRoot is available.
        }
        
        $skipReason = if ($RequiredPlatforms.Count -gt 0 -and $script:CurrentPlatform -notin $RequiredPlatforms) { "Not compatible with platform: $script:CurrentPlatform"
           } else { $null
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

# Do NOT include Export-ModuleMember in this .ps1 file.
# If you convert this to a .psm1 module, then add:
# Export-ModuleMember -Function New-InstallerScriptTest, New-FeatureScriptTest, New-ServiceScriptTest, New-ConfigurationScriptTest, New-CrossPlatformScriptTest, New-IntegrationTest


