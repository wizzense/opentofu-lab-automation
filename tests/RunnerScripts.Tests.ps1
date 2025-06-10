
$helperPath = Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1'
if (-not (Test-Path $helperPath)) {
    throw "Required helper script is missing: $helperPath"
}

. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')

if ($IsLinux -or $IsMacOS) { return }

$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks' -Skip:($IsLinux -or $IsMacOS) {

    BeforeAll {
        . (Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1')
    }


    $testCases = $scripts | ForEach-Object {
        @{ Name = $_.Name; File = $_ }
    }

    It 'parses without errors' -TestCases $testCases {
        param($File)
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($File.FullName, [ref]$null, [ref]$errors) | Out-Null
        ($errors ? $errors.Count : 0) | Should -Be 0
    }

    It 'declares a Config parameter when required' -TestCases $testCases {
        param($File)
        $ast = Get-ScriptAst $File.FullName
        $configParam = if ($ast) {
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'Config' }, $true)
        } else { @() }
        if ($configParam.Count -eq 0) {
            Write-Host "No Config parameter found in $($File.FullName)"
        }
        $configParam.Count | Should -BeGreaterThan 0
    }

    It 'contains at least one command invocation' -TestCases $testCases {
        param($File)
        $ast = Get-ScriptAst $File.FullName
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        if ($commands.Count -eq 0) {
            Write-Host "No commands found in $($File.FullName)"
        }
        $commands.Count | Should -BeGreaterThan 0
    }
}
