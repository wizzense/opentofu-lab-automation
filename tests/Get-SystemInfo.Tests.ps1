
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')


Describe '0200_Get-SystemInfo' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'LabRunner' 'LabRunner.psd1')
        $script:ScriptPath = Get-RunnerScriptPath '0200_Get-SystemInfo.ps1'
    }

    It 'runs without throwing and returns expected keys' {
        $result = & $script:ScriptPath -AsJson -Config @{}
        $obj = $result | ConvertFrom-Json
        $obj | Should -Not -BeNullOrEmpty
        $obj.PSObject.Properties.Name | Should -Contain 'ComputerName'
        $obj.PSObject.Properties.Name | Should -Contain 'IPAddresses'
        $obj.PSObject.Properties.Name | Should -Contain 'OSVersion'
        $obj.PSObject.Properties.Name | Should -Contain 'DiskInfo'
        if ($IsWindows) {
            $obj.PSObject.Properties.Name | Should -Contain 'RolesFeatures'
            $obj.PSObject.Properties.Name | Should -Contain 'LatestHotfix'
        }
    }

    It 'returns exit code 1 for unsupported platform' {
        Mock Get-Platform { 'Solaris' }
        try {
            & $script:ScriptPath -Config @{} -AsJson | Out-Null
            $code = $LASTEXITCODE
        } catch {
            $code = 1
        }
        $code | Should -Be 1
    }
}

Describe 'runner.ps1 executing 0200_Get-SystemInfo' {
    It 'outputs system info when run via runner' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner.ps1') -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'LabRunner') -Destination (Join-Path $tempDir 'lab_utils' 'LabRunner') -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'configs' 'config_files') -Destination (Join-Path $tempDir 'configs' 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'pwsh' 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            Copy-Item $script:ScriptPath -Destination $scriptsDir

        Push-Location $tempDir
        $pwsh = (Get-Command pwsh).Source
        $output = & $pwsh -NoLogo -NoProfile -File './runner.ps1' -Scripts '0200' -Auto
        $code   = $LASTEXITCODE
        Pop-Location

        $code | Should -Be 0
        $text = $output -join [Environment]::NewLine
        $text | Should -Match 'ComputerName'
        $text | Should -Match 'IPAddresses'
        $text | Should -Match 'OSVersion'
        $text | Should -Match 'DiskInfo'
        if ($IsWindows) {
            $text | Should -Match 'RolesFeatures'
            $text | Should -Match 'LatestHotfix'
        }

        }
        finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}
