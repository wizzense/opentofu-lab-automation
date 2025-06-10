. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }

Describe 'Get-WindowsJobArtifacts' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-WindowsJobArtifacts.ps1'
    }

    It 'uses gh CLI when authenticated' {
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth status' }
        Mock gh { '{"workflow_runs":[{"id":1}]}' } -ParameterFilter { $args[0] -like '*runs?*' }
        Mock gh { '{"artifacts":[{"name":"pester-coverage-windows-latest","archive_download_url":"cov"},{"name":"pester-results-windows-latest","archive_download_url":"res"}]}' } -ParameterFilter { $args[0] -like '*artifacts*' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'cov' -or $args[0] -eq 'res' }
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath

        Should -Invoke -CommandName gh -ParameterFilter { $args[0] -eq 'auth status' } -Times 1
        Should -Not -Invoke -CommandName Invoke-WebRequest
    }

    It 'falls back to nightly.link when gh auth fails' {
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { throw 'unauthenticated' } -ParameterFilter { $args[0] -eq 'auth status' }
        Mock Invoke-WebRequest {}
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath

        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -match 'nightly\.link' }
    }
}
