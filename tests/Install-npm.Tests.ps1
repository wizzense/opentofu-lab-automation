Describe '0203_Install-npm' {
    It 'runs npm install in configured NpmPath' {
        $script = Join-Path $PSScriptRoot '..\runner_scripts\0203_Install-npm.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script -Destination $tempDir
            $npmDir = Join-Path $tempDir 'frontend'
            $null = New-Item -ItemType Directory -Path $npmDir
            '{}' | Set-Content -Path (Join-Path $npmDir 'package.json')
            $config = @{ Node_Dependencies = @{ NpmPath = $npmDir } }

            $calledPath = $null
            Mock npm { $calledPath = (Get-Location).ProviderPath }

            Push-Location $tempDir
            & "$tempDir/0203_Install-npm.ps1" -Config $config
            Pop-Location

            Assert-MockCalled npm -Times 1 -Exactly
            $calledPath | Should -Be (Get-Item $npmDir).FullName
        } finally {
            Remove-Item -Recurse -Force $tempDir
        }
    }
}
