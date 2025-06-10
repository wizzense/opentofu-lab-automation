. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0008_Install-OpenTofu' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = (
            Resolve-Path (Join-Path $PSScriptRoot '..' 'runner_scripts' '0008_Install-OpenTofu.ps1')

        ).Path
        . $script:ScriptPath
    }

    It 'calls OpenTofuInstaller when enabled' {
        $cfg = [pscustomobject]@{
            InstallOpenTofu = $true
            CosignPath      = 'C:\\temp'
            OpenTofuVersion = '1.9.1'
        }

        Mock Invoke-OpenTofuInstaller {}
        Mock Write-CustomLog {}
        
        . $script:ScriptPath -Config $cfg

        Assert-MockCalled Invoke-OpenTofuInstaller -Times 1 -ParameterFilter {
            $CosignPath -eq (Join-Path $cfg.CosignPath 'cosign-windows-amd64.exe') -and
            $OpenTofuVersion -eq $cfg.OpenTofuVersion
        }
    }

    It 'skips install when flag is false' {
        $cfg = [pscustomobject]@{ InstallOpenTofu = $false }
        Mock Invoke-OpenTofuInstaller {}
        Mock Write-CustomLog {}

        . $script:ScriptPath -Config $cfg

        Assert-MockCalled Invoke-OpenTofuInstaller -Times 0
    }
}
