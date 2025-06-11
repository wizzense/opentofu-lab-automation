
# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

$SkipNonWindows = $IsLinux -or $IsMacOS
. (Join-Path $PSScriptRoot '..' '..' 'lab_utils' 'Resolve-ProjectPath.ps1')

function global:Get-RunnerScriptPath {
    param(
        [Parameter(Mandatory=$true)][string]$Name
    )
    Resolve-ProjectPath -Name $Name -Root (Join-Path $PSScriptRoot '..')
}

function global:Mock-WriteLog {
    if (-not (Get-Command Write-CustomLog -ErrorAction SilentlyContinue)) {
        function global:Write-CustomLog { param([string]$Message,[string]$Level) }
    }
    Mock Write-CustomLog {}
}

