. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0007_Install-Go' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll { $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0007_Install-Go.ps1' }

    It 'installs Go when enabled' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go.msi' } }
        Mock Get-Command {} -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { $Uri -eq $cfg.Go.InstallerUrl } -Times 1
        Assert-MockCalled Start-Process -ParameterFilter { $FilePath -eq 'msiexec.exe' } -Times 1
    }

    It 'skips when InstallGo is false' {
        $cfg = [pscustomobject]@{ InstallGo = $false; Go = @{ InstallerUrl = 'http://example.com/go.msi' } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }

    It 'does nothing when Go is already installed' {
        $cfg = [pscustomobject]@{ InstallGo = $true; Go = @{ InstallerUrl = 'http://example.com/go.msi' } }
        Mock Get-Command { @{ Name = 'go' } } -ParameterFilter { $Name -eq 'go' }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }
}
