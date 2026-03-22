#Requires -Version 7.0
#Requires -Modules Pester

<#
.SYNOPSIS
    Example test demonstrating state-of-the-art testing patterns

.DESCRIPTION
    This test file showcases modern Pester 5.x testing patterns including:
    - Parameterized tests with TestCases
    - Advanced mocking strategies
    - Edge case testing
    - Performance benchmarking
    - Test data builders
#>

BeforeAll {
    # Import required modules
    $projectRoot = $env:PROJECT_ROOT
    if (-not $projectRoot) {
        $projectRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $env:PROJECT_ROOT = $projectRoot
    }
    
    # Import Logging module first (dependency)
    $loggingPath = Join-Path $projectRoot "core-runner/modules/Logging"
    if (Test-Path $loggingPath) {
        Import-Module $loggingPath -Force -ErrorAction SilentlyContinue
    }
    
    # Import TestingFramework module
    $testingFrameworkPath = Join-Path $projectRoot "core-runner/modules/TestingFramework"
    if (Test-Path $testingFrameworkPath) {
        Import-Module $testingFrameworkPath -Force -ErrorAction SilentlyContinue
    }
    
    # Mock centralized logging
    Mock Write-CustomLog { 
        param($Message, $Level = "INFO")
        # Silent mock for cleaner test output
    }
    
    # Test data builder class
    class TestModuleConfigBuilder {
        [hashtable] $Config = @{}
        
        [TestModuleConfigBuilder] WithName([string] $name) {
            $this.Config.Name = $name
            return $this
        }
        
        [TestModuleConfigBuilder] WithVersion([string] $version) {
            $this.Config.Version = $version
            return $this
        }
        
        [TestModuleConfigBuilder] WithAuthor([string] $author) {
            $this.Config.Author = $author
            return $this
        }
        
        [TestModuleConfigBuilder] WithDefaults() {
            $this.Config = @{
                Name = "TestModule"
                Version = "1.0.0"
                Author = "Test Team"
                Description = "Test module for demonstrations"
                PowerShellVersion = "7.0"
            }
            return $this
        }
        
        [hashtable] Build() {
            return $this.Config.Clone()
        }
    }
    
    # Helper function for testing
    function Test-ModuleConfiguration {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [hashtable]$Config
        )
        
        $result = @{
            IsValid = $true
            Errors = @()
            Warnings = @()
        }
        
        # Validate required fields
        if (-not $Config.Name) {
            $result.IsValid = $false
            $result.Errors += "Name is required"
        }
        
        if (-not $Config.Version) {
            $result.IsValid = $false
            $result.Errors += "Version is required"
        }
        
        # Validate version format
        if ($Config.Version -and $Config.Version -notmatch '^\d+\.\d+\.\d+$') {
            $result.Warnings += "Version should follow semantic versioning (x.y.z)"
        }
        
        # Optional field warnings
        if (-not $Config.Author) {
            $result.Warnings += "Author is recommended"
        }
        
        if (-not $Config.Description) {
            $result.Warnings += "Description is recommended"
        }
        
        return $result
    }
    
    # Helper function to simulate processing
    function Invoke-DataProcessing {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [AllowNull()]
            [object]$Data,
            
            [Parameter()]
            [int]$DelayMs = 0
        )
        
        if ($null -eq $Data) {
            throw "Data cannot be null"
        }
        
        if ($Data -is [string] -and [string]::IsNullOrWhiteSpace($Data)) {
            throw "Data cannot be empty or whitespace"
        }
        
        if ($DelayMs -gt 0) {
            Start-Sleep -Milliseconds $DelayMs
        }
        
        return [PSCustomObject]@{
            Success = $true
            ProcessedData = $Data
            Timestamp = Get-Date
        }
    }
}

