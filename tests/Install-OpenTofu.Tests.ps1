



. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0008_Install-OpenTofu'  {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0008_Install-OpenTofu.ps1'
        . $script:ScriptPath
    }
    BeforeEach {
        Mock Invoke-OpenTofuInstaller {}
        Mock-WriteLog
    }
        It 'calls OpenTofuInstaller when enabled' {
        $cfg = [pscustomobject]@{
            InstallOpenTofu = $true
            CosignPath      = 'C:\\temp'
            OpenTofuVersion = '1.9.1'
        }

        
        Install-OpenTofu -Config $cfg

        Should -Invoke -CommandName Invoke-OpenTofuInstaller -Times 1 -ParameterFilter {
            $CosignPath -eq (Join-Path $cfg.CosignPath 'cosign-windows-amd64.exe') -and
            $OpenTofuVersion -eq $cfg.OpenTofuVersion
        }
    }
        It 'skips install when flag is false' {
        $cfg = [pscustomobject]@{ InstallOpenTofu = $false }

        Install-OpenTofu -Config $cfg

        Should -Invoke -CommandName Invoke-OpenTofuInstaller -Times 0
    }
}


