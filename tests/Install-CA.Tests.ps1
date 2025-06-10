. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe '0104_Install-CA script' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0104_Install-CA.ps1'
    }

    It 'invokes CA installation when InstallCA is true' -Skip:($IsLinux -or $IsMacOS) {
        . (Join-Path $PSScriptRoot '..\runner_utility_scripts\Logger.ps1')
        $config = [pscustomobject]@{
            InstallCA = $true
            CertificateAuthority = @{ CommonName = 'TestCA'; ValidityYears = 1 }
        }
        Mock Write-CustomLog {}
        Mock Get-WindowsFeature { @{ Installed = $false } } -ParameterFilter { $Name -eq 'Adcs-Cert-Authority' }
        Mock Install-WindowsFeature {}
        Mock Get-Item { $null }
        Mock Install-AdcsCertificationAuthority {}

        . $scriptPath
        Install-CA -Config $config

        Assert-MockCalled Install-AdcsCertificationAuthority -Times 1
    }

    It 'skips CA installation when InstallCA is false' -Skip:($IsLinux -or $IsMacOS) {
        . (Join-Path $PSScriptRoot '..\runner_utility_scripts\Logger.ps1')
        $config = [pscustomobject]@{
            InstallCA = $false
            CertificateAuthority = @{ CommonName = 'TestCA'; ValidityYears = 1 }
        }
        Mock Write-CustomLog {}
        Mock Install-AdcsCertificationAuthority {}

        . $scriptPath
        Install-CA -Config $config

        Assert-MockNotCalled Install-AdcsCertificationAuthority
    }
}
