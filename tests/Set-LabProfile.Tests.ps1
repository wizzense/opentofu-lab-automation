



. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0216_Set-LabProfile' {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0216_Set-LabProfile.ps1'
    }
        It 'writes profile when flag enabled' {
        $cfg = [pscustomobject]@{ SetupLabProfile = $true }
        Mock Set-Content {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Set-Content -Times 1
    }
        It 'skips when flag disabled' {
        $cfg = [pscustomobject]@{ SetupLabProfile = $false }
        Mock Set-Content {}
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Set-Content -Times 0
    }
}


