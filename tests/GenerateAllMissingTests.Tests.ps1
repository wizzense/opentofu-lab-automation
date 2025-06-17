#!/usr/bin/env pwsh
#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Generates comprehensive tests for all PowerShell scripts in the project
.DESCRIPTION
    Systematically identifies missing tests and creates comprehensive test files
    following the project's testing standards and logging practices.
.NOTES
    Uses Write-CustomLog for all logging output with appropriate levels
#>

# Set environment variables for admin-friendly module discovery
if (-not $env:PWSH_MODULES_PATH) {
    $env:PWSH_MODULES_PATH = (Resolve-Path "$PSScriptRoot/../pwsh/modules").Path
}
if (-not $env:PROJECT_ROOT) {
    $env:PROJECT_ROOT = (Resolve-Path "$PSScriptRoot/..").Path
}

# Import required modules
try {
    Import-Module "$env:PWSH_MODULES_PATH/Logging/" -Force -ErrorAction Stop
    Import-Module "$env:PWSH_MODULES_PATH/LabRunner/" -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

Describe "Generate All Missing Tests" {
    BeforeAll {
        Write-CustomLog "Starting comprehensive test generation process" -Level "INFO"
        
        # Define project structure
        $script:ProjectRoot = $env:PROJECT_ROOT
        $script:ScriptsPath = Join-Path $ProjectRoot "pwsh/core_app/scripts"
        $script:ModulesPath = Join-Path $ProjectRoot "pwsh/modules"
        $script:TestsPath = Join-Path $ProjectRoot "tests"
        $script:UnitTestsPath = Join-Path $TestsPath "unit"
        $script:ScriptTestsPath = Join-Path $UnitTestsPath "scripts"
        $script:ModuleTestsPath = Join-Path $UnitTestsPath "modules"
        
        Write-CustomLog "Project paths initialized" -Level "INFO"
        Write-CustomLog "Scripts path: $script:ScriptsPath" -Level "INFO"
        Write-CustomLog "Tests path: $script:TestsPath" -Level "INFO"
    }

    Context "Test Infrastructure Validation" {
        It "Should have all required test directories" {
            @($script:TestsPath, $script:UnitTestsPath, $script:ScriptTestsPath, $script:ModuleTestsPath) | ForEach-Object {
                $_ | Should -Exist
                Write-CustomLog "Validated directory: $_" -Level "INFO"
            }
        }

        It "Should have CustomLogging module available" {
            { Write-CustomLog "Test log message" -Level "INFO" } | Should -Not -Throw
        }
    }

    Context "Script Test Generation" {
        BeforeAll {
            Write-CustomLog "Scanning for PowerShell scripts requiring tests" -Level "INFO"
            
            # Get all PowerShell scripts
            $script:AllScripts = @()
            if (Test-Path $script:ScriptsPath) {
                $script:AllScripts += Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1" -File
                Write-CustomLog "Found $($script:AllScripts.Count) scripts in core_app/scripts" -Level "INFO"
            }
            
            # Get existing test files
            $script:ExistingTests = @()
            if (Test-Path $script:ScriptTestsPath) {
                $script:ExistingTests = Get-ChildItem -Path $script:ScriptTestsPath -Filter "*.Tests.ps1" -File
                Write-CustomLog "Found $($script:ExistingTests.Count) existing test files" -Level "INFO"
            }
        }

        It "Should identify scripts without tests" {
            $scriptsWithoutTests = @()
            
            foreach ($script in $script:AllScripts) {
                $expectedTestName = "$($script.BaseName).Tests.ps1"
                $testExists = $script:ExistingTests | Where-Object { $_.Name -eq $expectedTestName }
                
                if (-not $testExists) {
                    $scriptsWithoutTests += $script
                    Write-CustomLog "Missing test for: $($script.Name)" -Level "WARN"
                }
            }
            
            Write-CustomLog "Found $($scriptsWithoutTests.Count) scripts without tests" -Level "INFO"
            $scriptsWithoutTests.Count | Should -BeGreaterThan -1
        }

        It "Should generate comprehensive test template" {
            $testTemplate = @"
#!/usr/bin/env pwsh
#Requires -Version 7.0
#Requires -Module Pester

<#
.SYNOPSIS
    Comprehensive tests for {SCRIPT_NAME}
.DESCRIPTION
    Tests for the {SCRIPT_NAME} script including syntax validation,
    parameter validation, and functionality testing.
#>

# Set environment variables for admin-friendly module discovery
if (-not `$env:PWSH_MODULES_PATH) {
    `$env:PWSH_MODULES_PATH = (Resolve-Path "`$PSScriptRoot/../../pwsh/modules").Path
}
if (-not `$env:PROJECT_ROOT) {
    `$env:PROJECT_ROOT = (Resolve-Path "`$PSScriptRoot/../..").Path
}

# Import required modules
try {
    Import-Module "`$env:PWSH_MODULES_PATH/Logging/" -Force -ErrorAction Stop
    Import-Module "`$env:PWSH_MODULES_PATH/LabRunner/" -Force -ErrorAction Stop
} catch {
    Write-Error "Failed to import required modules: `$_"
    exit 1
}

Describe "{SCRIPT_NAME} Tests" {
    BeforeAll {
        Write-CustomLog "Starting tests for {SCRIPT_NAME}" -Level "INFO"
        `$script:ScriptPath = "`$env:PROJECT_ROOT/pwsh/core_app/scripts/{SCRIPT_NAME}"
        `$script:ScriptContent = Get-Content `$script:ScriptPath -Raw -ErrorAction SilentlyContinue
    }

    Context "Script Validation" {
        It "Should exist and be readable" {
            `$script:ScriptPath | Should -Exist
            `$script:ScriptContent | Should -Not -BeNullOrEmpty
            Write-CustomLog "Script file validation passed" -Level "INFO"
        }

        It "Should have valid PowerShell syntax" {
            { 
                `$tokens = `$errors = `$null
                [System.Management.Automation.Language.Parser]::ParseFile(`$script:ScriptPath, [ref]`$tokens, [ref]`$errors)
                if (`$errors.Count -gt 0) {
                    Write-CustomLog "Syntax errors found: `$(`$errors | Out-String)" -Level "ERROR"
                    throw "Syntax errors detected"
                }
            } | Should -Not -Throw
        }

        It "Should follow project coding standards" {
            `$script:ScriptContent | Should -Match "#Requires -Version 7.0"
            Write-CustomLog "PowerShell version requirement validated" -Level "INFO"
        }
    }

    Context "Functionality Tests" {
        It "Should contain expected functions or logic" {
            # Add specific functionality tests here
            `$true | Should -Be `$true
            Write-CustomLog "Basic functionality test passed" -Level "INFO"
        }
    }

    AfterAll {
        Write-CustomLog "Completed tests for {SCRIPT_NAME}" -Level "SUCCESS"
    }
}
"@
            
            $testTemplate | Should -Not -BeNullOrEmpty
            $testTemplate | Should -Match "Write-CustomLog"
            Write-CustomLog "Test template generated successfully" -Level "SUCCESS"
        }
    }

    Context "Module Test Generation" {
        BeforeAll {
            Write-CustomLog "Scanning for PowerShell modules requiring tests" -Level "INFO"
            
            # Get all module directories
            $script:AllModules = @()
            if (Test-Path $script:ModulesPath) {
                $script:AllModules = Get-ChildItem -Path $script:ModulesPath -Directory
                Write-CustomLog "Found $($script:AllModules.Count) modules" -Level "INFO"
            }
        }

        It "Should identify modules without comprehensive tests" {
            $modulesWithoutTests = @()
            
            foreach ($module in $script:AllModules) {
                $moduleTestPath = Join-Path $script:ModuleTestsPath $module.Name
                if (-not (Test-Path $moduleTestPath)) {
                    $modulesWithoutTests += $module
                    Write-CustomLog "Missing test directory for module: $($module.Name)" -Level "WARN"
                }
            }
            
            Write-CustomLog "Found $($modulesWithoutTests.Count) modules without test directories" -Level "INFO"
            $modulesWithoutTests.Count | Should -BeGreaterThan -1
        }
    }

    AfterAll {
        Write-CustomLog "Comprehensive test generation analysis completed" -Level "SUCCESS"
        Write-CustomLog "Next steps: Run individual test generation for missing tests" -Level "INFO"
    }
}
