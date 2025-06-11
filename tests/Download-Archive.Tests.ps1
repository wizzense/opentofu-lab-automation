. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

InModuleScope LabRunner {
Describe 'Invoke-ArchiveDownload' {
    BeforeEach {
        function global:gh {}
        Mock gh {}
        Mock Invoke-WebRequest {}
        Mock Write-Host {}
    }

    It 'uses gh CLI when -UseGh' {
        Invoke-ArchiveDownload 'url' 'dest' -UseGh
        Should -Invoke -CommandName gh -Times 1
        Should -Invoke -CommandName Invoke-WebRequest -Times 0
    }

    It 'uses Invoke-WebRequest when -UseGh not specified' {
        Invoke-ArchiveDownload 'url' 'dest'
        Should -Invoke -CommandName gh -Times 0
        Should -Invoke -CommandName Invoke-WebRequest -Times 1
    }

    It 'throws if gh fails and -Required is set' {
        Mock gh { throw 'fail' }
        { Invoke-ArchiveDownload 'url' 'dest' -Required -UseGh } | Should -Throw
    }

    It 'throws if Invoke-WebRequest fails and -Required is set' {
        Mock Invoke-WebRequest { throw 'fail' }
        { Invoke-ArchiveDownload 'url' 'dest' -Required } | Should -Throw
    }
}
}
