. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

Describe 'Customize-ISO.ps1'  {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '..' 'iso_tools' 'Customize-ISO.ps1'
    }

    It 'parses without errors' {
        $errs = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errs) | Out-Null
        ($errs ? $errs.Count : 0) | Should -Be 0
    }

    It 'honours parameters and logs each step' {
        $temp = Join-Path $TestDrive ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null

        $iso      = Join-Path $temp 'src.iso'
        $extract  = Join-Path $temp 'extract'
        $mount    = Join-Path $temp 'mount'
        $setup    = Join-Path $temp 'setup.ps1'
        $unattend = Join-Path $temp 'answer.xml'
        $outIso   = Join-Path $temp 'custom.iso'
        $oscExe   = Join-Path $temp 'oscdimg.exe'
        $index    = 5

        New-Item -ItemType File -Path $iso | Out-Null
        New-Item -ItemType File -Path $setup | Out-Null
        New-Item -ItemType File -Path $unattend | Out-Null

        Mock-WriteLog
        Mock Mount-DiskImage { [pscustomobject]@{ DevicePath = $iso } } -ParameterFilter { $ImagePath -eq $iso -and $PassThru }
        Mock Get-Volume { [pscustomobject]@{ DriveLetter = 'Z' } }
        Mock Dismount-DiskImage {} -ParameterFilter { $ImagePath -eq $iso }
        function dism { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$dismArgs) }
        Mock dism {}
        function Start-Process { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$procArgs) }
        Mock Start-Process {}
        Mock robocopy {}
        Mock Copy-Item {}
        Mock New-Item {}
        Mock Remove-Item {}

        & $script:ScriptPath -ISOPath $iso -ExtractPath $extract -MountPath $mount -SetupScript $setup -UnattendXML $unattend -OutputISO $outIso -OscdimgExe $oscExe -WIMIndex $index

        $wimFile = Join-Path $extract 'sources\install.wim'
        Should -Invoke -CommandName Mount-DiskImage -Times 1 -ParameterFilter { $ImagePath -eq $iso -and $PassThru }
        Should -Invoke -CommandName Dismount-DiskImage -Times 1 -ParameterFilter { $ImagePath -eq $iso }
        Should -Invoke -CommandName dism -Times 1 -ParameterFilter { $dismArgs[0] -eq '/Mount-Image' -and $dismArgs[1] -eq "/ImageFile:$wimFile" -and $dismArgs[2] -eq "/Index:$index" -and $dismArgs[3] -eq "/MountDir:$mount" }
        Should -Invoke -CommandName dism -Times 1 -ParameterFilter { $dismArgs[0] -eq '/Unmount-Image' -and $dismArgs[1] -eq "/MountDir:$mount" -and $dismArgs[2] -eq '/Commit' }
        Should -Invoke -CommandName Start-Process -Times 1 -ParameterFilter { $FilePath -eq $oscExe -and $ArgumentList[-1] -eq "`"$outIso`"" }

        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Mounting Windows ISO...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq "Extracting ISO contents to $extract..." }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Dismounting ISO...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Mounting install.wim...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Copying setup.ps1 into Windows...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Committing changes and unmounting install.wim...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Copying autounattend.xml to ISO root...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'Recreating bootable ISO...' }
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq "Custom ISO creation complete! New ISO saved as $outIso" }
    }
}
