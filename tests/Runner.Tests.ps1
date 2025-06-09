Describe 'runner.ps1 configuration' {
    It 'loads default configuration without errors' {
        $configPath = Join-Path $PSScriptRoot '..\config_files\default-config.json'
        { Get-Content -Raw $configPath | ConvertFrom-Json } | Should -Not -Throw
    }
}
