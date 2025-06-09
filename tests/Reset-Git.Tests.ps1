Describe '0001_Reset-Git cloning logic' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0001_Reset-Git.ps1'
    }

    It 'uses gh repo clone when gh CLI is available' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $config = [pscustomobject]@{ InfraRepoUrl='https://example.com/repo.git'; InfraRepoPath=$tempDir }
        Mock Get-Command { @{Name='gh'} } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { $global:LASTEXITCODE = 0 }
        Mock git {}
        & $scriptPath -Config $config
        Assert-MockCalled gh -ParameterFilter { $Args[0] -eq 'repo' -and $Args[1] -eq 'clone' } -Times 1
        Assert-MockNotCalled git
        Remove-Item -Recurse -Force $tempDir
    }

    It 'falls back to git clone when gh CLI is missing' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $config = [pscustomobject]@{ InfraRepoUrl='https://example.com/repo.git'; InfraRepoPath=$tempDir }
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
        Mock git { $global:LASTEXITCODE = 0 }
        Mock gh {}
        & $scriptPath -Config $config
        Assert-MockCalled git -ParameterFilter { $Args[0] -eq 'clone' } -Times 1
        Assert-MockNotCalled gh
        Remove-Item -Recurse -Force $tempDir
    }
}
