# Required test file header
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Get-LabConfig Tests' {
    BeforeAll {
        # Dot-source the script directly for testing
        $script:ScriptPath = Join-Path $env:PROJECT_ROOT 'core-runner/modules/LabRunner/Get-LabConfig.ps1'
        . $script:ScriptPath

        # Create sample JSON and YAML config files
        $script:JsonPath = Join-Path $TestDrive 'config.json'
        @{ LabName = 'JsonLab' } | ConvertTo-Json | Set-Content -Path $script:JsonPath -Encoding UTF8

        $script:YamlPath = Join-Path $TestDrive 'config.yaml'
        "LabName: YamlLab" | Set-Content -Path $script:YamlPath -Encoding UTF8
    }

    Context 'Script Validation' {
        It 'script should exist' {
            $script:ScriptPath | Should -Exist
        }
    }

    Context 'JSON Loading' {
        It 'should parse JSON config' {
            $result = Get-LabConfig -Path $script:JsonPath
            $result.LabName | Should -Be 'JsonLab'
            $result.Directories | Should -Not -BeNullOrEmpty
        }
    }

    Context 'YAML Loading' {
        It 'should parse YAML config' {
            $result = Get-LabConfig -Path $script:YamlPath
            $result.LabName | Should -Be 'YamlLab'
            $result.Directories | Should -Not -BeNullOrEmpty
        }
    }

    AfterAll {
        # Cleanup test resources
    }
}

