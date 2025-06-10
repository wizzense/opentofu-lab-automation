
. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-Platform.ps1')


Describe '0200_Get-SystemInfo' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0200_Get-SystemInfo.ps1'
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
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            Copy-Item $script:ScriptPath -Destination $scriptsDir

            Push-Location $tempDir
            $output = & "$tempDir/runner.ps1" -Scripts '0200' -Auto
            Pop-Location
            
            $text = $output | Out-String
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
