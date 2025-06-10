Describe 'Prepare-HyperVProvider path restoration' {
    It 'restores location after execution' {
        $script:scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
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
        Mock Read-Host { '' }
        Mock Resolve-Path { param([string]$Path) @{ Path = $Path } }

        & $script:scriptPath -Config $config

        $location | Should -Be 'C:\\Start'
    }
}

Describe 'Prepare-HyperVProvider certificate handling' {
    It 'creates PEM files and updates providers.tf' {
        $script:scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
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
        Mock Copy-Item {}
        Mock Read-Host { 'pw' }

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

        & $script:scriptPath -Config $config

        Test-Path (Join-Path $tempDir 'TestCA.pem') | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname).pem")) | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname)-key.pem")) | Should -BeTrue
        (Get-Content $providerFile -Raw) | Should -Match 'insecure\s*=\s*false'
    }
}

Describe 'Convert certificate helpers honour -WhatIf' {
    It 'skips writing files when WhatIf is used' {
        $scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
        . $scriptPath -Config @{ PrepareHyperVHost = $false }
        $cer = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '.cer'
        $pem = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '.pem'
        'dummy' | Set-Content -Path $cer
        Mock Set-Content {}
        Convert-CerToPem -CerPath $cer -PemPath $pem -WhatIf
        Assert-MockNotCalled Set-Content
        Remove-Item $cer -ErrorAction SilentlyContinue
    }

    It 'skips writing PFX outputs when WhatIf is used' {
        $scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
        . $scriptPath -Config @{ PrepareHyperVHost = $false }
        $pfx = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '.pfx'
        $cert = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '.pem'
        $key = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '-key.pem'
        'dummy' | Set-Content -Path $pfx
        $rsa = New-Object psobject
        $rsa | Add-Member -MemberType ScriptMethod -Name ExportPkcs8PrivateKey -Value { @() }
        $stub = New-Object psobject
        $stub | Add-Member -MemberType ScriptMethod -Name Export -Value { param($t) @() }
        $stub | Add-Member -MemberType ScriptMethod -Name GetRSAPrivateKey -Value { $rsa }
        Mock Set-Content {}
        Mock New-Object { $stub }
        $securePass = (New-Object System.Net.NetworkCredential('', 'pw')).SecurePassword
        Convert-PfxToPem -PfxPath $pfx -Password $securePass -CertPath $cert -KeyPath $key -WhatIf

        Assert-MockNotCalled Set-Content
        Remove-Item $pfx -ErrorAction SilentlyContinue
    }
}
