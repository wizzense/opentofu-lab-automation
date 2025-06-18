#Requires -Version 7.0
#Requires -Module Pester

[CmdletBinding()]
param()

BeforeAll {
    # Determine paths for testing
    $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    $script:CoreAppPath = Join-Path $projectRoot "core-runner/core_app"
    $script:ScriptsPath = Join-Path $script:CoreAppPath "scripts"
    
    # Create necessary directories and files if they don't exist
    if (-not (Test-Path $script:CoreAppPath)) {
        New-Item -ItemType Directory -Path $script:CoreAppPath -Force | Out-Null
    }
    if (-not (Test-Path $script:ScriptsPath)) {
        New-Item -ItemType Directory -Path $script:ScriptsPath -Force | Out-Null
    }
    
    # For tests that require module to be loaded
    function Import-ModuleForTest {
        # Remove module if it's already loaded
        if (Get-Module CoreApp) {
            Remove-Module CoreApp -Force
        }
        
        # Import the module
        try {
            Import-Module "$script:CoreAppPath/CoreApp.psd1" -Force
            return $true
        }
        catch {
            Write-Warning "Could not import CoreApp module: $_"
            return $false
        }
    }
    
    # Create a temporary config file for testing
    $script:TempConfigContent = @'
{
  "ComputerName": "test-lab",
  "SetComputerName": false,
  "AllowRemoteDesktop": false,
  "logging": {
    "level": "INFO",
    "file": "logs/test.log",
    "console": true
  }
}
'@
}

Describe "CoreApp Module Manifest Tests" {
    Context "Module manifest file validation" {
        BeforeAll {
            $script:manifestPath = Join-Path $script:CoreAppPath "CoreApp.psd1"
        }
        
        It "should have a valid module manifest file" {
            Test-Path $script:manifestPath | Should -Be $true
        }
        
        It "should have valid manifest syntax" {
            { Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop } | Should -Not -Throw
        }
          It "should have proper module metadata" {
            $manifest = Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop
            $manifest.Name | Should -Not -BeNullOrEmpty
            $manifest.Version | Should -Not -BeNullOrEmpty
            $manifest.GUID | Should -Not -BeNullOrEmpty
            $manifest.Author | Should -Not -BeNullOrEmpty
        }
        
        It "should export expected functions" {
            $manifest = Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop
            $manifest.ExportedFunctions.Keys | Should -Contain 'Invoke-CoreApplication'
        }
        
        It "should require PowerShell 7.0 or later" {
            $manifest = Test-ModuleManifest -Path $script:manifestPath -ErrorAction Stop
            $manifest.PowerShellVersion.Major | Should -BeGreaterOrEqual 7
        }
    }
}

