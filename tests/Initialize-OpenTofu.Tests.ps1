. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Describe 'Initialize-OpenTofu script' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'lab_utils' 'LabRunner.psd1')
        $script:ScriptPath = Get-RunnerScriptPath '0009_Initialize-OpenTofu.ps1'
    }
    AfterEach {
        Remove-Item Function:gh -ErrorAction SilentlyContinue
        Remove-Item Function:tofu -ErrorAction SilentlyContinue
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

        Should -Invoke -CommandName gh -Times 1 -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' }
        Should -Invoke -CommandName git -Times 0
        Should -Invoke -CommandName tofu -Times 1 -ParameterFilter { $args[0] -eq 'init' }

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

        Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'pull' }
        Should -Invoke -CommandName git -Times 0 -ParameterFilter { $args[0] -eq 'clone' }
        Should -Invoke -CommandName tofu -Times 1 -ParameterFilter { $args[0] -eq 'init' }

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

        Should -Invoke -CommandName tofu -Times 1 -ParameterFilter { $args[0] -eq 'init' }

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'installs OpenTofu when tofu command is missing' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $env:LOCALAPPDATA = $tempDir
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl  = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
            HyperV        = @{}
            CosignPath    = 'C:\\temp'
            OpenTofuVersion = 'latest'
        }

        $script:getCalls = 0
        Mock Get-Command {
            param($Name)
            if ($Name -eq 'gh') { return @{ Name = 'gh' } }
            if ($Name -eq 'tofu') {
                $script:getCalls++
                if ($script:getCalls -eq 1) { return $null } else { return @{ Name = 'tofu' } }
            }
        }
        function global:gh {}
        function global:tofu {}
        Mock gh { $global:LASTEXITCODE = 0 }
        Mock git {}
        Mock tofu {}
        Mock Invoke-OpenTofuInstaller {}

        & $script:ScriptPath -Config $config

        Should -Invoke -CommandName Invoke-OpenTofuInstaller -Times 1
        Should -Invoke -CommandName tofu -Times 1 -ParameterFilter { $args[0] -eq 'init' }

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'throws when installation does not make tofu available' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $env:LOCALAPPDATA = $tempDir
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl  = 'https://example.com/repo.git'
            InfraRepoPath = $tempDir
            HyperV        = @{}
            CosignPath    = 'C:\\temp'
            OpenTofuVersion = 'latest'
        }

        Mock Get-Command {
            param($Name)
            if ($Name -eq 'gh') { return @{ Name = 'gh' } }
            if ($Name -eq 'tofu') { return $null }
        }
        function global:gh {}
        Mock gh { $global:LASTEXITCODE = 0 }
        Mock git {}
        Mock Invoke-OpenTofuInstaller {}

        { & $script:ScriptPath -Config $config } | Should -Throw 'Tofu still not found after installation'

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'errors when Install-OpenTofu script is missing' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $env:LOCALAPPDATA = $tempDir
        $config = [pscustomobject]@{
            InitializeOpenTofu = $true
            InfraRepoUrl      = 'https://example.com/repo.git'
            InfraRepoPath     = $tempDir
            HyperV            = @{}
            CosignPath        = 'C:\\temp'
            OpenTofuVersion   = 'latest'
        }

        $install = Get-RunnerScriptPath '0008_Install-OpenTofu.ps1'
        $backup  = "$install.bak"
        Move-Item -Path $install -Destination $backup
        try {
            Mock Get-Command {
                param($Name)
                if ($Name -eq 'gh')   { return @{ Name = 'gh' } }
                if ($Name -eq 'tofu') { return $null }
            }
            function global:gh {}
            Mock gh { $global:LASTEXITCODE = 0 }
            Mock git {}

            { & $script:ScriptPath -Config $config } |
                Should -Throw 'installer script'
        }
        finally {
            Move-Item -Path $backup -Destination $install
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}
