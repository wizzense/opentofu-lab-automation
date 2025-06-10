. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'kicker-bootstrap utilities' -Skip:($IsLinux -or $IsMacOS) {
    It 'defines Write-CustomLog fallback' {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:scriptPath, [ref]$null, [ref]$null)
        $funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        ($funcs.Name -contains 'Write-CustomLog') | Should -BeTrue
    }

    It 'invokes runner with call operator and propagates exit code' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $pattern = 'Start-Process -FilePath \$pwshPath -ArgumentList .* -Wait -NoNewWindow'
        $content | Should -Match $pattern
        $content | Should -Match 'exit \$LASTEXITCODE'
    }

    It 'detects remote config URLs using -match' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '\$configOption\s+-match\s+"https://"'
        $content | Should -Not -Match '-ccontains'
    }
}
