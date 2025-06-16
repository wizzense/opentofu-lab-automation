






. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0100_Enable-WinRM' -Skip:($SkipNonWindows) {
    BeforeAll {
        Enable-WindowsMocks
        $script:ScriptPath = Get-RunnerScriptPath '0100_Enable-WinRM.ps1'
    }
        It 'enables WinRM when service is not running' {
        $cfg = [pscustomobject]@{}
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } } -ParameterFilter { $Name -eq 'WinRM' }
        Mock Enable-PSRemoting {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Enable-PSRemoting -Times 1 -ParameterFilter { $Force }
    }
        It 'skips enabling when WinRM already running' {
        $cfg = [pscustomobject]@{}
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } } -ParameterFilter { $Name -eq 'WinRM' }
        Mock Enable-PSRemoting {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Enable-PSRemoting -Times 0
    }
}



