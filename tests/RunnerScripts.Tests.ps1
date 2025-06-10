
$helperPath = Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1'
if (-not (Test-Path $helperPath)) {
    throw "Required helper script is missing: $helperPath"
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

if ($SkipNonWindows) { return }

$scriptDir = Split-Path (Get-RunnerScriptPath '0001_Reset-Git.ps1')
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks' -Skip:($SkipNonWindows) {

    BeforeAll {
        . (Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1')
    }


    $mandatory = @('Write-CustomLog')
    $testCases = $scripts | ForEach-Object {
        @{ Name = $_.Name; File = $_; Commands = $mandatory }
    }

    It 'declares a Config parameter when required' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $configParam = if ($ast) {
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'Config' }, $true)
        } else { @() }
        if ($configParam.Count -eq 0) {
            Write-Host "No Config parameter found in $($File.FullName)"
        }
        $configParam.Count | Should -BeGreaterThan 0
    }

    It 'contains mandatory command invocations' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        foreach ($cmd in $Commands) {
            $found = $commands | Where-Object { $_.GetCommandName() -eq $cmd }
            if (-not $found) {
                Write-Host "Command '$cmd' not found in $($File.FullName)"
            }
            ($found | Measure-Object).Count | Should -BeGreaterThan 0
        }
    }

    It 'contains Invoke-LabStep call' -TestCases $testCases {
        param($File, $Commands)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        $found = $commands | Where-Object { $_.GetCommandName() -eq 'Invoke-LabStep' }
        if (-not $found) {
            Write-Host "Invoke-LabStep not found in $($File.FullName)"
        }
        ($found | Measure-Object).Count | Should -BeGreaterThan 0
    }
}
