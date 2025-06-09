Describe '0203_Install-npm' {
    It 'runs npm install in configured NpmPath' {
        $script = Join-Path $PSScriptRoot '..\runner_scripts\0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $npmDir
        '{}' | Set-Content -Path (Join-Path $npmDir 'package.json')
        $config = @{ Node_Dependencies = @{ NpmPath = $npmDir } }

        $script:calledPath = $null
        function npm { param([string[]]$Args) $script:calledPath = (Get-Location).ProviderPath }


        & $script -Config $config

        $script:calledPath | Should -Be (Get-Item $npmDir).FullName

        Remove-Item -Recurse -Force $npmDir
    }

    It 'succeeds when NpmPath exists' {
        $script = Join-Path $PSScriptRoot '..\runner_scripts\0203_Install-npm.ps1'
        $npmDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $npmDir
        '{}' | Set-Content -Path (Join-Path $npmDir 'package.json')
        $config = @{ Node_Dependencies = @{ NpmPath = $npmDir } }

        function npm { param([string[]]$testArgs) }

        & $script -Config $config
        $success = $?

        $success | Should -BeTrue

        Remove-Item -Recurse -Force $npmDir
    }
}
