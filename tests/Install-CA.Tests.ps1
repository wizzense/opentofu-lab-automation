. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }

if ($IsLinux -or $IsMacOS) { return }

# Skip entirely if the required Windows modules are unavailable
if (-not (Get-Module -ListAvailable -Name 'ServerManager') -or
    -not (Get-Module -ListAvailable -Name 'ADCSDeployment')) {
    return
}

Describe '0104_Install-CA script' {
    BeforeAll {
        $scriptPath = Get-RunnerScriptPath '0104_Install-CA.ps1'
    }
    AfterEach {
        Remove-Item Function:Install-AdcsCertificationAuthority -ErrorAction SilentlyContinue
    }

    It 'invokes CA installation when InstallCA is true' -Skip:($SkipNonWindows) {
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
        $config = [pscustomobject]@{
            InstallCA = $true
            CertificateAuthority = @{ CommonName = 'TestCA'; ValidityYears = 1 }
        }
        Mock-WriteLog
        Mock Get-WindowsFeature { @{ Installed = $false } } -ParameterFilter { $Name -eq 'Adcs-Cert-Authority' }
        Mock Install-WindowsFeature {}
        Mock Get-Item { $null }
        function global:Install-AdcsCertificationAuthority {}
        Mock Install-AdcsCertificationAuthority {}

        & $scriptPath -Config $config -Confirm:$false

        Should -Invoke -CommandName Install-AdcsCertificationAuthority -Times 1 -ParameterFilter {
            $CACommonName -eq 'TestCA' -and $CAType -eq 'StandaloneRootCA'
        }
    }

    It 'skips CA installation when InstallCA is false' -Skip:($SkipNonWindows) {
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
        $config = [pscustomobject]@{
            InstallCA = $false
            CertificateAuthority = @{ CommonName = 'TestCA'; ValidityYears = 1 }
        }
        Mock-WriteLog
        function global:Install-AdcsCertificationAuthority {}
        Mock Install-AdcsCertificationAuthority {}

        & $scriptPath -Config $config -Confirm:$false

        Should -Invoke -CommandName Install-AdcsCertificationAuthority -Times 0
    }
}
