. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe '0006_Install-ValidationTools' -Skip:($SkipNonWindows) {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0006_Install-ValidationTools.ps1'
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner' 'Logger.ps1')
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
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -eq $cfg.CosignURL }
    }

    It 'checks for gpg when InstallGpg is true' {
        $cfg = [pscustomobject]@{ InstallGpg = $true }
        Mock Get-Command {} -ParameterFilter { $Name -eq 'gpg' }
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Get-Command -Times 1 -ParameterFilter { $Name -eq 'gpg' }
    }

    It 'logs a message when no option specified' {
        $cfg = [pscustomobject]@{ InstallCosign = $false; InstallGpg = $false }
        Mock-WriteLog
        & $script:ScriptPath -Config $cfg
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -like 'No installation option*' }
    }
}
