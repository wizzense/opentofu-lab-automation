. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
if ($SkipNonWindows) { return }
Import-Module (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'LabRunner.psd1') -Force

InModuleScope LabSetup {
Describe 'Get-WindowsJobArtifacts' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-WindowsJobArtifacts.ps1'
    }

    It 'uses gh CLI when authenticated' {
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{"workflow_runs":[{"id":1}]}' } -ParameterFilter { $args[0] -like '*runs?*' }
        Mock gh { '{"artifacts":[{"name":"pester-coverage-windows-latest","archive_download_url":"cov"},{"name":"pester-results-windows-latest","archive_download_url":"res"}]}' } -ParameterFilter { $args[0] -like '*artifacts*' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'cov' -or $args[0] -eq 'res' }
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath

        Should -Invoke -CommandName gh -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' } -Times 1
        Should -Not -Invoke -CommandName Invoke-WebRequest
    }

    It 'falls back to nightly.link when gh auth fails' {
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { throw 'unauthenticated' } -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock Invoke-WebRequest -ModuleName LabSetup {}
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath

        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -match 'nightly\.link' }
    }

    It 'uses provided run ID with gh' {
        $id = 123
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{"artifacts":[]}' } -ParameterFilter { $args[0] -like "*runs/$id/artifacts" }
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath -RunId $id

        Should -Invoke -CommandName gh -ParameterFilter { $args[0] -like "*runs/$id/artifacts" } -Times 1
        Should -Not -Invoke -CommandName Invoke-WebRequest
    }

    It 'uses provided run ID with nightly.link when gh auth fails' {
        $id = 456
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { throw 'unauthenticated' } -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock Invoke-WebRequest -ModuleName LabSetup {}
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }

        & $scriptPath -RunId $id

        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -match "$id" } -Times 2
    }

    It 'emits a clear message when artifacts are missing' {
        $id = 789
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{"artifacts":[]}' } -ParameterFilter { $args[0] -like "*runs/$id/artifacts" }
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }
        $messages = @()
        function global:Write-Host { param($Object, $Color); $script:messages += $Object }

        & $scriptPath -RunId $id 2>$null

        $LASTEXITCODE | Should -Be 1
        ($messages | Select-Object -Last 1) | Should -Match 'No artifacts'
    }

    It 'returns nonzero exit code when download fails' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
        Mock Invoke-WebRequest -ModuleName LabSetup { throw '404' }
        $messages = @()
        function global:Write-Host { param($Object,$Color); $script:messages += $Object }
        try { & $scriptPath } catch {}

        $LASTEXITCODE | Should -Be 1
    }
}
}
