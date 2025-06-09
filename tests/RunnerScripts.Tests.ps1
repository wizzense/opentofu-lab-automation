$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks' {
    foreach ($script in $scripts) {
        Context $script.Name {
            It 'declares a Config parameter when required' {
                $ast         = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
                $configParam = $null
                if ($ast -and $ast.ParamBlock) {
                    $configParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Config' }
                }

                $configParam | Should -Not -BeNullOrEmpty
            }

            It 'contains at least one command invocation' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
                $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
                $commands.Count | Should -BeGreaterThan 0
            }
        }
    }
}
