






. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Get-HyperVProviderVersion'  {
    It 'uses version from config' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $cfg = [pscustomobject]@{ HyperV = @{ ProviderVersion = '9.9.9' } }
        Get-HyperVProviderVersion -Config $cfg | Should -Be '9.9.9'
    }
        It 'falls back to default when not specified' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        Get-HyperVProviderVersion -Config ([pscustomobject]@{}) | Should -Be '1.2.1'
    }
}