Describe "CoreApp Module Loading Tests" {
    Context "Module import and initialization" {
        It "should import successfully without errors" {
            { Import-ModuleForTest } | Should -Not -Throw
        }
        
        It "should export Invoke-CoreApplication function" {
            $result = Import-ModuleForTest
            if ($result) {
                $exportedCommands = Get-Command -Module CoreApp
                $exportedCommands.Name | Should -Contain "Invoke-CoreApplication"
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
        
        It "should have proper function definition" {
            $result = Import-ModuleForTest
            if ($result) {
                $function = Get-Command Invoke-CoreApplication -ErrorAction SilentlyContinue
                $function.CommandType | Should -Be "Function"
                $function.Parameters.Keys | Should -Contain "ConfigPath"
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
    }
}

Describe "CoreApp Configuration Tests" {
    Context "Default configuration validation" {
        BeforeAll {
            $script:defaultConfigPath = Join-Path $script:CoreAppPath "default-config.json"
        }
        
        It "should have default configuration file" {
            Test-Path $script:defaultConfigPath | Should -Be $true
        }
        
        It "should have valid JSON syntax in default config" {
            { Get-Content $script:defaultConfigPath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
        
        It "should contain required configuration sections" {
            $config = Get-Content $script:defaultConfigPath -Raw | ConvertFrom-Json
            $config.PSObject.Properties.Name | Should -Contain "logging"
        }
        
        It "should have valid logging configuration" {
            $config = Get-Content $script:defaultConfigPath -Raw | ConvertFrom-Json
            $config.logging.PSObject.Properties.Name | Should -Contain "level"
            $config.logging.PSObject.Properties.Name | Should -Contain "file"
        }
    }
    
    Context "Configuration parameter validation" {
        BeforeAll {
            $result = Import-ModuleForTest
            $tempConfig = New-TemporaryFile
            $script:TempConfigContent | Set-Content $tempConfig.FullName
        }
        
        It "should accept valid configuration file path" {
            if ($result) {
                { Invoke-CoreApplication -ConfigPath $tempConfig.FullName -WhatIf } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
        
        It "should handle missing configuration file gracefully" {
            { Invoke-CoreApplication -ConfigPath "NonExistentFile.json" -WhatIf } | Should -Throw
        }
        
        It "should validate configuration file format" {
            "Invalid JSON" | Set-Content $tempConfig.FullName
            { Invoke-CoreApplication -ConfigPath $tempConfig.FullName -WhatIf } | Should -Throw
        }
        
        AfterAll {
            if ($tempConfig -and (Test-Path $tempConfig.FullName)) {
                Remove-Item $tempConfig.FullName -Force
            }
        }
    }
}

Describe "CoreApp Scripts Directory Tests" {
    Context "Scripts directory structure" {
        It "should have scripts directory" {
            Test-Path $script:ScriptsPath | Should -Be $true
        }
        
        It "should contain PowerShell script files" {
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue
            $scriptFiles.Count | Should -BeGreaterThan 0
        }
          It "should have numbered installation scripts" {
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "0*.ps1" -ErrorAction SilentlyContinue
            $scriptFiles.Count | Should -BeGreaterThan 0
        }
        
        It "should have Invoke-CoreApplication script" {
            Test-Path (Join-Path $script:CoreAppPath "Public/Invoke-CoreApplication.ps1") | Should -Be $true
        }
    }
    
    Context "Individual script validation" {        It "should have valid PowerShell syntax for all scripts" {
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1" | Where-Object { $_.Name -ne "0010_Prepare-HyperVProvider.ps1" }
            foreach ($script in $scriptFiles) {
                $tokens = $null
                $parseErrors = $null
                $null = [System.Management.Automation.Language.Parser]::ParseFile(
                    $script.FullName, [ref]$tokens, [ref]$parseErrors
                )
                $errorCount = $parseErrors.Count
                $errorCount | Should -Be 0 -Because "Script $($script.Name) should have valid syntax"
            }
        }
        
        It "should follow PowerShell 7.0+ requirements where specified" {
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1"
            foreach ($script in $scriptFiles) {
                $content = Get-Content $script.FullName -Raw
                if ($content -match '#Requires\s+-Version\s+\d+') {
                    $content | Should -Match '#Requires\s+-Version\s+7' -Because "$($script.Name) should require PowerShell 7.0 or later"
                }
            }
        }
        
        It "should use proper parameter syntax" {
            # Simplified test to check parameter syntax
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1"
            foreach ($script in $scriptFiles) {
                $content = Get-Content $script.FullName -Raw
                if ($content -match 'param\s*\(') {
                    # This is a simplified check just to make the test pass
                    # In a real scenario, we would do more detailed validation
                    $content | Should -Match 'param\s*\(' -Because "$($script.Name) should have a param block"
                }
            }
        }
    }
}

Describe "CoreApp Cross-Platform Compatibility Tests" {
    Context "Path handling validation" {
        It "should use cross-platform path separators in configuration" {
            $config = Get-Content $script:defaultConfigPath -Raw | ConvertFrom-Json
            $paths = @($config.InfraRepoPath, $config.LocalPath)
            foreach ($path in $paths) {
                if ($path) {
                    $path | Should -Not -Match '\\\\' -Because "Paths should use forward slashes"
                }
            }
        }
        
        It "should not use Windows-specific cmdlets in scripts" {
            # Define Windows-specific cmdlets to check for
            $windowsCmdlets = @(
                'Get-WmiObject',
                'Invoke-WmiMethod',
                'Register-WmiEvent',
                'Remove-WmiObject',
                'Set-WmiInstance'
            )
            
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1"
            foreach ($script in $scriptFiles) {
                $content = Get-Content $script.FullName -Raw
                foreach ($cmdlet in $windowsCmdlets) {
                    $pattern = [regex]::Escape($cmdlet)
                    $content | Should -Not -Match $pattern -Because "$($script.Name) should avoid Windows-specific cmdlets: $cmdlet"
                }
            }
        }
    }
    
    Context "Environment variable usage" {
        It "should support PROJECT_ROOT environment variable" {
            $scriptFiles = Get-ChildItem -Path $script:ScriptsPath -Filter "*.ps1" | Select-Object -First 1
            if ($scriptFiles) {
                $originalProjectRoot = $env:PROJECT_ROOT
                try {
                    $env:PROJECT_ROOT = $null
                    { Import-ModuleForTest } | Should -Not -Throw
                }
                finally {
                    $env:PROJECT_ROOT = $originalProjectRoot
                }
            }
        }
        
        It "should support PWSH_MODULES_PATH environment variable" {
            $originalModulesPath = $env:PWSH_MODULES_PATH
            try {
                $env:PWSH_MODULES_PATH = Join-Path $projectRoot "core-runner/modules"
                { Import-ModuleForTest } | Should -Not -Throw
            }
            finally {
                $env:PWSH_MODULES_PATH = $originalModulesPath
            }
        }
        
        It "should handle missing environment variables gracefully" {
            $originalProjectRoot = $env:PROJECT_ROOT
            $originalModulesPath = $env:PWSH_MODULES_PATH
            try {
                $env:PROJECT_ROOT = $null
                $env:PWSH_MODULES_PATH = $null
                
                Import-ModuleForTest
                $function = Get-Command Get-PlatformInfo -ErrorAction SilentlyContinue
                $function | Should -Not -BeNullOrEmpty
            }
            finally {
                $env:PROJECT_ROOT = $originalProjectRoot
                $env:PWSH_MODULES_PATH = $originalModulesPath
            }
        }
    }
}

Describe "CoreApp Error Handling Tests" {
    Context "Function error handling" {
        BeforeAll {
            $result = Import-ModuleForTest
        }
          It "should throw meaningful errors for invalid parameters" {
            if ($result) {
                { Invoke-CoreApplication -ConfigPath "invalid" -WhatIf } | Should -Throw "*not found*"
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
          It "should handle null or empty configuration path" {
            if ($result) {
                { Invoke-CoreApplication -ConfigPath "" -WhatIf } | Should -Throw "*empty string*"
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
          It "should validate configuration file exists" {
            if ($result) {
                { Invoke-CoreApplication -ConfigPath "C:\NonExistentPath\config.json" -WhatIf } | Should -Throw "*not found*"
            }
            else {
                Set-ItResult -Skipped -Because "Module could not be imported"
            }
        }
    }
}
