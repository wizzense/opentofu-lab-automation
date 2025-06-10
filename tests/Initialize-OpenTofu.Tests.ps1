. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'Initialize-OpenTofu script' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0009_Initialize-OpenTofu.ps1'
    }

    It 'clones repo when InfraRepoUrl is provided' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl  = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
            HyperV        = @{}
        }

        Mock Get-Command {
            param($Name)
            if ($Name -eq 'gh') { return @{ Name = 'gh' } }
            if ($Name -eq 'tofu') { return @{ Name = 'tofu' } }
        }
        function global:gh {}
        function global:tofu {}
        Mock gh { $global:LASTEXITCODE = 0 }
        Mock git {}
        Mock tofu {}

        & $script:ScriptPath -Config $config

        Assert-MockCalled gh  -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' } -Times 1
        Assert-MockCalled git -Times 0
        Assert-MockCalled tofu -ParameterFilter { $args[0] -eq 'init' } -Times 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'pulls updates when repo already exists' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path (Join-Path $tempDir '.git') -Force
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl  = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
            HyperV        = @{}
        }

        Mock Get-Command {
            param($Name)
            if ($Name -eq 'gh') { return @{ Name = 'gh' } }
            if ($Name -eq 'tofu') { return @{ Name = 'tofu' } }
        }
        function global:gh {}
        function global:tofu {}
        Mock git {}
        Mock gh {}
        Mock tofu {}

        & $script:ScriptPath -Config $config

        Assert-MockCalled git -ParameterFilter { $args[0] -eq 'pull' } -Times 1
        Assert-MockCalled git -ParameterFilter { $args[0] -eq 'clone' } -Times 0
        Assert-MockCalled tofu -ParameterFilter { $args[0] -eq 'init' } -Times 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'runs tofu init in InfraRepoPath' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl  = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
            HyperV        = @{}
        }

        $script:pushed = $null
        Mock Get-Command {
            param($Name)
            if ($Name -eq 'gh') { return @{ Name = 'gh' } }
            if ($Name -eq 'tofu') { return @{ Name = 'tofu' } }
        }
        function global:gh {}
        function global:tofu {}
        Mock gh { $global:LASTEXITCODE = 0 }
        Mock git {}
        Mock tofu {}
        Mock Push-Location {}
        Mock Pop-Location {}

        & $script:ScriptPath -Config $config

        Assert-MockCalled tofu -ParameterFilter { $args[0] -eq 'init' } -Times 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
