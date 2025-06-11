. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Get-HyperVProviderVersion'  {
    It 'parses version from main.tf' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $tf = [System.IO.Path]::ChangeExtension(
            [System.IO.Path]::Combine(
                [System.IO.Path]::GetTempPath(),
                ([guid]::NewGuid()).ToString()),
            '.tf')
        @'
terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "9.9.9"
    }
  }
}
'@ | Set-Content -Path $tf
        try {
            Get-HyperVProviderVersion -MainTfPath $tf | Should -Be '9.9.9'
        } finally {
            Remove-Item $tf -ErrorAction SilentlyContinue
        }
    }

    It 'falls back to repository paths when missing' {
        $scriptPath = Get-RunnerScriptPath '0010_Prepare-HyperVProvider.ps1'
        . $scriptPath
        $tf = Join-Path $env:TEMP ([guid]::NewGuid()).ToString() + '.tf'
        Get-HyperVProviderVersion -MainTfPath $tf | Should -Be '1.2.1'
    }
}
