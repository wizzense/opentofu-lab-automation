. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }

BeforeAll {
    $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
    . $script:scriptPath
    $script:origConvertCerToPem = (Get-Command Convert-CerToPem).ScriptBlock
    $script:origConvertPfxToPem = (Get-Command Convert-PfxToPem).ScriptBlock
    Mock Convert-PfxToPem {}
}
Describe 'Prepare-HyperVProvider path restoration' -Skip:($IsLinux -or $IsMacOS) {
    It 'restores location after execution' {
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
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
        Mock Pop-Location { $script:location = $script:stack[-1]; $script:stack = $script:stack[0..($script:stack.Count-2)] }

        Mock Write-CustomLog {}
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
        Mock Read-Host {
            $pwd = New-Object System.Security.SecureString
            foreach ($c in ''.ToCharArray()) { $pwd.AppendChar($c) }
            $pwd.MakeReadOnly()
            $pwd
        }
        Mock Resolve-Path { param([string]$Path) @{ Path = $Path } }

        . $script:scriptPath -Config $config

        $location | Should -Be 'C:\\Start'
    }
}

Describe 'Prepare-HyperVProvider certificate handling' -Skip:($IsLinux -or $IsMacOS) {
    It 'creates PEM files and updates providers.tf' {

        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())

        $null = New-Item -ItemType Directory -Path $tempDir
        $config = [pscustomobject]@{
            PrepareHyperVHost = $true
            InfraRepoPath = $tempDir
            CertificateAuthority = @{ CommonName = 'TestCA' }
        }

        Mock Write-CustomLog {}
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
            & $script:origConvertCerToPem -CerPath $CerPath -PemPath $PemPath
        }
        Mock Convert-PfxToPem {
            param($PfxPath, $Password, $CertPath, $KeyPath)
            & $script:origConvertPfxToPem -PfxPath $PfxPath -Password $Password -CertPath $CertPath -KeyPath $KeyPath
        }
        Mock Copy-Item {}
        # certificate operations should not touch the real store
        $rootStub = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $hostStub = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $certCall = 0
        Mock New-SelfSignedCertificate { if ($certCall++ -eq 0) { $rootStub } else { $hostStub } }
        Mock Export-Certificate {}
        Mock Import-PfxCertificate {}
        Mock Remove-Item {}
        Mock Read-Host {
            $pwd = New-Object System.Security.SecureString
            foreach ($c in 'pw'.ToCharArray()) { $pwd.AppendChar($c) }
            $pwd.MakeReadOnly()
            $pwd
        }

        # prepare certificate files for conversion using static test data
        $rootCaName = $config.CertificateAuthority.CommonName
        $hostName   = [System.Net.Dns]::GetHostName()
        $sourceCert = Join-Path $PSScriptRoot 'data' 'TestCA.cer'
        Copy-Item -Path $sourceCert -Destination (Join-Path $PWD "$rootCaName.cer") -Force
        'dummy' | Set-Content -Path (Join-Path $PWD "$rootCaName.pfx")
        'dummy' | Set-Content -Path (Join-Path $PWD "$hostName.pfx")

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

        $cmdBefore = Get-Command Convert-PfxToPem
        . $script:scriptPath -Config $config
        $cmdAfter  = Get-Command Convert-PfxToPem
        $cmdAfter | Should -Be $cmdBefore
        Assert-MockCalled New-SelfSignedCertificate -Times 2
        Assert-MockCalled Export-Certificate -Times 2
        Assert-MockCalled Import-PfxCertificate -Times 3
        Assert-MockCalled Convert-CerToPem -Times 1
        Assert-MockCalled Convert-PfxToPem -Times 1

        Test-Path (Join-Path $tempDir 'TestCA.pem') | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname).pem")) | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname)-key.pem")) | Should -BeTrue
        (Get-Content $providerFile -Raw) | Should -Match 'insecure\s*=\s*false'

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$rootCaName.cer") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$rootCaName.pem") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$rootCaName.pfx") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$hostName.pfx") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$hostName.pem") -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $PWD "$hostName-key.pem") -ErrorAction SilentlyContinue
    }

    It 'does not redefine Convert-PfxToPem when sourced twice' {
        $cmdFirst = Get-Command Convert-PfxToPem
        . $script:scriptPath -Config ([pscustomobject]@{ PrepareHyperVHost = $false })
        $cmdSecond = Get-Command Convert-PfxToPem
        $cmdSecond | Should -Be $cmdFirst
    }
}


Describe 'Convert certificate helpers honour -WhatIf' -Skip:($IsLinux -or $IsMacOS) {
    It 'skips writing files when WhatIf is used' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $cer = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.cer')
        $pem = Join-Path $TestDrive (([guid]::NewGuid()).ToString() + '.pem')
        'dummy' | Set-Content -Path $cer
        Mock Set-Content {}
        Convert-CerToPem -CerPath $cer -PemPath $pem -WhatIf
        Should -Invoke -CommandName Set-Content -Times 0
        Remove-Item $cer -ErrorAction SilentlyContinue
    }

    It 'skips writing PFX outputs when WhatIf is used' -Skip:($IsLinux -or $IsMacOS) {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
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

Describe 'Convert certificate helpers validate paths' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        Remove-Mock -CommandName Convert-PfxToPem -ErrorAction SilentlyContinue
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
    }
    It 'errors when CerPath or PemPath is missing' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        { Convert-CerToPem -CerPath '' -PemPath 'x' } | Should -Throw 'Convert-CerToPem: CerPath is required'
        { Convert-CerToPem -CerPath 'x' -PemPath '' } | Should -Throw 'Convert-CerToPem: PemPath is required'
    }

    It 'errors when PfxPath, CertPath, or KeyPath is missing' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $pwd = New-Object System.Security.SecureString
        foreach ($c in 'pw'.ToCharArray()) { $pwd.AppendChar($c) }
        $pwd.MakeReadOnly()
        { Convert-PfxToPem -PfxPath '' -Password $pwd -CertPath 'c' -KeyPath 'k' } | Should -Throw 'Convert-PfxToPem: PfxPath is required'
        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath '' -KeyPath 'k' } | Should -Throw 'Convert-PfxToPem: CertPath is required'
        { Convert-PfxToPem -PfxPath 'p' -Password $pwd -CertPath 'c' -KeyPath '' } | Should -Throw 'Convert-PfxToPem: KeyPath is required'
    }
}
