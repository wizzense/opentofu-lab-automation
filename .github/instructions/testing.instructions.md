# Testing Framework Instructions

When working with tests in this project, follow these specific guidelines:

## Pester Test Generation

### Test File Structure
- Use `.Tests.ps1` suffix for all test files
- Place unit tests in `tests/unit/modules/[ModuleName]/`
- Place integration tests in `tests/integration/`
- Place system tests in `tests/system/`

### Required Headers
```powershell
#Requires -Module Pester
#Requires -Version 7.0

# Import the module under test
BeforeAll {
    $ModulePath = Resolve-Path "$PSScriptRoot/../../../core-runner/modules/ModuleName"
    Import-Module $ModulePath -Force
    
    # Common test utilities
    Import-Module "$PSScriptRoot/../../helpers/TestHelpers.psm1" -Force
}
```

### Test Categories
Use tags to categorize tests:
```powershell
Describe 'Function-Name' -Tag 'Unit', 'Fast' {
    # Quick unit tests
}

Describe 'Integration-Test' -Tag 'Integration', 'Slow' {
    # Integration tests
}

Describe 'Cross-Platform-Test' -Tag 'CrossPlatform' {
    # Platform-specific tests
}
```

### Mock Patterns
```powershell
BeforeAll {
    # Mock external dependencies
    Mock Write-CustomLog {}
    Mock Invoke-RestMethod { return @{ Status = 'Success' } }
    Mock Get-ChildItem { return @() } -ParameterFilter { $Path -like '*backup*' }
}
```

### Assertion Patterns
```powershell
# Basic assertions
$result | Should -Not -BeNullOrEmpty
$result | Should -BeOfType [string]
$result | Should -Match 'pattern'

# Complex object validation
$result | Should -HaveCount 3
$result.Property | Should -Be 'ExpectedValue'
$result | Should -BeIn @('Valid1', 'Valid2')

# Error testing
{ Invoke-Function -InvalidParam } | Should -Throw -ExpectedMessage 'Parameter validation failed'
```

### Cross-Platform Testing
```powershell
Context 'Cross-platform compatibility' {
    It 'Should work on Windows' -Skip:(-not $IsWindows) {
        # Windows-specific test logic
        $result = Invoke-WindowsSpecificFunction
        $result | Should -Not -BeNullOrEmpty
    }
    
    It 'Should work on Linux' -Skip:(-not $IsLinux) {
        # Linux-specific test logic
        $result = Invoke-LinuxSpecificFunction
        $result | Should -Not -BeNullOrEmpty
    }
    
    It 'Should work on macOS' -Skip:(-not $IsMacOS) {
        # macOS-specific test logic
        $result = Invoke-MacOSSpecificFunction
        $result | Should -Not -BeNullOrEmpty
    }
}
```

### Performance Testing
```powershell
Context 'Performance requirements' {
    It 'Should complete within reasonable time' {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $result = Invoke-Function -Parameter 'test'
        
        $stopwatch.Stop()
        $stopwatch.Elapsed.TotalSeconds | Should -BeLessThan 5
    }
}
```

### Module-Specific Test Patterns

#### BackupManager Tests
```powershell
Context 'Backup operations' {
    BeforeEach {
        $TestBackupPath = New-TestDirectory
        $TestSourcePath = New-TestDirectory -WithFiles
    }
    
    AfterEach {
        Remove-TestDirectory $TestBackupPath
        Remove-TestDirectory $TestSourcePath
    }
    
    It 'Should create backup with proper structure' {
        $result = Invoke-BackupOperation -Source $TestSourcePath -Destination $TestBackupPath
        
        Test-Path "$TestBackupPath/backup-*.zip" | Should -Be $true
        $result.BackupSize | Should -BeGreaterThan 0
    }
}
```

#### DevEnvironment Tests
```powershell
Context 'Environment setup' {
    It 'Should detect current platform' {
        $platform = Get-CurrentPlatform
        $platform | Should -BeIn @('Windows', 'Linux', 'macOS')
    }
    
    It 'Should install tools for detected platform' {
        Mock Install-WindowsTool {}
        Mock Install-LinuxTool {}
        Mock Install-MacOSTool {}
        
        Install-DevelopmentTools
        
        if ($IsWindows) {
            Should -Invoke Install-WindowsTool -Times 1
        }
    }
}
```

#### LabRunner Tests
```powershell
Context 'Lab orchestration' {
    It 'Should execute steps in correct order' {
        $steps = @('Step1', 'Step2', 'Step3')
        $executionOrder = @()
        
        Mock Execute-LabStep { $executionOrder += $StepName }
        
        Invoke-LabSequence -Steps $steps
        
        $executionOrder | Should -Be $steps
    }
}
```

### Test Data Management
```powershell
BeforeAll {
    # Test data should be deterministic and isolated
    $script:TestData = @{
        ValidConfig = @{
            Environment = 'test'
            Modules = @{
                BackupManager = @{ Enabled = $true }
            }
        }
        InvalidConfig = @{}
        SampleFiles = @(
            'test-file-1.txt',
            'test-file-2.json'
        )
    }
}
```

### Cleanup Patterns
```powershell
AfterEach {
    # Clean up test artifacts
    Get-ChildItem -Path $env:TEMP -Filter 'test-*' | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

AfterAll {
    # Remove test modules
    Get-Module | Where-Object { $_.Name -like 'Test*' } | Remove-Module -Force
}
```

## Test Execution Guidelines

### Local Testing
```powershell
# Run specific module tests
Invoke-Pester -Path "tests/unit/modules/ModuleName" -Output Detailed

# Run with coverage
Invoke-Pester -Path "tests/unit" -CodeCoverage "core-runner/modules/**/*.ps1"

# Run cross-platform tests
Invoke-Pester -Tag 'CrossPlatform' -Output Detailed
```

### Configuration
Tests should respect the project's Pester configuration in `tests/config/PesterConfiguration.psd1`.

### Continuous Integration
Tests must pass on all supported platforms before merging. Use appropriate skip conditions for platform-specific functionality.
