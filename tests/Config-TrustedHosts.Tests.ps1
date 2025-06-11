. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '0114_Config-TrustedHosts'  {
    It 'calls Start-Process with winrm arguments using config value' {

        $script = Get-RunnerScriptPath '0114_Config-TrustedHosts.ps1'
        $config = [pscustomobject]@{
            SetTrustedHosts = $true
            TrustedHosts    = 'host1'
        }

        Mock Start-Process {}

        & $script -Config $config

        $expected = '/d /c winrm set winrm/config/client @{TrustedHosts="host1"}'

        Should -Invoke -CommandName Start-Process -Times 1 -ParameterFilter {
            $FilePath -eq 'cmd.exe' -and $ArgumentList -eq $expected
        }
    }
}

