# Helper to create an isolated runner test environment.
# Returns the path to the temporary directory.

if (-not $script:RunnerTestEnvDirs) { $script:RunnerTestEnvDirs = @() }

function global:New-RunnerTestEnv {
    $root = Join-Path $TestDrive ([guid]::NewGuid())
    if (Test-Path $root) {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $root | Out-Null

    $repoRoot   = Join-Path $PSScriptRoot '..' '..'
    $pwshDir = Join-Path $root 'pwsh'
    New-Item -ItemType Directory -Path $pwshDir | Out-Null
    Copy-Item (Join-Path $repoRoot 'pwsh' 'runner.ps1') -Destination $pwshDir

    $rsDir = Join-Path $pwshDir 'runner_scripts'
    New-Item -ItemType Directory -Path $rsDir | Out-Null

    $utils = Join-Path $pwshDir 'modules/LabRunner'
    New-Item -ItemType Directory -Path $utils -Force | Out-Null
    'function Write-CustomLog { param([string]$Message,[string]$Level) 



}' |
        Set-Content -Path (Join-Path $utils 'Logger.ps1')

    $labs = Join-Path $pwshDir 'lab_utils'
    New-Item -ItemType Directory -Path $labs | Out-Null
    Copy-Item (Join-Path $repoRoot 'pwsh' 'lab_utils' 'Resolve-ProjectPath.ps1') -Destination $labs -Force -ErrorAction SilentlyContinue
    'function Get-LabConfig { param([string]$Path) 



Get-Content -Raw $Path | ConvertFrom-Json }' |
        Set-Content -Path (Join-Path $labs 'Get-LabConfig.ps1')
    'function Format-Config { param($Config) 



$Config | ConvertTo-Json -Depth 5 }' |
        Set-Content -Path (Join-Path $labs 'Format-Config.ps1')
    'function Get-Platform {
        if ($IsWindows) { return "Windows" }
        elseif ($IsLinux) { return "Linux" }
        elseif ($IsMacOS) { return "MacOS" }
        else { return "Unknown" }
    }' |
        Set-Content -Path (Join-Path $labs 'Get-Platform.ps1')
    'function Get-MenuSelection { }' |
        Set-Content -Path (Join-Path $labs 'Menu.ps1')

    # Also expose Resolve-ProjectPath from the repository root so tests invoking
    # runner.ps1 can locate it via $root/lab_utils
    $rootLabs = Join-Path $root 'lab_utils'
    New-Item -ItemType Directory -Path $rootLabs -Force | Out-Null
    Copy-Item (Join-Path $repoRoot 'pwsh' 'lab_utils' 'Resolve-ProjectPath.ps1') -Destination $rootLabs -ErrorAction SilentlyContinue

    $cfgDir = Join-Path $root 'configs' 'config_files'
    New-Item -ItemType Directory -Path $cfgDir | Out-Null
    '{}' | Set-Content -Path (Join-Path $cfgDir 'default-config.json')
    '{}' | Set-Content -Path (Join-Path $cfgDir 'recommended-config.json')

    $script:RunnerTestEnvDirs += $root
    return $root
}

function global:Remove-RunnerTestEnv {
    foreach ($envDir in $script:RunnerTestEnvDirs) {
        Remove-Item -Recurse -Force $envDir -ErrorAction SilentlyContinue
    }
    $script:RunnerTestEnvDirs = @()
}



