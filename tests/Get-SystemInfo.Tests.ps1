. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }

Describe '0200_Get-SystemInfo' -Skip:($IsLinux -or $IsMacOS) {
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
        $obj.PSObject.Properties.Name | Should -Contain 'RolesFeatures'
        $obj.PSObject.Properties.Name | Should -Contain 'LatestHotfix'
    }
}
