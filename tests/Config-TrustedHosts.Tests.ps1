. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe '0114_Config-TrustedHosts' -Skip:($IsLinux -or $IsMacOS) {
    It 'calls Start-Process with winrm arguments using config value' {
        $script = Join-Path $PSScriptRoot '..' 'runner_scripts' '0114_Config-TrustedHosts.ps1'
        $config = [pscustomobject]@{
            SetTrustedHosts = $true
            TrustedHosts    = 'host1'
        }

        Mock Start-Process {}

        & $script -Config $config

        $expected = '/d /c winrm set winrm/config/client @{TrustedHosts="host1"}'

        Assert-MockCalled Start-Process -ParameterFilter {
            $FilePath -eq 'cmd.exe' -and $ArgumentList -eq $expected
        } -Times 1
    }
}

