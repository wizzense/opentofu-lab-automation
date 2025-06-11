. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe '0204_Install-Poetry' {
    BeforeAll {
        $script:ScriptPath = Get-RunnerScriptPath '0204_Install-Poetry.ps1'
        . $script:ScriptPath
    }

    It 'invokes installer when enabled' {
        $cfg = [pscustomobject]@{ InstallPoetry = $true; PoetryVersion = '1.8.2' }
        Mock Invoke-LabWebRequest {}
        function python { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args) }
        Mock python {}
        Mock-WriteLog

        Install-Poetry -Config $cfg

        Should -Invoke -CommandName Invoke-LabWebRequest -Times 1 -ParameterFilter { $Uri -eq 'https://install.python-poetry.org' }
        Should -Invoke -CommandName python -Times 1
    }

    It 'skips when InstallPoetry is false' {
        $cfg = [pscustomobject]@{ InstallPoetry = $false }
        Mock Invoke-LabWebRequest {}
        function python { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args) }
        Mock python {}
        Mock-WriteLog

        Install-Poetry -Config $cfg

        Should -Invoke -CommandName Invoke-LabWebRequest -Times 0
        Should -Invoke -CommandName python -Times 0
    }

    AfterEach {
        Remove-Item function:python -ErrorAction SilentlyContinue
    }
}
