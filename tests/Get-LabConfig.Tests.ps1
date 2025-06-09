Describe 'Get-LabConfig' {

    It 'returns PSCustomObject for valid JSON' {
        $modulePath = Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1'
        . $modulePath
        $configPath = Join-Path $PSScriptRoot '..\config_files\default-config.json'
        $result = Get-LabConfig -Path $configPath
        $result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
    }

    It 'throws when file does not exist' {
        $modulePath = Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1'
        . $modulePath
        { Get-LabConfig -Path 'nonexistent.json' } | Should -Throw
    }

    It 'throws on invalid JSON' {
        $modulePath = Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1'
        . $modulePath
        $badFile = Join-Path $PSScriptRoot 'bad.json'
        Set-Content -Path $badFile -Value '{bad json}'
        try {
            { Get-LabConfig -Path $badFile } | Should -Throw
        } finally {
            Remove-Item $badFile

        }
    }
}
