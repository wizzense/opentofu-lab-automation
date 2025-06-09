describe '0001_Reset-Git error handling' {
    it 'exits with code 1 when git clone fails' {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0001_Reset-Git.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $config = [pscustomobject]@{
            InfraRepoUrl = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
        }
        Mock git { $global:LASTEXITCODE = 1 }
        . $scriptPath -Config $config
        $LASTEXITCODE | Should -Be 1
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