Describe "TestingFramework - State-of-the-Art Patterns Demo" -Tag "Unit", "Example" {
    
    Context "Parameterized Testing - Input Validation" {
        
        It "Should validate <Description>" -TestCases @(
            @{ 
                Description = "valid minimal config"
                Config = @{ Name = "Module1"; Version = "1.0.0" }
                ExpectedValid = $true
                ExpectedErrorCount = 0
                ExpectedWarningCount = 2
            }
            @{ 
                Description = "valid full config"
                Config = @{ 
                    Name = "Module1"
                    Version = "1.0.0"
                    Author = "Team"
                    Description = "Full config"
                }
                ExpectedValid = $true
                ExpectedErrorCount = 0
                ExpectedWarningCount = 0
            }
            @{ 
                Description = "missing name"
                Config = @{ Version = "1.0.0"; Author = "Team" }
                ExpectedValid = $false
                ExpectedErrorCount = 1
                ExpectedWarningCount = 1
            }
            @{ 
                Description = "missing version"
                Config = @{ Name = "Module1"; Author = "Team" }
                ExpectedValid = $false
                ExpectedErrorCount = 1
                ExpectedWarningCount = 1
            }
            @{ 
                Description = "invalid version format"
                Config = @{ Name = "Module1"; Version = "1.0" }
                ExpectedValid = $true
                ExpectedErrorCount = 0
                ExpectedWarningCount = 3
            }
        ) {
            param($Description, $Config, $ExpectedValid, $ExpectedErrorCount, $ExpectedWarningCount)
            
            # Act
            $result = Test-ModuleConfiguration -Config $Config
            
            # Assert
            $result.IsValid | Should -Be $ExpectedValid
            $result.Errors.Count | Should -Be $ExpectedErrorCount
            $result.Warnings.Count | Should -Be $ExpectedWarningCount
        }
    }
    
    Context "Edge Case Testing - Null and Empty Handling" {
        
        It "Should handle <InputType> appropriately" -TestCases @(
            @{ InputType = "null value"; InputData = $null; ShouldThrow = $true; ErrorMessage = "cannot be null" }
            @{ InputType = "empty string"; InputData = ""; ShouldThrow = $true; ErrorMessage = "cannot be empty" }
            @{ InputType = "whitespace only"; InputData = "   "; ShouldThrow = $true; ErrorMessage = "cannot be empty" }
            @{ InputType = "valid string"; InputData = "data"; ShouldThrow = $false; ErrorMessage = "" }
            @{ InputType = "valid array"; InputData = @(1, 2, 3); ShouldThrow = $false; ErrorMessage = "" }
            @{ InputType = "valid hashtable"; InputData = @{ Key = "Value" }; ShouldThrow = $false; ErrorMessage = "" }
        ) {
            param($InputType, $InputData, $ShouldThrow, $ErrorMessage)
            
            if ($ShouldThrow) {
                # Assert - Should throw with expected message
                { Invoke-DataProcessing -Data $InputData } | Should -Throw -ExpectedMessage "*$ErrorMessage*"
            } else {
                # Assert - Should not throw
                { Invoke-DataProcessing -Data $InputData } | Should -Not -Throw
                
                # Verify result
                $result = Invoke-DataProcessing -Data $InputData
                $result.Success | Should -Be $true
                $result.ProcessedData | Should -Be $InputData
            }
        }
    }
    
    Context "Test Data Builders - Complex Object Creation" {
        
        It "Should build minimal configuration" {
            # Arrange - Use builder pattern
            $config = [TestModuleConfigBuilder]::new().
                WithName("MinimalModule").
                WithVersion("0.1.0").
                Build()
            
            # Act
            $result = Test-ModuleConfiguration -Config $config
            
            # Assert
            $result.IsValid | Should -Be $true
            $config.Name | Should -Be "MinimalModule"
            $config.Version | Should -Be "0.1.0"
        }
        
        It "Should build full configuration with defaults" {
            # Arrange
            $config = [TestModuleConfigBuilder]::new().
                WithDefaults().
                Build()
            
            # Act
            $result = Test-ModuleConfiguration -Config $config
            
            # Assert
            $result.IsValid | Should -Be $true
            $result.Warnings.Count | Should -Be 0
            $config.Name | Should -Be "TestModule"
            $config.Version | Should -Be "1.0.0"
            $config.Author | Should -Be "Test Team"
        }
        
        It "Should build custom configuration fluently" {
            # Arrange - Demonstrate fluent interface
            $config = [TestModuleConfigBuilder]::new().
                WithDefaults().
                WithName("CustomModule").
                WithVersion("2.0.0").
                WithAuthor("Custom Team").
                Build()
            
            # Act
            $result = Test-ModuleConfiguration -Config $config
            
            # Assert
            $result.IsValid | Should -Be $true
            $config.Name | Should -Be "CustomModule"
            $config.Version | Should -Be "2.0.0"
            $config.Author | Should -Be "Custom Team"
        }
    }
    
    Context "Performance Testing - Execution Time Benchmarks" {
        
        It "Should complete processing within acceptable time" {
            # Arrange
            $data = "test-data"
            $maxExecutionTimeMs = 100
            
            # Act
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-DataProcessing -Data $data
            $stopwatch.Stop()
            
            # Assert
            $result.Success | Should -Be $true
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $maxExecutionTimeMs
        }
        
        It "Should process multiple items efficiently" {
            # Arrange
            $items = 1..10
            $maxTotalTimeMs = 500
            
            # Act
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $results = $items | ForEach-Object {
                Invoke-DataProcessing -Data "item-$_"
            }
            $stopwatch.Stop()
            
            # Assert
            $results.Count | Should -Be 10
            $results | ForEach-Object { $_.Success | Should -Be $true }
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan $maxTotalTimeMs
        }
    }
    
    Context "Advanced Mocking - Selective Mocking with Parameter Filters" {
        
        BeforeAll {
            # Mock external command with specific behavior based on parameters
            Mock Invoke-RestMethod -ParameterFilter {
                $Uri -like "*/api/success*"
            } {
                return @{
                    StatusCode = 200
                    Data = "Success"
                }
            }
            
            Mock Invoke-RestMethod -ParameterFilter {
                $Uri -like "*/api/error*"
            } {
                throw "API Error"
            }
            
            # Function to test
            function Get-ApiData {
                param([string]$Endpoint)
                
                try {
                    $response = Invoke-RestMethod -Uri "https://example.com/api/$Endpoint"
                    return @{ Success = $true; Data = $response.Data }
                } catch {
                    return @{ Success = $false; Error = $_.Exception.Message }
                }
            }
        }
        
        It "Should handle successful API call" {
            # Act
            $result = Get-ApiData -Endpoint "success/data"
            
            # Assert
            $result.Success | Should -Be $true
            $result.Data | Should -Be "Success"
            
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -like "*/api/success*"
            }
        }
        
        It "Should handle failed API call" {
            # Act
            $result = Get-ApiData -Endpoint "error/data"
            
            # Assert
            $result.Success | Should -Be $false
            $result.Error | Should -BeLike "*API Error*"
            
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -like "*/api/error*"
            }
        }
    }
    
    Context "Boundary Value Testing" {
        
        It "Should handle boundary values correctly" -TestCases @(
            @{ Value = -1; Description = "below minimum"; ExpectedThrow = $true }
            @{ Value = 0; Description = "at minimum"; ExpectedThrow = $false }
            @{ Value = 50; Description = "in range"; ExpectedThrow = $false }
            @{ Value = 100; Description = "at maximum"; ExpectedThrow = $false }
            @{ Value = 101; Description = "above maximum"; ExpectedThrow = $true }
        ) {
            param($Value, $Description, $ExpectedThrow)
            
            # Function to test
            function Test-RangeValue {
                param(
                    [ValidateRange(0, 100)]
                    [int]$Value
                )
                return $true
            }
            
            if ($ExpectedThrow) {
                { Test-RangeValue -Value $Value } | Should -Throw
            } else {
                { Test-RangeValue -Value $Value } | Should -Not -Throw
                $result = Test-RangeValue -Value $Value
                $result | Should -Be $true
            }
        }
    }
}

