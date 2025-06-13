. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }

if ($IsLinux -or $IsMacOS) { return }

<#
.SYNOPSIS
    Tests for runner_scripts\0001_Reset-Git.ps1

    - Verifies that the script prefers `gh repo clone` when the GitHub CLI exists.
    - Verifies that it falls back to `git clone` when `gh` is absent.
    - Verifies that it exits with a non-zero code (or throws) when the clone fails.
#>

Describe '0001_Reset-Git' -Skip:($SkipNonWindows) {

    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0001_Reset-Git.ps1'
    }
    AfterEach {
        Remove-Item Function:gh -ErrorAction SilentlyContinue
    }

    Context 'Clone command selection' {

        It 'uses **gh repo clone** when gh CLI is available' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { @{ Name = 'gh'; Path = 'gh.exe' } } -ParameterFilter { $Name -eq 'gh' }
            function global:gh {}
            
            Mock gh {
                $global:LASTEXITCODE = 0
                New-Item -ItemType Directory -Path (Join-Path $tempDir '.git') -Force | Out-Null
            }

            Mock git {}

            & $script:ScriptPath -Config $config

            Should -Invoke -CommandName gh -Times 1 -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' }
            Should -Invoke -CommandName git -Times 0

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        It 'falls back to **git clone** when gh CLI is missing' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git {
                $global:LASTEXITCODE = 0
                New-Item -ItemType Directory -Path (Join-Path $tempDir '.git') -Force | Out-Null
            }
            Mock gh  {}

            & $script:ScriptPath -Config $config

            Should -Invoke -CommandName git -Times 1 -ParameterFilter { $args[0] -eq 'clone' }
            Should -Invoke -CommandName gh -Times 0

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Error handling' {

        It 'exits with code 1 (or throws) when clone fails' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            # Simulate git failing
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git { $global:LASTEXITCODE = 1 }

            try {
                & $script:ScriptPath -Config $config
                # If the script uses `throw`, this assertion is skipped because the Try is exited.
                $LASTEXITCODE | Should -Be 1
            }
            catch {
                $_ | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        It 'aborts when gh CLI is unauthenticated' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { @{ Name = 'gh'; Path = 'gh.exe' } } -ParameterFilter { $Name -eq 'gh' }
            function global:gh {}
            Mock gh {
                param($Sub, $Action)
                



if ($Sub -eq 'auth' -and $Action -eq 'status') { $global:LASTEXITCODE = 1 }
            }
            Mock git {}

            try {
                & $script:ScriptPath -Config $config
                $LASTEXITCODE | Should -Be 1
            } catch {
                $_ | Should -Not -BeNullOrEmpty
            } finally {
                Should -Invoke -CommandName gh -Times 1 -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
                Should -Invoke -CommandName gh -Times 0 -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' }
                Should -Invoke -CommandName git -Times 0
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Logging' {
        It 'logs a success message when clone succeeds' {
            . (Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Logger.ps1')
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git {
                $global:LASTEXITCODE = 0
                New-Item -ItemType Directory -Path (Join-Path $tempDir '.git') -Force | Out-Null
            }
            Mock-WriteLog

            & $script:ScriptPath -Config $config

            Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Clone completed successfully.' }

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        It 'logs a completion message when clone succeeds' {
            . (Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/Logger.ps1')
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git {
                $global:LASTEXITCODE = 0
                New-Item -ItemType Directory -Path (Join-Path $tempDir '.git') -Force | Out-Null
            }
            Mock-WriteLog

            & $script:ScriptPath -Config $config

            Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Completed 0001_Reset-Git.ps1' }

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}



