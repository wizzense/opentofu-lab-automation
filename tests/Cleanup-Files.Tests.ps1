Describe 'Cleanup-Files script' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0000_Cleanup-Files.ps1'
    }

    It 'removes repo and infra directories when they exist' {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $temp

        $Global:LogFilePath = Join-Path $temp 'cleanup.log'

        $repoName = 'opentofu-lab-automation'
        $repoPath = Join-Path $temp $repoName
        $infraPath = Join-Path $temp 'infra'
        $null = New-Item -ItemType Directory -Path $repoPath
        $null = New-Item -ItemType Directory -Path $infraPath

        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = "https://github.com/wizzense/$repoName.git"
            InfraRepoPath = $infraPath
        }

        . $scriptPath -Config $config

        (Test-Path $repoPath) | Should -BeFalse
        (Test-Path $infraPath) | Should -BeFalse

        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
    }

    It 'handles missing directories gracefully' {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $temp
        $infraPath = Join-Path $temp 'infra'
        $Global:LogFilePath = Join-Path $temp 'cleanup.log'
        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = 'https://github.com/wizzense/test.git'
            InfraRepoPath = $infraPath
        }

        { . $scriptPath -Config $config } | Should -Not -Throw

        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
    }

    It 'runs without a global log file' {
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $temp
        $infraPath = Join-Path $temp 'infra'
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = 'https://github.com/wizzense/test.git'
            InfraRepoPath = $infraPath
        }

        { . $scriptPath -Config $config } | Should -Not -Throw

        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }
}

