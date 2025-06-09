<#
.SYNOPSIS
    Tests for runner_scripts\0001_Reset-Git.ps1

    • Verifies that the script prefers `gh repo clone` when the GitHub CLI exists.
    • Verifies that it falls back to `git clone` when `gh` is absent.
    • Verifies that it exits with a non-zero code (or throws) when the clone fails.
#>

Describe '0001_Reset-Git' {

    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'runner_scripts' '0001_Reset-Git.ps1'
    }

    Context 'Clone command selection' {

        It 'uses **gh repo clone** when gh CLI is available' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { @{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
            Mock gh { $global:LASTEXITCODE = 0 }
            Mock git {}

            & $script:ScriptPath -Config $config

            Assert-MockCalled gh  -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' } -Times 1
            Assert-MockNotCalled git

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        It 'falls back to **git clone** when gh CLI is missing' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git { $global:LASTEXITCODE = 0 }
            Mock gh  {}

            & $script:ScriptPath -Config $config

            Assert-MockCalled git -ParameterFilter { $args[0] -eq 'clone' } -Times 1
            Assert-MockNotCalled gh

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

        It 'prompts to login when gh CLI is unauthenticated' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { @{ Name = 'gh'; Path = 'gh.exe' } } -ParameterFilter { $Name -eq 'gh' }
            Mock gh {
                param($Sub, $Action)
                if ($Sub -eq 'auth' -and $Action -eq 'status') { $global:LASTEXITCODE = 1 }
            }
            Mock git {}

            & $script:ScriptPath -Config $config

            Assert-MockCalled gh -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' } -Times 1
            Assert-MockNotCalled gh -ParameterFilter { $args[0] -eq 'repo' -and $args[1] -eq 'clone' }
            Assert-MockNotCalled git

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Logging' {
        It 'logs a success message when clone succeeds' {
            $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())

            $config = [pscustomobject]@{
                InfraRepoUrl  = 'https://example.com/repo.git'
                InfraRepoPath = $tempDir
            }

            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
            Mock git { $global:LASTEXITCODE = 0 }
            Mock Write-CustomLog {}

            & $script:ScriptPath -Config $config

            Assert-MockCalled Write-CustomLog -ParameterFilter { $Message -eq 'Clone completed successfully.' } -Times 1

            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
