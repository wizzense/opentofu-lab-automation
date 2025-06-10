. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'


Describe 'Runner scripts parameter and command checks' -Skip:($IsLinux -or $IsMacOS) {

function Get-ScriptAst {
    param([string]$Path)
    $text = Get-Content -Raw -Encoding UTF8 $Path
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$null, [ref]$null)
}

    $testCases = $scripts | ForEach-Object { @{ file = $_ } }

    It 'declares a Config parameter when required' -TestCases $testCases {
        param($file)
        $ast = Get-ScriptAst $file.FullName
        $configParam = if ($ast) {
            $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'Config' }, $true)
        } else { @() }
        if ($configParam.Count -eq 0) {
            Write-Host "No Config parameter found in $($file.FullName)"
        }
        $configParam.Count | Should -BeGreaterThan 0
    }

    It 'contains at least one command invocation' -TestCases $testCases {
        param($file)
        $ast = Get-ScriptAst $file.FullName
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        if ($commands.Count -eq 0) {
            Write-Host "No commands found in $($file.FullName)"
        }
        $commands.Count | Should -BeGreaterThan 0
    }
}
