---
applyTo: "**/tests/**/*.ps1"
description: Testing standards and patterns for Pester test files
---

# Testing Standards Instructions

## Pester Test Structure

Use the enhanced TestFramework for all tests:

```powershell
# Required test file header
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'ScriptName Tests' {
    BeforeAll {
        # Setup test environment
        $script:TestConfig = [pscustomobject]@{
            TestProperty = "TestValue"
        }
    }
    
    Context 'Module Loading' {
        It 'should load required modules' {
            Get-Module LabRunner | Should -Not -BeNullOrEmpty
            Get-Module CodeFixer | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Functionality Tests' {
        It 'should execute without errors' {
            # Your test implementation
        }
    }
    
    AfterAll {
        # Cleanup test resources
    }
}
```

## Mock Patterns

Use standardized mocking for external dependencies:

```powershell
BeforeAll {
    # Mock external commands
    Mock Write-Host {}
    Mock Invoke-WebRequest { @{ Content = "mock response" } }
    Mock Test-Path { $true }
    
    # Mock LabRunner functions when needed
    Mock Write-CustomLog {} -ModuleName LabRunner
    Mock Invoke-LabStep {} -ModuleName LabRunner
}
```

## Test Scenarios

Use the TestFramework for complex scenario testing:

```powershell
$testScenarios = @(
    @{
        Name = "Valid Configuration"
        Config = [pscustomobject]@{ ValidProperty = "Value" }
        ExpectedResult = $true
        ShouldThrow = $false
    },
    @{
        Name = "Invalid Configuration"
        Config = [pscustomobject]@{ InvalidProperty = $null }
        ExpectedResult = $false
        ShouldThrow = $true
        ExpectedError = "Invalid configuration"
    }
)

foreach ($scenario in $testScenarios) {
    Context $scenario.Name {
        It "should handle scenario correctly" {
            if ($scenario.ShouldThrow) {
                { YourFunction -Config $scenario.Config } | Should -Throw "*$($scenario.ExpectedError)*"
            } else {
                $result = YourFunction -Config $scenario.Config
                $result | Should -Be $scenario.ExpectedResult
            }
        }
    }
}
```

## Performance Testing

Include performance expectations in tests:

```powershell
It 'should complete within acceptable time' {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    YourFunction -Config $TestConfig
    $stopwatch.Stop()
    $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000  # 5 seconds max
}
```

## Integration Testing

Test module integration properly:

```powershell
Context 'Module Integration' {
    It 'should integrate with CodeFixer' {
        # Test CodeFixer integration
        $result = Invoke-PowerShellLint -Path $TestScript -PassThru
        $result | Should -Not -BeNullOrEmpty
    }
    
    It 'should integrate with LabRunner' {
        # Test LabRunner integration
        Mock Invoke-LabStep { "Success" } -ModuleName LabRunner
        $result = YourScript -Config $TestConfig
        Should -Invoke Invoke-LabStep -ModuleName LabRunner -Times 1
    }
}
```

## Error Testing

Always test error conditions:

```powershell
Context 'Error Handling' {
    It 'should handle missing files gracefully' {
        { YourFunction -Path "NonExistentFile.ps1" } | Should -Throw "*File not found*"
    }
    
    It 'should validate parameters' {
        { YourFunction -Config $null } | Should -Throw "*Config cannot be null*"
    }
}
```

## Cross-Platform Testing

Include platform-specific test considerations:

```powershell
Context 'Cross-Platform Compatibility' {
    It 'should work on current platform' {
        $platform = Get-Platform
        # Test platform-specific behavior
        switch ($platform) {
            'Windows' { 
                # Windows-specific tests
            }
            'Linux' { 
                # Linux-specific tests
            }
            'macOS' { 
                # macOS-specific tests
            }
        }
    }
}
```

## Configuration and Workflow Testing

### YAML Validation Testing
Always test YAML configuration handling:

```powershell
Describe 'YAML Configuration Tests' {
    Context 'Valid YAML Files' {
        It 'should validate workflow files without errors' {
            $workflowFiles = Get-ChildItem ".github/workflows/*.yml" -ErrorAction SilentlyContinue
            
            if ($workflowFiles) {
                foreach ($file in $workflowFiles) {
                    { & "./scripts/validation/Invoke-YamlValidation.ps1" -Mode "Check" -Path $file.FullName } | Should -Not -Throw
                }
            }
        }
    }
    
    Context 'YAML Schema Validation' {
        It 'should validate against GitHub Actions schema' {
            $workflowFiles = Get-ChildItem ".github/workflows/*.yml" -ErrorAction SilentlyContinue
            
            foreach ($file in $workflowFiles) {
                $content = Get-Content $file.FullName -Raw
                $yaml = ConvertFrom-Yaml $content
                
                # Basic workflow structure validation
                $yaml.name | Should -Not -BeNullOrEmpty
                $yaml.on | Should -Not -BeNullOrEmpty
                $yaml.jobs | Should -Not -BeNullOrEmpty
            }
        }
    }
}
```

### Configuration File Testing
Test configuration file validation:

```powershell
Describe 'Configuration Validation' {
    It 'should validate all YAML configuration files' {
        $configFiles = Get-ChildItem "configs/*.yml", "configs/*.yaml" -ErrorAction SilentlyContinue
        
        foreach ($file in $configFiles) {
            { ConvertFrom-Yaml (Get-Content $file.FullName -Raw) } | Should -Not -Throw
        }
    }
    
    It 'should validate JSON configuration files' {
        Import-Module "/pwsh/modules/CodeFixer/" -Force
        
        $jsonFiles = Get-ChildItem "*.json", "configs/*.json" -ErrorAction SilentlyContinue
        
        foreach ($file in $jsonFiles) {
            { Test-JsonConfig -Path $file.FullName } | Should -Not -Throw
        }
    }
}
```
