. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0007_Install-Go' -Skip:($SkipNonWindows) {
    BeforeAll { $script:ScriptPath = Get-RunnerScriptPath '0007_Install-Go.ps1' }

    It 'installs Go when enabled' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Get-Command {} -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl } -Times 1
        Assert-MockCalled Start-Process -ParameterFilter { $FilePath -eq 'msiexec.exe' } -Times 1
    }

    It 'skips when InstallGo is false' {
        $cfg = [pscustomobject]@{ InstallGo = $false; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }

    It 'does nothing when Go is already installed' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go1.21.0.windows-amd64.msi' } }
        Mock Get-Command { @{ Name = 'go' } } -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }
}
