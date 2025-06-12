. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'kicker-bootstrap configuration' {
    It 'config files specify correct RunnerScriptName path' {
        $configFiles = @(
            (Join-Path $PSScriptRoot '..' 'configs' 'config_files' 'default-config.json'),
            (Join-Path $PSScriptRoot '..' 'configs' 'config_files' 'full-config.json')
        )
        
        foreach ($configFile in $configFiles) {
            if (Test-Path $configFile) {
                $config = Get-Content $configFile -Raw | ConvertFrom-Json
                if ($config.PSObject.Properties.Name -contains 'RunnerScriptName') {
                    $config.RunnerScriptName | Should -Be 'pwsh/runner.ps1' -Because "Config file $configFile should specify correct runner path"
                    
                    # Verify the runner script actually exists at the specified path
                    $repoRoot = Split-Path $PSScriptRoot -Parent
                    $runnerPath = Join-Path $repoRoot $config.RunnerScriptName
                    $runnerPath | Should -Exist -Because "Runner script should exist at path specified in config"
                }
            }
        }
    }
}

Describe 'kicker-bootstrap utilities'  {
    It 'defines Write-CustomLog fallback' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Write-CustomLog'
    }

    It 'defines Read-LoggedInput fallback' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Read-LoggedInput'
    }

    It 'invokes runner and propagates exit code using PassThru' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $pattern = 'Start-Process -FilePath \$pwshPath -ArgumentList .* -Wait -NoNewWindow -PassThru'
        $content | Should -Match $pattern
        $content | Should -Match '\$exitCode\s*=\s*\$proc.ExitCode'
        $content | Should -Match 'exit \$exitCode'
    }

    It 'detects remote config URLs using -match' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '\$configOption\s+-match\s+"https://"'
        $content | Should -Not -Match '-ccontains'
    }

    It 'adds repo path to git safe.directory' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'gitPath"\s+config\s+--global\s+--add\s+safe.directory'
    }

    It 'defines Update-RepoPreserveConfig function' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'function\s+Update-RepoPreserveConfig'
    }

    It 'prompts when multiple config files exist' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'Multiple configuration files found'
        $content | Should -Match 'Select configuration number'
    }

    It 'stashes config changes before pulling' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match 'stash push'
    }

    It 'defines baseUrl for raw GitHub downloads' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'kicker-bootstrap.ps1'
        $content = Get-Content $scriptPath -Raw
        $content | Should -Match '\$baseUrl\s*='
        $content | Should -Match 'raw\.githubusercontent\.com'
    }
}
