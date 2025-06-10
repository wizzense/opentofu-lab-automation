. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks' {
    foreach ($scriptFile in $scripts) {
        Context $scriptFile.Name -ForEach @{ Path = $scriptFile.FullName } {
            param($Path)
            It 'declares a Config parameter when required' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
                $configParam = if ($ast) {
                    $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'Config' }, $true)
                } else { @() }
                $configParam.Count | Should -BeGreaterThan 0
            }

            It 'contains at least one command invocation' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
                $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
                $commands.Count | Should -BeGreaterThan 0
            }
        }
    }
}
