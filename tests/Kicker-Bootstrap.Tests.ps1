Describe 'kicker-bootstrap utilities' {
    It 'defines Write-CustomLog fallback' {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:scriptPath, [ref]$null, [ref]$null)
        $funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        ($funcs.Name -contains 'Write-CustomLog') | Should -BeTrue
    }
}
