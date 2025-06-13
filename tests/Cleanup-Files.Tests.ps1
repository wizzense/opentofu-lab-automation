. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Cleanup-Files script' {
    BeforeAll {
        $helperPath = Join-Path $PSScriptRoot 'helpers' 'Get-ScriptAst.ps1'
        if (-not (Test-Path $helperPath)) {
            throw "Required helper script is missing: $helperPath"
        }
        . $helperPath
        $script:scriptPath = Get-RunnerScriptPath '0000_Cleanup-Files.ps1'
        $script:ast = Get-ScriptAst $script:scriptPath
    }

    BeforeEach {
        $script:temp = Join-Path $TestDrive ([System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:temp | Out-Null
    }

    AfterEach {
        Remove-Item -Recurse -Force $script:temp -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
    }
        It 'uses ErrorAction Stop for Remove-Item calls' {
        $removes = $script:ast.FindAll({ param($n) 






$n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Remove-Item' }, $true)
        $removes.Count | Should -BeGreaterThan 0
        foreach ($cmd in $removes) {
            $ea = $cmd.CommandElements | Where-Object {
                $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'ErrorAction'
            }
            ($ea | Measure-Object).Count | Should -BeGreaterThan 0
            
            # Check if the parameter has an argument
            $lastEa = $ea[-1]
            if ($lastEa.Argument) {
                $lastEa.Argument.Value | Should -Be 'Stop'
            } else {
                # Check the next element after the parameter for the value
                $paramIndex = [Array]::IndexOf($cmd.CommandElements, $lastEa)
                if ($paramIndex -lt ($cmd.CommandElements.Count - 1)) {
                    $nextElement = $cmd.CommandElements[$paramIndex + 1]
                    if ($nextElement -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        $nextElement.Value | Should -Be 'Stop'
                    }
                }
            }
        }
    }
        It 'removes repo and infra directories when they exist' {
        $temp = $script:temp

        $script:LogFilePath = Join-Path $temp 'cleanup.log'

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

        . $script:scriptPath -Config $config

        (Test-Path $repoPath) | Should -BeFalse
        (Test-Path $infraPath) | Should -BeFalse

        # cleanup handled in AfterEach
    }
        It 'handles missing directories gracefully' {
        $temp = $script:temp
        $infraPath = Join-Path $temp 'infra'
        $script:LogFilePath = Join-Path $temp 'cleanup.log'
        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = 'https://github.com/wizzense/test.git'
            InfraRepoPath = $infraPath
        }

        { . $script:scriptPath -Config $config } | Should -Not -Throw
    }
        It 'runs without a global log file' {
        $temp = $script:temp
        $infraPath = Join-Path $temp 'infra'
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = 'https://github.com/wizzense/test.git'
            InfraRepoPath = $infraPath
        }

        { . $script:scriptPath -Config $config } | Should -Not -Throw
    }
        It 'completes when LogFilePath is undefined' {
        $temp = $script:temp
        $repoName = 'opentofu-lab-automation'
        $repoPath = Join-Path $temp $repoName
        $infraPath = Join-Path $temp 'infra'
        $null = New-Item -ItemType Directory -Path $repoPath
        $null = New-Item -ItemType Directory -Path $infraPath
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        $config = [PSCustomObject]@{
            LocalPath     = $temp
            RepoUrl       = "https://github.com/wizzense/$repoName.git"
            InfraRepoPath = $infraPath
        }

        { . $script:scriptPath -Config $config } | Should -Not -Throw

        (Test-Path $repoPath) | Should -BeFalse
        (Test-Path $infraPath) | Should -BeFalse
    }
        It 'completes when the repo directory is removed' {
        $temp = $script:temp
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

        $orig = Get-Location
        Set-Location $repoPath

        { . $script:scriptPath -Config $config } | Should -Not -Throw

        (Test-Path $repoPath) | Should -BeFalse
        (Get-Location).Path | Should -Not -Be $repoPath

        Set-Location $orig
    }
        It 'throws when repo removal fails' {
        $temp = $script:temp
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

        Mock Remove-Item { throw [System.IO.IOException]::new('in use') } -ParameterFilter { $Path -eq $repoPath }

        # Test that the script throws an error when removal fails
        { & $script:scriptPath -Config $config } | Should -Throw '*Cleanup failed:*'
    }
}




