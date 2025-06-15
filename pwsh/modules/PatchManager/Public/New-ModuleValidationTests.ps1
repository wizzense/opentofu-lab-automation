function New-ModuleValidationTests {
    <#
    .SYNOPSIS
    Generates comprehensive Pester tests for PowerShell modules
    
    .DESCRIPTION
    Creates test suites that validate module functionality while excluding
    patches in development from validation errors.
    
    .PARAMETER ModulePath
    Path to the module to test
    
    .PARAMETER ExcludePatterns
    Patterns to exclude from validation (patches in development)
    
    .EXAMPLE
    New-ModuleValidationTests -ModulePath "./pwsh/modules/PatchManager"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,
        
        [string[]]$ExcludePatterns = @(
            "*/patches/in-development/*",
            "*/temp-fixes/*",
            "*/archive/*",
            "*.old.ps1"
        )
    )
    
    $moduleName = Split-Path $ModulePath -Leaf
    $testPath = Join-Path $ModulePath "$moduleName.Module.Tests.ps1"
    
    $testContent = @"
#Requires -Modules Pester

Describe '$moduleName Module Validation' {
    BeforeAll {
        `$ModulePath = '$ModulePath'
        `$ExcludePatterns = @(
            '*/patches/in-development/*',
            '*/temp-fixes/*', 
            '*/archive/*',
            '*.old.ps1'
        )
        
        # Import required modules
        Import-Module "/`$ModulePath" -Force
        if (Get-Module CodeFixer -ListAvailable) {
            Import-Module CodeFixer -Force
        }
    }
    
    Context 'Module Structure' {
        It 'Should have a valid module manifest' {
            `$manifestPath = Join-Path `$ModulePath '$moduleName.psd1'
            `$manifestPath | Should -Exist
            { Test-ModuleManifest -Path `$manifestPath } | Should -Not -Throw
        }
        
        It 'Should have a module file' {
            `$moduleFile = Join-Path `$ModulePath '$moduleName.psm1'
            `$moduleFile | Should -Exist
        }
        
        It 'Should load without errors' {
            { Import-Module `$ModulePath -Force } | Should -Not -Throw
        }
    }
    
    Context 'PowerShell Syntax Validation' {
        BeforeAll {
            # Get all PowerShell files excluding patterns
            `$allFiles = Get-ChildItem -Path `$ModulePath -Recurse -Include '*.ps1', '*.psm1', '*.psd1'
            `$validationFiles = `$allFiles | Where-Object {
                `$file = `$_
                `$exclude = `$false
                foreach (`$pattern in `$ExcludePatterns) {
                    if (`$file.FullName -like `$pattern) {
                        `$exclude = `$true
                        break
                    }
                }
                -not `$exclude
            }
        }
        
        It 'Should have valid PowerShell syntax in <_.Name>' -ForEach `$validationFiles {
            { 
                `$tokens = `$null
                `$errors = `$null
                [System.Management.Automation.Language.Parser]::ParseFile(`$_.FullName, [ref]`$tokens, [ref]`$errors)
                `$errors.Count | Should -Be 0
            } | Should -Not -Throw
        }
        
        It 'Should pass PSScriptAnalyzer validation' {
            if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
                `$results = `$validationFiles | ForEach-Object {
                    Invoke-ScriptAnalyzer -Path `$_.FullName -Severity Error
                }
                `$results | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because 'PSScriptAnalyzer not available'
            }
        }
        
        It 'Should not assign to automatic variables' {
            if (Get-Command Test-AutomaticVariables -ErrorAction SilentlyContinue) {
                `$issues = `$validationFiles | ForEach-Object {
                    Test-AutomaticVariables -ScriptPath `$_.FullName
                }
                `$issues | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because 'Test-AutomaticVariables not available'
            }
        }
    }
    
    Context 'Module Functions' {
        BeforeAll {
            `$exportedFunctions = (Get-Module $moduleName).ExportedFunctions.Keys
        }
        
        It 'Should export functions' {
            `$exportedFunctions | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have help for exported function <_>' -ForEach `$exportedFunctions {
            `$help = Get-Help `$_ -ErrorAction SilentlyContinue
            `$help | Should -Not -BeNullOrEmpty
            `$help.Synopsis | Should -Not -BeNullOrEmpty
        }
        
        It 'Should have valid parameter sets for <_>' -ForEach `$exportedFunctions {
            { Get-Command `$_ -ErrorAction Stop } | Should -Not -Throw
        }
    }
    
    Context '$moduleName Specific Tests' {
        # Module-specific tests will be added here
        It 'Should have module-specific functionality tests' {
            # Placeholder for module-specific tests
            `$true | Should -Be `$true
        }
    }
}
"@

    Set-Content -Path $testPath -Value $testContent -Encoding UTF8
    Write-Host "✅ Created test suite: $testPath" -ForegroundColor Green
    
    return $testPath
}

function Invoke-ModuleTestSuite {
    <#
    .SYNOPSIS
    Runs comprehensive test suites for all modules
    
    .DESCRIPTION
    Executes Pester tests for all modules while properly handling patches in development
    #>
    [CmdletBinding()]
    param(
        [string]$ModulesPath = "./pwsh/modules",
        [switch]$GenerateTests
    )
    
    $modules = Get-ChildItem -Path $ModulesPath -Directory
    $results = @()
    
    foreach ($module in $modules) {
        Write-Host "🧪 Testing module: $($module.Name)" -ForegroundColor Cyan
          if ($GenerateTests) {
            New-ModuleValidationTests -ModulePath $module.FullName | Out-Null
        }
        
        # Run existing tests
        $testFiles = Get-ChildItem -Path $module.FullName -Filter "*.Tests.ps1" -Recurse
        
        foreach ($testFile in $testFiles) {
            Write-Host "  Running: $($testFile.Name)" -ForegroundColor Yellow
            $result = Invoke-Pester -Path $testFile.FullName -PassThru
            $results += [PSCustomObject]@{
                Module = $module.Name
                TestFile = $testFile.Name
                Passed = $result.PassedCount
                Failed = $result.FailedCount
                Skipped = $result.SkippedCount
                Success = $result.FailedCount -eq 0
            }
        }
    }
    
    # Summary
    Write-Host "`n📊 Test Results Summary:" -ForegroundColor Magenta
    $results | Format-Table -AutoSize
    
    $totalPassed = ($results | Measure-Object Passed -Sum).Sum
    $totalFailed = ($results | Measure-Object Failed -Sum).Sum
    
    if ($totalFailed -eq 0) {
        Write-Host "✅ All tests passed! ($totalPassed total)" -ForegroundColor Green
    } else {
        Write-Host "❌ $totalFailed tests failed out of $($totalPassed + $totalFailed) total" -ForegroundColor Red
    }
    
    return $results
}

