# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

$SkipNonWindows = $IsLinux -or $IsMacOS

# Use the same LabRunner module that the actual scripts use to avoid conflicts
$LabRunnerModulePath = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' 'pwsh' 'lab_utils' 'LabRunner')).Path

# Remove any previously loaded LabRunner modules to avoid duplicate import errors  
Get-Module LabRunner* | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the lab_utils LabRunner module
Import-Module $LabRunnerModulePath -Force

# Ensure Get-MenuSelection is always available for tests that need it
if (-not (Get-Command Get-MenuSelection -ErrorAction SilentlyContinue)) {
    function global:Get-MenuSelection { 
        param([string[]]$Items, [string]$Title)
        return @() 
    }
}

function global:Get-RunnerScriptPath {
    param(
        [Parameter(Mandatory=$true)][string]$Name
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
    $tempDir = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
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
                    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
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
                    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
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

# Note: Call Disable-InteractivePrompts manually in test BeforeAll blocks when needed
# Note: Windows mocks should be enabled manually in test BeforeAll blocks using Enable-WindowsMocks
# when needed for cross-platform compatibility

