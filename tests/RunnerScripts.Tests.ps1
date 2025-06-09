$scriptDir = Join-Path $PSScriptRoot '..' 'runner_scripts'
$cases = Get-ChildItem $scriptDir -Filter '*.ps1' | ForEach-Object {
    @{ Name = $_.Name; Path = $_.FullName }
}

Describe 'Runner scripts parameter and command checks' {
    It 'declares a Config parameter when required' -TestCases $cases {
        param($Name, $Path)
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        $configParam = $null
        if ($ast -and $ast.ParamBlock) {
            $configParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Config' }
        }
        if ($Name -eq '0100_Enable-WinRM.ps1') {
            $configParam | Should -BeNullOrEmpty
        } else {
            $configParam | Should -Not -BeNullOrEmpty
        }
    }

    It 'contains at least one command invocation' -TestCases $cases {
        param($Name, $Path)
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        $commands = if ($ast) { $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) } else { @() }
        $commands.Count | Should -BeGreaterThan 0
    }

    It 'uses Invoke-LabScript wrapper' -TestCases $cases {
        param($Name, $Path)
        $content = Get-Content -Path $Path -Raw
        $content | Should -Match 'Invoke-LabScript'
    }
}
