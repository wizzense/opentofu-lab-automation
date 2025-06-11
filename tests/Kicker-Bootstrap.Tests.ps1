. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'kicker-bootstrap utilities' -Skip:($SkipNonWindows) {
    It 'defines Write-CustomLog fallback' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Write-CustomLog'
    }

    It 'defines Read-LoggedInput fallback' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Read-LoggedInput'
    }

    It 'invokes runner and propagates exit code using PassThru' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $pattern = 'Start-Process -FilePath \$pwshPath -ArgumentList .* -Wait -NoNewWindow -PassThru'
        $content | Should -Match $pattern
        $content | Should -Match '\$exitCode\s*=\s*\$proc.ExitCode'
        $content | Should -Match 'exit \$exitCode'
    }

    It 'detects remote config URLs using -match' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '\$configOption\s+-match\s+"https://"'
        $content | Should -Not -Match '-ccontains'
    }

    It 'adds repo path to git safe.directory' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'gitPath"\s+config\s+--global\s+--add\s+safe.directory'
    }

    It 'defines Update-RepoPreserveConfig function' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Update-RepoPreserveConfig'
    }

    It 'prompts when multiple config files exist' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'Multiple configuration files found'
        $content | Should -Match 'Select configuration number'
    }

    It 'stashes config changes before pulling' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'stash push'
    }
}
