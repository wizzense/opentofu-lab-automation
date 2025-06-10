. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0105_Install-HyperV' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0105_Install-HyperV.ps1'
    }

    It 'installs Hyper-V when not present and flag enabled' {
        $cfg = [pscustomobject]@{ InstallHyperV = $true }
        Mock Get-WindowsFeature { [pscustomobject]@{ Installed = $false } } -ParameterFilter { $Name -eq 'Hyper-V' }
        Mock Install-WindowsFeature {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Install-WindowsFeature -Times 1 -ParameterFilter { $Name -eq 'Hyper-V' }
    }

    It 'skips install when already installed' {
        $cfg = [pscustomobject]@{ InstallHyperV = $true }
        Mock Get-WindowsFeature { [pscustomobject]@{ Installed = $true } } -ParameterFilter { $Name -eq 'Hyper-V' }
        Mock Install-WindowsFeature {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Install-WindowsFeature -Times 0
    }

    It 'does nothing when InstallHyperV is false' {
        $cfg = [pscustomobject]@{ InstallHyperV = $false }
        Mock Get-WindowsFeature { [pscustomobject]@{ Installed = $false } } -ParameterFilter { $Name -eq 'Hyper-V' }
        Mock Install-WindowsFeature {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Install-WindowsFeature -Times 0
    }
}
