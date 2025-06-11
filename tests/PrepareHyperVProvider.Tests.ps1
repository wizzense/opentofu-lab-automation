$script:testRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path $PSCommandPath } else { '.' }
. (Join-Path $script:testRoot 'TestDriveCleanup.ps1')
. (Join-Path $script:testRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }

# Skip tests if the Hyper-V module isn't available
if (-not (Get-Module -ListAvailable -Name 'Hyper-V')) { return }

BeforeAll {
    $script:scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
    . $script:scriptPath
    $global:origConvertCerToPem = (Get-Command Convert-CerToPem).ScriptBlock
    $global:origConvertPfxToPem = (Get-Command Convert-PfxToPem).ScriptBlock
    Mock Convert-PfxToPem {}
}
Describe 'Prepare-HyperVProvider path restoration' -Skip:($SkipNonWindows) {
    It 'restores location after execution' {
        $script:scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        $config = [pscustomobject]@{
            PrepareHyperVHost = $true
            InfraRepoPath = 'C:\\Infra'
            CertificateAuthority = @{ CommonName = 'TestCA' }
            HostName = 'hvhost'
        }

        $script:location = 'C:\\Start'
        $script:stack = @()

        Mock Get-Location { $script:location }
        Mock Push-Location { $script:stack += $script:location }
        Mock Set-Location { param($Path) $script:location = $Path }
        Mock Pop-Location {
            if ($script:stack.Count -gt 0) {
                $script:location = $script:stack[-1]
                if ($script:stack.Count -gt 1) {
                    $script:stack = $script:stack[0..($script:stack.Count-2)]
                } else {
                    $script:stack = @()
                }
            }
        }

        Mock-WriteLog
        Mock Get-WindowsOptionalFeature { @{State='Enabled'} }
        Mock Enable-WindowsOptionalFeature {}
        Mock Test-WSMan {}
        Mock Enable-PSRemoting {}
        Mock Get-WSManInstance { @{MaxMemoryPerShellMB=1024; MaxTimeoutms=1800000; TrustedHosts='*'; Negotiate=$true} }
        Mock Set-WSManInstance {}
        Mock New-Item {}
        Mock Test-Path { $false }
        Mock git {}
        Mock go {}
        Mock Copy-Item {}
        Mock Convert-CerToPem {}
        Mock Read-LoggedInput {
            $pwd = New-Object System.Security.SecureString
            foreach ($c in ''.ToCharArray()) { $pwd.AppendChar($c) }
            $pwd.MakeReadOnly()
            $pwd
        }
        Mock Resolve-Path { param([string]$Path) @{ Path = $Path } }

        & $script:scriptPath -Config $config

        $location | Should -Be 'C:\\Start'
    }
}

Describe 'Prepare-HyperVProvider certificate handling' -Skip:($SkipNonWindows) {
    It 'creates PEM files and updates providers.tf' {

        $script:scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())

        $null = New-Item -ItemType Directory -Path $tempDir
        $config = [pscustomobject]@{
            PrepareHyperVHost = $true
            InfraRepoPath = $tempDir
            CertificateAuthority = @{ CommonName = 'TestCA' }
        }

        Mock-WriteLog
        Mock Get-WindowsOptionalFeature { @{State='Enabled'} }
        Mock Enable-WindowsOptionalFeature {}
        Mock Test-WSMan {}
        Mock Enable-PSRemoting {}
        Mock Get-WSManInstance { @{MaxMemoryPerShellMB=1024; MaxTimeoutms=1800000; TrustedHosts='*'; Negotiate=$true} }
        Mock Set-WSManInstance {}
        Mock New-Item {}
        Mock Test-Path { $false }
        Mock git {}
        Mock go {}
        Mock Get-ChildItem { $null } -ParameterFilter { $Path -like 'cert:*' }
        Mock Import-PfxCertificate {}
        Mock New-SelfSignedCertificate {}

        Mock Convert-CerToPem {
            param($CerPath, $PemPath)
            & $global:origConvertCerToPem -CerPath $CerPath -PemPath $PemPath
        }
        Mock Convert-PfxToPem {
            param($PfxPath, $Password, $CertPath, $KeyPath)
            & $global:origConvertPfxToPem -PfxPath $PfxPath -Password $Password -CertPath $CertPath -KeyPath $KeyPath
        }
        # certificate operations should not touch the real store
        $rootStub = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $hostStub = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certCall = 0
        Mock New-SelfSignedCertificate { if ($certCall++ -eq 0) { $rootStub } else { $hostStub } }
        Mock Export-Certificate {}
        Mock Export-PfxCertificate {}
        Mock Import-PfxCertificate {}
        Mock Remove-Item {}
        Mock Read-LoggedInput {
            $pwd = New-Object System.Security.SecureString
            foreach ($c in 'pw'.ToCharArray()) { $pwd.AppendChar($c) }
            $pwd.MakeReadOnly()
            $pwd
        }

        # prepare certificate files for conversion using static test data
        $rootCaName = $config.CertificateAuthority.CommonName
        $hostName   = [System.Net.Dns]::GetHostName()

        $executionPath = Get-Location
        $sourceCert = Join-Path $testRoot 'data' 'TestCA.cer'
        Mock Test-Path { $true } -ParameterFilter { $_ -like "*$rootCaName.cer" }
        Copy-Item -Path $sourceCert -Destination (Join-Path $executionPath "$rootCaName.cer") -Force
        'dummy' | Set-Content -Path (Join-Path $executionPath "$rootCaName.pfx")
        'dummy' | Set-Content -Path (Join-Path $executionPath "$hostName.pfx")

        Mock Copy-Item {}

        $providerFile = Join-Path $tempDir 'providers.tf'
        @(
          'provider "hyperv" {',
          '  insecure        = true',
          '  use_ntlm        = true',
          '  tls_server_name = ""',
          '  cacert_path     = ""',
          '  cert_path       = ""',
          '  key_path        = ""',
          '}'
        ) | Set-Content -Path $providerFile
        Mock Test-Path { $true } -ParameterFilter { $_ -eq $providerFile }

        $cmdBefore = Get-Command Convert-PfxToPem
        & $script:scriptPath -Config $config
        $cmdAfter  = Get-Command Convert-PfxToPem
        $cmdAfter | Should -Be $cmdBefore
        Should -Invoke -CommandName New-SelfSignedCertificate -Times 2
        Should -Invoke -CommandName Export-Certificate -Times 2
        Should -Invoke -CommandName Import-PfxCertificate -Times 3
        Should -Invoke -CommandName Convert-CerToPem -Times 1
        Should -Invoke -CommandName Convert-PfxToPem -Times 1

        Test-Path (Join-Path $tempDir 'TestCA.pem') | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname).pem")) | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname)-key.pem")) | Should -BeTrue
        (Get-Content $providerFile -Raw) | Should -Match 'insecure\s*=\s*false'

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$rootCaName.cer") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$rootCaName.pem") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$rootCaName.pfx") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$hostName.pfx") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$hostName.pem") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $executionPath "$hostName-key.pem") -ErrorAction SilentlyContinue
   }

    It 'does not redefine Convert-PfxToPem when sourced twice' {
        $cmdFirst = Get-Command Convert-PfxToPem
        . $script:scriptPath -Config ([pscustomobject]@{ PrepareHyperVHost = $false })
        $cmdSecond = Get-Command Convert-PfxToPem
        $cmdSecond | Should -Be $cmdFirst
    }
}


