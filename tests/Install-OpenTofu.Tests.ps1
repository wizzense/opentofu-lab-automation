. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe '0008_Install-OpenTofu script' {
    It 'passes OpenTofuVersion to the installer' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $scriptsDir = Join-Path $tempRoot 'runner_scripts'
        $utilsDir = Join-Path $tempRoot 'runner_utility_scripts'
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
        Copy-Item (Join-Path $PSScriptRoot '..' 'runner_scripts' '0008_Install-OpenTofu.ps1') -Destination $scriptsDir
        Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $utilsDir -Recurse
        $stub = Join-Path $utilsDir 'OpenTofuInstaller.ps1'
@"
param([string]$installMethod,[string]$cosignPath,[string]$opentofuVersion)
$global:calledVersion = $opentofuVersion
Write-Output "stub version $opentofuVersion"
"@ | Set-Content -Path $stub
        $cosignDir = Join-Path $tempRoot 'cosign'
        New-Item -ItemType Directory -Path $cosignDir | Out-Null
        $config = [pscustomobject]@{
            InstallOpenTofu = $true
            CosignPath = $cosignDir
            OpenTofuVersion = '9.9.9'
        }
        try {
            & (Join-Path $scriptsDir '0008_Install-OpenTofu.ps1') -Config $config
            $global:calledVersion | Should -Be '9.9.9'
        } finally {
            Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
        }
    }
}
