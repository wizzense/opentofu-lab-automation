



. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Get-LabConfig' {

    It 'returns PSCustomObject for valid JSON and populates Directories' {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        . $modulePath
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.json')
        @{
            InfraRepoPath = 'C:\\Infra'
        } | ConvertTo-Json | Set-Content -Path $tempFile
        try {
            $result = Get-LabConfig -Path $tempFile
            $result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
            $result | Get-Member -Name Directories | Should -Not -BeNullOrEmpty
            $result.Directories.InfraRepo | Should -Be 'C:\\Infra'
            $result.Directories.RunnerScripts | Should -Match 'pwsh/runner_scripts$'
        } finally {
            Remove-Item $tempFile
        }
    }
        It 'uses custom Directories from JSON file' {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        . $modulePath
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.json')
        @{
            InfraRepoPath = 'C:\\Infra'
            Directories   = @{
                HyperVPath   = 'D:\\HyperV'
                IsoSharePath = 'D:\\ISO'
            }
        } | ConvertTo-Json | Set-Content -Path $tempFile
        try {
            $result = Get-LabConfig -Path $tempFile
            $result.Directories.HyperVPath   | Should -Be 'D:\\HyperV'
            $result.Directories.IsoSharePath | Should -Be 'D:\\ISO'
        } finally {
            Remove-Item $tempFile
        }
    }
        It 'throws when file does not exist' {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        . $modulePath
        { Get-LabConfig -Path 'nonexistent.json' } | Should -Throw
    }
        It 'throws on invalid JSON' {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        . $modulePath
        $badFile = Join-Path $PSScriptRoot 'bad.json'
        Set-Content -Path $badFile -Value '{bad json}'
        try {
            { Get-LabConfig -Path $badFile } | Should -Throw
        } finally {
            Remove-Item $badFile

        }
    }
        It 'parses valid YAML' -Skip:(-not (Get-Module -ListAvailable 'powershell-yaml')) {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Get-LabConfig.ps1'
        . $modulePath
        $yamlFile = Join-Path $PSScriptRoot 'test.yaml'
        "foo: bar" | Set-Content -Path $yamlFile
        try {
            $result = Get-LabConfig -Path $yamlFile
            $result.foo | Should -Be 'bar'
        } finally {
            Remove-Item $yamlFile
        }
    }
}



