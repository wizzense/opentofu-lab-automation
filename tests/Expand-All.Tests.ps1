. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
Describe 'Expand-All' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Expand-All.ps1')
    }
    BeforeEach {
        function global:Write-CustomLog {}
        Mock Write-CustomLog {}
    }
    AfterEach {
        Remove-Item Function:Write-CustomLog -ErrorAction SilentlyContinue
    }

    It 'expands a specific ZIP file when provided' {
        $temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zipPath = Join-Path $temp 'archive.zip'
        New-Item -ItemType File -Path $zipPath | Out-Null

        Mock Expand-Archive {}
        Mock Read-Host { 'y' }

        Expand-All -ZipFile $zipPath

        Assert-MockCalled Expand-Archive -Times 1 -ParameterFilter {
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
        Mock Read-Host { 'y' }
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

        Assert-MockCalled Expand-Archive -ParameterFilter { $Path -eq $zip1 -and $DestinationPath -eq (Join-Path $temp 'a') } -Times 1
        Assert-MockCalled Expand-Archive -ParameterFilter { $Path -eq $zip2 -and $DestinationPath -eq (Join-Path $subDir 'b') } -Times 1
        Assert-MockCalled Get-ChildItem -Times 1
    }
}

