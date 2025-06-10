
# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

$SkipNonWindows = $IsLinux -or $IsMacOS

function global:Get-RunnerScriptPath {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    $root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    (Resolve-Path -ErrorAction Stop (Join-Path $root '..' '..' 'runner_scripts' $Name)).Path
}

function global:Mock-WriteLog {
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        function global:Write-CustomLog { param([string]$Message,[string]$Level) }
    }
    Mock Write-CustomLog {}
}

