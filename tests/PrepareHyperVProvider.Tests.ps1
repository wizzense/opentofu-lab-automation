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

        Mock Write-Log {}
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
