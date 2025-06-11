. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Expand-All' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'pwsh' 'lab_utils' 'Expand-All.psm1'
        if (-not (Test-Path $modulePath)) {
            throw "Required module is missing: $modulePath"
        }
        Import-Module $modulePath -Force
    }
    BeforeEach {
        Mock-WriteLog
    }
    AfterEach {
        Remove-Item Function:Write-CustomLog -ErrorAction SilentlyContinue
        Remove-Item Function:Read-LoggedInput -ErrorAction SilentlyContinue
    }

    It 'expands a specific ZIP file when provided' {
        $temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zipPath = Join-Path $temp 'archive.zip'
        New-Item -ItemType File -Path $zipPath | Out-Null

        Mock Expand-Archive {}
        Mock Read-LoggedInput { 'y' } -ModuleName Expand-All

        Expand-All -ZipFile $zipPath

        Should -Invoke -CommandName Expand-Archive -Times 1 -ParameterFilter {
            $Path -eq $zipPath -and
            $DestinationPath -eq (Join-Path $temp 'archive')
        }
    }

    It 'expands all ZIP files recursively when no path is given' {
        $temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zip1 = Join-Path $temp 'a.zip'
        $subDir = Join-Path $temp 'sub'
        $zip2 = Join-Path $subDir 'b.zip'

        Mock Expand-Archive {}
        Mock Read-LoggedInput { 'y' } -ModuleName Expand-All
        Mock Get-ChildItem {
            @(
                [pscustomobject]@{ FullName = $zip1; DirectoryName = $temp; BaseName = 'a' },
                [pscustomobject]@{ FullName = $zip2; DirectoryName = $subDir; BaseName = 'b' }
            )
        } -ParameterFilter {
            $Path -eq (Get-Location) -and $Recurse -and $Filter -eq '*.zip'
        }

        Push-Location $temp
        try {
            Expand-All
        } finally {
            Pop-Location
        }

        Should -Invoke -CommandName Expand-Archive -Times 1 -ParameterFilter { $Path -eq $zip1 -and $DestinationPath -eq (Join-Path $temp 'a') }
        Should -Invoke -CommandName Expand-Archive -Times 1 -ParameterFilter { $Path -eq $zip2 -and $DestinationPath -eq (Join-Path $subDir 'b') }
        Should -Invoke -CommandName Get-ChildItem -Times 1
    }

    It 'logs message when specified ZIP file does not exist' {
        $zipPath = Join-Path $TestDrive 'missing.zip'

        Mock Expand-Archive {}
        Mock Read-LoggedInput {} -ModuleName Expand-All

        Expand-All -ZipFile $zipPath

        Should -Invoke -CommandName Expand-Archive -Times 0
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter {
            $Message -Like '*does not exist*'
        }
    }

    It 'cancels when user declines expansion' {
        $temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zipPath = Join-Path $temp 'archive.zip'
        New-Item -ItemType File -Path $zipPath | Out-Null

        Mock Expand-Archive {}
        Mock Read-LoggedInput { 'n' } -ModuleName Expand-All

        Expand-All -ZipFile $zipPath

        Should -Invoke -CommandName Expand-Archive -Times 0
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter {
            $Message -eq 'Operation canceled.'
        }
    }
}

