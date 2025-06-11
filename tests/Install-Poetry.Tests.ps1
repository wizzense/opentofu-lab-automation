. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe '0204_Install-Poetry' {
    InModuleScope LabRunner {
        BeforeAll {
            $script:ScriptPath = Get-RunnerScriptPath '0204_Install-Poetry.ps1'
        }

        It 'invokes installer when enabled' {
            $cfg = [pscustomobject]@{ InstallPoetry = $true; PoetryVersion = '1.8.2' }
            Mock Invoke-LabDownload { 
                param($Uri, $Prefix, $Extension, $Action)
                $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "mock_$Prefix.py"
                New-Item -ItemType File -Path $tempFile -Force | Out-Null
                try { & $Action $tempFile } finally { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
            }
            Mock Get-Command { [PSCustomObject]@{ Path = 'python' } } -ParameterFilter { $Name -eq 'python' }
            function python { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args) }
            Mock python {}

            & $script:ScriptPath -Config $cfg

            Should -Invoke -CommandName Invoke-LabDownload -Times 1 -ParameterFilter { $Uri -eq 'https://install.python-poetry.org' }
            Should -Invoke -CommandName python -Times 1
        }

        It 'skips when InstallPoetry is false' {
            $cfg = [pscustomobject]@{ InstallPoetry = $false }
            Mock Invoke-LabWebRequest {}
            Mock Get-Command { [PSCustomObject]@{ Path = 'python' } } -ParameterFilter { $Name -eq 'python' }
            function python { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args) }
            Mock python {}

            & $script:ScriptPath -Config $cfg

            Should -Invoke -CommandName Invoke-LabWebRequest -Times 0
            Should -Invoke -CommandName python -Times 0
        }

        It 'throws when python is missing' {
            $cfg = [pscustomobject]@{ InstallPoetry = $true }
            Mock Invoke-LabWebRequest {}
            Mock Get-Command { $null } -ParameterFilter { $Name -eq 'python' }
            Remove-Item function:python -ErrorAction SilentlyContinue

            { & $script:ScriptPath -Config $cfg } | Should -Throw '*Python executable*'
        }

        AfterEach {
            Remove-Item function:python -ErrorAction SilentlyContinue
        }
    }

    AfterAll {
        Get-Module LabRunner | Remove-Module -Force -ErrorAction SilentlyContinue
    }
}
