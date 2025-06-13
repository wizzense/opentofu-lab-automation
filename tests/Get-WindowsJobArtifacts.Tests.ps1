. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers/TestHelpers.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'pwsh/modules/LabRunner/LabRunner.psd1') -Force

Describe 'Get-WindowsJobArtifacts' {
    BeforeAll {
        $global:scriptPath = Join-Path $PSScriptRoot '..' 'pwsh' 'modules' 'LabRunner' 'Get-WindowsJobArtifacts.ps1'
    }

    BeforeEach {
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -match 'nightly\.link' }
        Mock Expand-Archive {}
        Mock Get-ChildItem { [pscustomobject]@{ FullName = 'dummy.xml' } }
        Mock Select-Xml { @() }
    }
        It 'uses gh CLI when authenticated' {
        function global:gh {}
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{"workflow_runs":[{"id":1}]}' } -ParameterFilter { $args[1] -like '*runs?*' }
        Mock gh { '{"artifacts":[{"name":"pester-coverage-windows-latest","archive_download_url":"cov"},{"name":"pester-results-windows-latest","archive_download_url":"res"}]}' } -ParameterFilter { $args[1] -like '*artifacts*' }
        Mock gh {} -ParameterFilter { $args[1] -eq 'cov' -or $args[1] -eq 'res' }

        & $global:scriptPath

        Should -Invoke -CommandName gh -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' } -Times 1
        Should -Not -Invoke -CommandName Invoke-WebRequest
    }
        It 'falls back to nightly.link when gh auth fails' {
        function global:gh {}
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { throw 'unauthenticated' } -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }


        & $global:scriptPath

        Should -Invoke -CommandName Invoke-WebRequest -Times 1 -ParameterFilter { $Uri -match 'nightly\.link' }
    }
        It 'uses provided run ID with gh' {
        function global:gh {}
        $id = 123
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{"artifacts":[]}' } -ParameterFilter { $args[1] -like "*runs/$id/artifacts" }


        & $global:scriptPath -RunId $id

        Should -Invoke -CommandName gh -ParameterFilter { $args[1] -like "*runs/$id/artifacts" } -Times 1
        Should -Not -Invoke -CommandName Invoke-WebRequest
    }
        It 'uses provided run ID with nightly.link when gh auth fails' {
        function global:gh {}
        $id = 456
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh { throw 'unauthenticated' } -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock Invoke-WebRequest -ModuleName LabSetup {}

        & $global:scriptPath -RunId $id

        Should -Invoke -CommandName Invoke-WebRequest -ParameterFilter { $Uri -match "$id" } -Times 2
    }
        It 'emits a clear message when artifacts are missing' {
        function global:gh {}
        $id = 789
        Mock Get-Command { [pscustomobject]@{ Name = 'gh' } } -ParameterFilter { $Name -eq 'gh' }
        Mock gh {} -ParameterFilter { $args[0] -eq 'auth' -and $args[1] -eq 'status' }
        Mock gh { '{''"workflow_runs"'':[{''"id"'':1}], ''"artifacts"'':[]}' } -ParameterFilter { $args[1] -like "*runs/$id/artifacts" }
        $script:messages = @()
        function global:Write-Host { param($Object, $Color)



; $script:messages += $Object }

        & $global:scriptPath -RunId $id 2>$null

        $LASTEXITCODE | Should -Be 1
        ($script:messages | Select-Object -Last 1) | Should -Match 'No artifacts'
    }
        It 'returns nonzero exit code when download fails' {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq 'gh' }
        Mock Invoke-WebRequest { throw '404' }
        $script:messages = @()
        function global:Write-Host { param($Object,$Color)



; $script:messages += $Object }
        try { & $global:scriptPath } catch {}

        $LASTEXITCODE | Should -Be 1
    }
}