Describe "TestingFramework - Integration Patterns Demo" -Tag "Integration", "Example" {
    
    Context "Multi-Step Workflow Testing" {
        
        BeforeAll {
            # Set up test workspace
            $script:testWorkspace = Join-Path $TestDrive "integration-test"
            New-Item -Path $script:testWorkspace -ItemType Directory -Force | Out-Null
        }
        
        It "Should complete end-to-end workflow" {
            # Step 1: Initialize workspace
            $initFile = Join-Path $script:testWorkspace "init.txt"
            "initialized" | Out-File -FilePath $initFile
            Test-Path $initFile | Should -Be $true
            
            # Step 2: Process data
            $dataFile = Join-Path $script:testWorkspace "data.json"
            $data = @{ 
                Workflow = "Integration Test"
                Step = "Processing"
                Timestamp = (Get-Date).ToString("o")
            }
            $data | ConvertTo-Json | Out-File -FilePath $dataFile
            Test-Path $dataFile | Should -Be $true
            
            # Step 3: Validate result
            $savedData = Get-Content -Path $dataFile -Raw | ConvertFrom-Json
            $savedData.Workflow | Should -Be "Integration Test"
            $savedData.Step | Should -Be "Processing"
            
            # Step 4: Clean up (handled by AfterAll)
            Get-ChildItem $script:testWorkspace | Should -HaveCount 2
        }
        
        AfterAll {
            # Clean up test workspace
            if (Test-Path $script:testWorkspace) {
                Remove-Item -Path $script:testWorkspace -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

AfterAll {
    # Global cleanup
    Remove-Module TestingFramework -Force -ErrorAction SilentlyContinue
}
