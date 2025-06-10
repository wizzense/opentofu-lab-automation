. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
Describe 'OpenTofuInstaller logging' {
    It 'creates log files and removes them for elevated unpack' -Skip:($IsLinux -or $IsMacOS) {
        $script:scriptPath = Join-Path $PSScriptRoot '..\runner_utility_scripts\OpenTofuInstaller.ps1'
        $temp = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zipPath = Join-Path $temp 'tofu_0.0.0_windows_amd64.zip'
        'dummy' | Set-Content $zipPath
        $hash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash
        Mock Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            if ($Uri -match 'SHA256SUMS$') {
                "${hash}  tofu_0.0.0_windows_amd64.zip" | Set-Content $OutFile
            } else { New-Item -ItemType File -Path $OutFile -Force | Out-Null }
        }
        Mock Expand-Archive {}
        $script:logFile = $null
        Mock Start-Process {
            param($FilePath, $ArgumentList, $RedirectStandardOutput, $RedirectStandardError)
            $null = $FilePath
            $null = $ArgumentList
            $script:logFile = $RedirectStandardOutput
            New-Item -ItemType File -Path $RedirectStandardOutput -Force | Out-Null
            New-Item -ItemType File -Path $RedirectStandardError -Force | Out-Null
            $proc = New-Object psobject -Property @{ ExitCode = 0 }
            $proc | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $proc
        }
        & $script:scriptPath -installMethod standalone -opentofuVersion '0.0.0' -installPath $temp -allUsers -skipVerify -skipChangePath | Out-Null
        Assert-MockCalled Start-Process -Times 1
        (Test-Path $script:logFile) | Should -BeFalse
        Remove-Item -Recurse -Force $temp
    }
}

Describe 'OpenTofuInstaller error handling' {
    It 'returns install failed exit code when cosign is missing' {
        $script:scriptPath = Join-Path $PSScriptRoot '..\runner_utility_scripts\OpenTofuInstaller.ps1'
        $arguments = @(
            '-NoLogo',
            '-NoProfile',
            '-File', $script:scriptPath,
            '-installMethod', 'standalone',
            '-cosignPath', 'nonexistent.exe',
            '-gpgPath', 'nonexistent.exe'
        )
        $proc = Start-Process pwsh -ArgumentList $arguments -Wait -PassThru
        $proc.ExitCode | Should -Be 2

    }
}
