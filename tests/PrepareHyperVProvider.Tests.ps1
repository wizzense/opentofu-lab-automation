Describe 'Prepare-HyperVProvider path restoration' {
    It 'restores location after execution' {
        $scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
        $config = [pscustomobject]@{
            PrepareHyperVHost = $true
            InfraRepoPath = 'C:\\Infra'
            CertificateAuthority = @{ CommonName = 'TestCA' }
            HostName = 'hvhost'
        }

        $location = 'C:\\Start'
        $stack = @()

        Mock Get-Location { $location }
        Mock Push-Location { $stack += $location }
        Mock Set-Location { param($Path) $location = $Path }
        Mock Pop-Location { $location = $stack[-1]; $stack = $stack[0..($stack.Count-2)] }

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

        & $scriptPath -Config $config

        $location | Should -Be 'C:\\Start'
    }
}

Describe 'Prepare-HyperVProvider certificate handling' {
    It 'creates PEM files and updates providers.tf' {
        $scriptPath = Join-Path $PSScriptRoot '..\runner_scripts\0010_Prepare-HyperVProvider.ps1'
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

        & $scriptPath -Config $config

        Test-Path (Join-Path $tempDir 'TestCA.pem') | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname).pem")) | Should -BeTrue
        Test-Path (Join-Path $tempDir ("$(hostname)-key.pem")) | Should -BeTrue
        (Get-Content $providerFile -Raw) | Should -Match 'insecure\s*=\s*false'
    }
}
