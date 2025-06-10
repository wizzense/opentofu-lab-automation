. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$scripts = Get-ChildItem $scriptDir -Filter '*.ps1'

Describe 'Runner scripts parameter and command checks' {
    foreach ($file in $scripts) {
        Context $file.Name {
            $script:current = $file
            It 'declares a Config parameter when required' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:current.FullName, [ref]$null, [ref]$null)
                $configParam = if ($ast) {
                    $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ParameterAst] -and $n.Name.VariablePath.UserPath -eq 'Config' }, $true)
                } else { @() }
                if ($configParam.Count -eq 0) {
                    Write-Host "No Config parameter found in $($script:current.FullName)"
                }
                $configParam.Count | Should -BeGreaterThan 0
            }

            It 'contains at least one command invocation' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:current.FullName, [ref]$null, [ref]$null)
                $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
                if ($commands.Count -eq 0) {
                    Write-Host "No commands found in $($script:current.FullName)"
                }
                $commands.Count | Should -BeGreaterThan 0
            }
        }
    }
}
