. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe '0006_Install-ValidationTools' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0006_Install-ValidationTools.ps1'
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
    }

    It 'downloads cosign when InstallCosign is true' {
        $cfg = [pscustomobject]@{
            InstallCosign = $true
            CosignURL     = 'http://example.com/cosign.exe'
            CosignPath    = Join-Path $env:TEMP ([guid]::NewGuid())
        }
        Mock Invoke-WebRequest {}
        Mock New-Item {}
        Mock Test-Path { $false }
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -eq $cfg.CosignURL }
    }

    It 'checks for gpg when InstallGpg is true' {
        $cfg = [pscustomobject]@{ InstallGpg = $true }
        Mock Get-Command {} -ParameterFilter { $Name -eq 'gpg' }
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Get-Command -ParameterFilter { $Name -eq 'gpg' } -Times 1
    }

    It 'logs a message when no option specified' {
        $cfg = [pscustomobject]@{ InstallCosign = $false; InstallGpg = $false }
        Mock Write-CustomLog {}
        & $script:ScriptPath -Config $cfg
        Assert-MockCalled Write-CustomLog -ParameterFilter { $Message -like 'No installation option*' } -Times 1
    }
}
