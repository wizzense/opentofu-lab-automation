. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0008_Install-OpenTofu' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll { $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0008_Install-OpenTofu.ps1' }

    It 'calls OpenTofuInstaller when enabled' {
        $cfg = [pscustomobject]@{
            InstallOpenTofu = $true
            CosignPath      = 'C:\\temp'
            OpenTofuVersion = '1.2.3'
        }
        $installerPath = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1')).Path
        Mock $installerPath {}
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled $installerPath -Times 1 -ParameterFilter {
            $installMethod -eq 'standalone' -and
            $cosignPath -eq (Join-Path $cfg.CosignPath 'cosign-windows-amd64.exe') -and
            $opentofuVersion -eq $cfg.OpenTofuVersion
        }
    }

    It 'skips install when flag is false' {
        $cfg = [pscustomobject]@{ InstallOpenTofu = $false }
        $installerPath = (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1')).Path
        Mock $installerPath {}
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled $installerPath -Times 0
    }
}
