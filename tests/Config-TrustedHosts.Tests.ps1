Describe '0114_Config-TrustedHosts' {
    It 'calls Start-Process with winrm arguments using config value' -Skip:($IsLinux -or $IsMacOS) {
        $script = Join-Path $PSScriptRoot '..\runner_scripts\0114_Config-TrustedHosts.ps1'
        $config = [pscustomobject]@{
            SetTrustedHosts = $true
            TrustedHosts    = 'host1'
        }

        Mock Start-Process {}

        & $script -Config $config

        Assert-MockCalled Start-Process -ParameterFilter {
            $FilePath -eq 'cmd.exe' -and $ArgumentList -match 'TrustedHosts=\"host1\"'
        } -Times 1
    }
}

