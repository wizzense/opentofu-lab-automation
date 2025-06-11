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
    Copy-Item (Join-Path $repoRoot 'runner.ps1') -Destination $root

    $rsDir = Join-Path $root 'runner_scripts'
    New-Item -ItemType Directory -Path $rsDir | Out-Null

    $utils = Join-Path $root 'lab_utils' 'LabRunner'
    New-Item -ItemType Directory -Path $utils -Force | Out-Null
    'function Write-CustomLog { param([string]$Message,[string]$Level) }' |
        Set-Content -Path (Join-Path $utils 'Logger.ps1')

    $labs = Join-Path $root 'lab_utils'
    New-Item -ItemType Directory -Path $labs | Out-Null
    'function Get-LabConfig { param([string]$Path) Get-Content -Raw $Path | ConvertFrom-Json }' |
        Set-Content -Path (Join-Path $labs 'Get-LabConfig.ps1')
    'function Format-Config { param($Config) $Config | ConvertTo-Json -Depth 5 }' |
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

    $cfgDir = Join-Path $root 'config_files'
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
