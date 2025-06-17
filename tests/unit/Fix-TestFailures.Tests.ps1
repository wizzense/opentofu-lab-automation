#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Tests for Fix-TestFailures.ps1 script
.DESCRIPTION
    Comprehensive tests to validate the Fix-TestFailures script functionality
    before running it on the actual codebase.
#>

BeforeAll {
    # Set up test environment
    $script:TestsDir = Split-Path $PSScriptRoot -Parent
    $script:ProjectRoot = Split-Path $TestsDir -Parent
    $script:FixScript = Join-Path $ProjectRoot "Fix-TestFailures.ps1"
    
    # Mock Write-CustomLog function
    function global:Write-CustomLog {
        param(
            [string]$Message,
            [string]$Level = "INFO"
        )
        Write-Host "[$Level] $Message"
    }
    
    # Create temporary test directories for validation
    $script:TempTestDir = Join-Path ([System.IO.Path]::GetTempPath()) "test-fix-validation-$(Get-Random)"
    New-Item -Path $TempTestDir -ItemType Directory -Force | Out-Null
}

Describe "Fix-TestFailures Script Validation" {
    
    Context "Script File Validation" {
        It "should exist" {
            $FixScript | Should -Exist
        }
        
        It "should have valid PowerShell syntax" {
            { . $FixScript -WhatIf } | Should -Not -Throw
        }
        
        It "should support WhatIf parameter" {
            $content = Get-Content $FixScript -Raw
            $content | Should -Match "SupportsShouldProcess"
        }
    }
    
    Context "Function Definitions" {
        BeforeAll {
            # Dot source the script to load functions
            . $FixScript
        }
        
        It "should define Remove-UnusedVariables function" {
            Get-Command Remove-UnusedVariables -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "should define Remove-UnusedParameters function" {
            Get-Command Remove-UnusedParameters -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "should define Fix-ModuleStructure function" {
            Get-Command Fix-ModuleStructure -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "should define Update-ModuleManifests function" {
            Get-Command Update-ModuleManifests -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Remove-UnusedVariables Function" {
        BeforeAll {
            . $FixScript
            
            # Create test file with unused variables
            $testFile = Join-Path $TempTestDir "test-unused-vars.ps1"
            $testContent = @"
function Test-Function {
    param()
    
    `$usedVar = "I am used"
    `$unusedVar = "I am not used"
    `$anotherUnusedVar = "Also not used"
    
    Write-Output `$usedVar
}
"@
            Set-Content -Path $testFile -Value $testContent
        }
        
        It "should identify unused variables" {
            $result = Remove-UnusedVariables -FilePath $testFile -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "should not modify file in WhatIf mode" {
            $originalContent = Get-Content $testFile -Raw
            Remove-UnusedVariables -FilePath $testFile -WhatIf
            $newContent = Get-Content $testFile -Raw
            $newContent | Should -Be $originalContent
        }
    }
    
    Context "Remove-UnusedParameters Function" {
        BeforeAll {
            . $FixScript
            
            # Create test file with unused parameters
            $testFile = Join-Path $TempTestDir "test-unused-params.ps1"
            $testContent = @"
function Test-Function {
    param(
        [string]`$UsedParam,
        [string]`$UnusedParam,
        [int]`$AnotherUnusedParam
    )
    
    Write-Output `$UsedParam
}
"@
            Set-Content -Path $testFile -Value $testContent
        }
        
        It "should identify unused parameters" {
            $result = Remove-UnusedParameters -FilePath $testFile -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "should not modify file in WhatIf mode" {
            $originalContent = Get-Content $testFile -Raw
            Remove-UnusedParameters -FilePath $testFile -WhatIf
            $newContent = Get-Content $testFile -Raw
            $newContent | Should -Be $originalContent
        }
    }
    
    Context "Fix-ModuleStructure Function" {
        BeforeAll {
            . $FixScript
        }
          It "should handle non-existent src/pwsh directory gracefully" {
            { Fix-ModuleStructure -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Update-ModuleManifests Function" {
        BeforeAll {
            . $FixScript
            
            # Create test module structure
            $testModuleDir = Join-Path $TempTestDir "TestModule"
            New-Item -Path $testModuleDir -ItemType Directory -Force | Out-Null
            
            $manifestPath = Join-Path $testModuleDir "TestModule.psd1"
            $manifestContent = @"
@{
    ModuleVersion = '1.0.0'
    RootModule = 'TestModule.psm1'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
"@
            Set-Content -Path $manifestPath -Value $manifestContent
        }
        
        It "should process module manifests without errors" {
            { Update-ModuleManifests -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Main Script Execution" {
        It "should run in WhatIf mode without errors" {
            { & $FixScript -WhatIf } | Should -Not -Throw
        }
        
        It "should show what changes would be made" {
            $output = & $FixScript -WhatIf 2>&1
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Error Handling" {
        BeforeAll {
            . $FixScript
        }
        
        It "should handle invalid file paths gracefully" {
            { Remove-UnusedVariables -FilePath "C:\NonExistent\File.ps1" -WhatIf } | Should -Not -Throw
        }
        
        It "should handle files with syntax errors gracefully" {
            $badFile = Join-Path $TempTestDir "bad-syntax.ps1"
            Set-Content -Path $badFile -Value "This is not valid PowerShell {"
            { Remove-UnusedVariables -FilePath $badFile -WhatIf } | Should -Not -Throw
        }
    }
}

AfterAll {
    # Cleanup
    if (Test-Path $TempTestDir) {
        Remove-Item -Path $TempTestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
}
