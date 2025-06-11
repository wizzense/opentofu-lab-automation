. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Import-Module (Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'Download-Archive.psm1') -Force

InModuleScope Download-Archive {
Describe 'Download-Archive' {
    BeforeEach {
        function global:gh {}
        Mock gh {}
        Mock Invoke-WebRequest {}
        Mock Write-Host {}
    }

    It 'uses gh CLI when -UseGh' {
        Download-Archive 'url' 'dest' -UseGh
        Should -Invoke -CommandName gh -Times 1
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
    }

    It 'uses Invoke-WebRequest when -UseGh not specified' {
        Download-Archive 'url' 'dest'
        Should -Invoke -CommandName gh -Times 0
        Should -Invoke -CommandName Invoke-WebRequest -Times 1
    }

    It 'throws when gh download fails and -Required' {
        Mock gh { } -ParameterFilter { $args[0] -eq 'api' }
        $global:LASTEXITCODE = 1
        { Download-Archive 'url' 'dest' -Required -UseGh } | Should -Throw
    }

    It 'throws when Invoke-WebRequest fails and -Required' {
        Mock Invoke-WebRequest { throw 'err' }
        { Download-Archive 'url' 'dest' -Required } | Should -Throw
    }
}
}
