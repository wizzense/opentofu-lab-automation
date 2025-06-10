
# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

$SkipNonWindows = $IsLinux -or $IsMacOS

function global:Get-RunnerScriptPath {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    (Resolve-Path -ErrorAction Stop (Join-Path $PSScriptRoot '..' '..' 'runner_scripts' $Name)).Path
}

function Mock-WriteLog {
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        function global:Write-CustomLog { param([string]$Message,[string]$Level) }
    }
    Mock Write-CustomLog {}
}