Describe 'Convert certificate helpers honour -WhatIf' -Skip:($SkipNonWindows) {
    It 'skips writing files when WhatIf is used' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $cer = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.cer')
        $pem = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.pem')
        'dummy' | Set-Content -Path $cer
        Mock Set-Content {}
        Convert-CerToPem -CerPath $cer -PemPath $pem -WhatIf
        Should -Invoke -CommandName Set-Content -Times 0
        Remove-Item $cer -ErrorAction SilentlyContinue
    }

    It 'skips writing PFX outputs when WhatIf is used' -Skip:($SkipNonWindows) {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $pfx = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.pfx')
        $cert = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.pem')
        $key = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '-key.pem')
        'dummy' | Set-Content -Path $pfx
        $rsa = New-Object psobject
        $rsa | Add-Member -MemberType ScriptMethod -Name ExportPkcs8PrivateKey -Value { @() }
        $stub = New-Object psobject
        $stub | Add-Member -MemberType ScriptMethod -Name Export -Value { param($t) @() }
        $stub | Add-Member -MemberType ScriptMethod -Name GetRSAPrivateKey -Value { $rsa }
        Mock Set-Content {}
        Mock New-Object { $stub } -ParameterFilter { $TypeName -eq 'System.Security.Cryptography.X509Certificates.X509Certificate2' }
        $securePass = New-Object System.Security.SecureString
        foreach ($c in 'pw'.ToCharArray()) { $securePass.AppendChar($c) }
        $securePass.MakeReadOnly()
        Convert-PfxToPem -PfxPath $pfx -Password $securePass -CertPath $cert -KeyPath $key -WhatIf
        Should -Invoke -CommandName Set-Content -Times 0
        Remove-Item $pfx -ErrorAction SilentlyContinue
    }
}

Describe 'Convert certificate helpers validate paths' -Skip:($SkipNonWindows) {
    BeforeAll {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
    }
    It 'errors when CerPath or PemPath is missing' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath

        { Convert-CerToPem -CerPath '' -PemPath 'x' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-CerToPem -PemPath 'x' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-CerToPem -CerPath 'x' -PemPath '' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-CerToPem -CerPath 'x' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
    }

    It 'errors when PfxPath, CertPath, or KeyPath is missing' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $pwd = New-Object System.Security.SecureString
        foreach ($c in 'pw'.ToCharArray()) { $pwd.AppendChar($c) }
        $pwd.MakeReadOnly()

        { Convert-PfxToPem -PfxPath '' -Password $pwd -CertPath 'c' -KeyPath 'k' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-PfxToPem -PfxPath $null -Password $pwd -CertPath 'c' -KeyPath 'k' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]

        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath '' -KeyPath 'k' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath $null -KeyPath 'k' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -KeyPath $null } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]

        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath 'c' -KeyPath '' } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath 'c' -KeyPath $null } | Should -Throw -ErrorType [System.Management.Automation.ParameterBindingException]
    }
}
