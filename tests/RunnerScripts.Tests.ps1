Describe 'Runner scripts parameter and command checks' {
    BeforeAll {
        $scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
        $scripts = Get-ChildItem $scriptDir -Filter '*.ps1'
    }

    foreach ($script in $scripts) {
        Context $script.Name {
            It 'declares a Config parameter' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
                $configParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Config' }
                $configParam | Should -Not -BeNullOrEmpty
            }

            It 'contains at least one command invocation' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
                $commands = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
                $commands.Count | Should -BeGreaterThan 0
            }
        }
    }
}
