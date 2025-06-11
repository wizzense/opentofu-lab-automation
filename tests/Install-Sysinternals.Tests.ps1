. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'LabSetup' 'LabSetup.psd1') -Force
InModuleScope LabSetup {
Describe '0205_Install-Sysinternals' {
    BeforeAll { $script:ScriptPath = Get-RunnerScriptPath '0205_Install-Sysinternals.ps1' }

    It 'downloads and extracts when enabled' {
        $dest = Join-Path $env:TEMP ([guid]::NewGuid())
        $cfg  = [pscustomobject]@{ InstallSysinternals = $true; SysinternalsPath = $dest }
        Mock Invoke-LabWebRequest {}
        Mock Expand-Archive {}
        Mock New-Item {}
        Mock Test-Path { $false } -ParameterFilter { $Path -eq $dest }
        Mock Remove-Item {}
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-LabWebRequest -Times 1
        Should -Invoke -CommandName Expand-Archive -Times 1 -ParameterFilter { $DestinationPath -eq $dest }
    }

    It 'skips when InstallSysinternals is false' {
        $cfg = [pscustomobject]@{ InstallSysinternals = $false }
        Mock Invoke-LabWebRequest {}
        Mock Expand-Archive {}
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-LabWebRequest -Times 0
        Should -Invoke -CommandName Expand-Archive -Times 0
    }
}
}
