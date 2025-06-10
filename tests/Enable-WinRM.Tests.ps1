. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0100_Enable-WinRM' -Skip:($SkipNonWindows) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0100_Enable-WinRM.ps1'
    }

    It 'enables WinRM when service is not running' {
        $cfg = [pscustomobject]@{}
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } } -ParameterFilter { $Name -eq 'WinRM' }
        Mock Enable-PSRemoting {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Enable-PSRemoting -ParameterFilter { $Force } -Times 1
    }

    It 'skips enabling when WinRM already running' {
        $cfg = [pscustomobject]@{}
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } } -ParameterFilter { $Name -eq 'WinRM' }
        Mock Enable-PSRemoting {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Enable-PSRemoting -Times 0
    }
}
