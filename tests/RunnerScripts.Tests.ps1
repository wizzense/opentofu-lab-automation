
$helperPath = Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1'
if (-not (Test-Path $helperPath)) {
    throw "Required helper script is missing: $helperPath"
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')


$scriptDir = Split-Path (Get-RunnerScriptPath '0001_Reset-Git.ps1')
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks'  {

    BeforeAll {
        . (Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1')
    }


    $mandatory = @('Write-CustomLog')
    $testCases = $scripts | ForEach-Object {
        @{ Name = $_.Name; File = $_; Commands = $mandatory }
    }

    It 'parses without errors' -TestCases $testCases {
        param($File)
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$errors) | Out-Null
        ($errors ? $errors.Count : 0) | Should -Be 0
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

    It 'imports LabRunner module' -TestCases $testCases {
        param($File)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) {
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        } else { @() }

        $found = $commands | Where-Object {
            $_.GetCommandName() -eq 'Import-Module' -and
            $_.CommandElements.Count -ge 2 -and
            (
                $_.CommandElements[1] -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $_.CommandElements[1] -is [System.Management.Automation.Language.ExpandableStringExpressionAst]
            ) -and
            ([System.IO.Path]::GetFileName($_.CommandElements[1].Value) -eq 'LabRunner.psm1')
        }

        if (-not $found) {
            Write-Host "LabRunner module not imported in $($File.FullName)"
        }

        ($found | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It 'resolves PSScriptRoot when run with pwsh -File' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        try {
            $dummy = Join-Path $tempDir 'dummy.ps1'
            @"
Param([pscustomobject]`$Config)
Import-Module "$PSScriptRoot/../runner_utility_scripts/LabRunner.psm1"
Invoke-LabStep -Config `$Config -Body { Write-Output `$PSScriptRoot }
"@ | Set-Content -Path $dummy

            $pwsh = (Get-Command pwsh).Source
            $result = & $pwsh -NoLogo -NoProfile -File $dummy -Config @{}
            $expected = Split-Path $dummy -Parent
            $result.Trim() | Should -Be $expected
        }
        finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}
