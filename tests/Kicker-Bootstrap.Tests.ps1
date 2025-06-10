. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'kicker-bootstrap utilities' {
    It 'defines Write-CustomLog fallback' {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:scriptPath, [ref]$null, [ref]$null)
        $funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        ($funcs.Name -contains 'Write-CustomLog') | Should -BeTrue
    }

    It 'invokes runner with call operator and propagates exit code' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '& \\.\\\$runnerScriptName'
        $content | Should -Match 'exit \$LASTEXITCODE'
    }
}
