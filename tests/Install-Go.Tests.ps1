. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'LabSetup' 'LabSetup.psd1') -Force
InModuleScope LabSetup {
Describe '0007_Install-Go'  {
    BeforeAll { $script:ScriptPath = Get-RunnerScriptPath '0007_Install-Go.ps1' }
    BeforeEach {
        Mock Start-Process {}
        Mock-WriteLog
    }

    It 'installs Go when enabled' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Get-Command {} -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest -ModuleName LabSetup {} -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl }
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl }
        Should -Invoke -CommandName Start-Process -Times 1 -ParameterFilter { $FilePath -eq 'msiexec.exe' }
    }

    It 'skips when InstallGo is false' {
        $cfg = [pscustomobject]@{ InstallGo = $false; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Invoke-WebRequest -ModuleName LabSetup {} -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl }
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
        Should -Invoke -CommandName Start-Process -Times 0
    }

    It 'does nothing when Go is already installed' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Get-Command { @{ Name = 'go' } } -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest -ModuleName LabSetup {} -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl }
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
        Should -Invoke -CommandName Start-Process -Times 0
    }
}
}
