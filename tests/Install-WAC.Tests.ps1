. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0106_Install-WAC' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0106_Install-WAC.ps1'
    }

    It 'installs WAC when not installed and port free' {
        $cfg = [pscustomobject]@{ InstallWAC = $true; WAC = @{ InstallPort = 6516 } }
        Mock Get-WacRegistryInstallation { $null }
        Mock Get-NetTCPConnection { $null } -ParameterFilter { $LocalPort -eq 6516 }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 1
        Assert-MockCalled Start-Process -Times 1
    }

    It 'skips when InstallWAC is false' {
        $cfg = [pscustomobject]@{ InstallWAC = $false; WAC = @{ InstallPort = 6516 } }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }

    It 'skips when WAC already installed' {
        $cfg = [pscustomobject]@{ InstallWAC = $true; WAC = @{ InstallPort = 6516 } }
        Mock Get-WacRegistryInstallation { @{ DisplayName='Windows Admin Center' } }
        Mock Get-NetTCPConnection { $null }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }

    It 'skips when port already in use' {
        $cfg = [pscustomobject]@{ InstallWAC = $true; WAC = @{ InstallPort = 6516 } }
        Mock Get-WacRegistryInstallation { $null }
        Mock Get-NetTCPConnection { @{ } } -ParameterFilter { $LocalPort -eq 6516 }
        Mock Invoke-WebRequest {}
        Mock Start-Process {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 0
        Assert-MockCalled Start-Process -Times 0
    }
}
