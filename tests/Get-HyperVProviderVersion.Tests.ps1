. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }

Describe 'Get-HyperVProviderVersion' -Skip:($IsLinux -or $IsMacOS) {
    It 'parses version from main.tf' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0010_Prepare-HyperVProvider.ps1'
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
}
