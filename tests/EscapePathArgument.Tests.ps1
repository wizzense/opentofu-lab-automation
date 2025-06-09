Describe 'escapePathArgument' {
    BeforeAll {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:scriptPath, [ref]$null, [ref]$null)
        $funcAst = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'escapePathArgument' }, $false)
        Invoke-Expression $funcAst.Extent.Text
    }

    It 'wraps path in quotes' {
        escapePathArgument -Path 'C:\Test Path' | Should -Be '"C:\Test Path"'
    }

    It 'accepts pipeline input' {
        'C:\Temp' | escapePathArgument | Should -Be '"C:\Temp"'
    }

}
