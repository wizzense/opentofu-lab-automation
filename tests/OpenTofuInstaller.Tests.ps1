Describe 'OpenTofuInstaller' {
if ($IsLinux -or $IsMacOS) { return }

    BeforeAll {
        # Ensure no lingering TestDrive from previous test runs
        if (Get-PSDrive -Name TestDrive -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name TestDrive -Force -ErrorAction SilentlyContinue
        }
    }

    BeforeEach {
        $script:temp = Join-Path $TestDrive ([System.Guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:temp | Out-Null
    }

    AfterEach {
        Remove-Item -Recurse -Force $script:temp -ErrorAction SilentlyContinue
        Remove-Item Function:Test-IsAdmin -ErrorAction SilentlyContinue
        Remove-Variable -Name OpenTofuInstallerLogDir -Scope Global -ErrorAction SilentlyContinue
    }


    Describe 'logging' -Skip:($IsLinux -or $IsMacOS) {
        It 'creates log files and removes them for elevated unpack' {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1'
        $temp = $script:temp
        $zipPath = Join-Path $temp 'tofu_0.0.0_windows_amd64.zip'
        'dummy' | Set-Content $zipPath
        $hash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash
        Mock Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            if ($Uri -match 'SHA256SUMS$') {
                "${hash}  tofu_0.0.0_windows_amd64.zip" | Set-Content $OutFile
            } else { 'dummy' | Set-Content $OutFile }
        }
        Mock Expand-Archive {}
        function global:Test-IsAdmin { $false }
        $script:logFile = $null

        $Env:Programfiles = $temp
        $global:startProcessCalled = $false
        function global:Start-Process {
            param($FilePath, $ArgumentList, $Verb, $WorkingDirectory, [switch]$Wait, [switch]$Passthru)
            $global:startProcessCalled = $true

            $logDir = $global:OpenTofuInstallerLogDir
            if ($logDir) {
                New-Item -ItemType File -Path (Join-Path $logDir 'stdout.log') -Force | Out-Null
                New-Item -ItemType File -Path (Join-Path $logDir 'stderr.log') -Force | Out-Null
            }

            [pscustomobject]@{ ExitCode = 0 } | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { } -PassThru
        }
        & $script:scriptPath -installMethod standalone -opentofuVersion '0.0.0' -installPath $temp -allUsers -skipVerify -skipChangePath | Out-Null

        $global:startProcessCalled | Should -BeTrue
        $global:OpenTofuInstallerLogDir | Should -Not -BeNullOrEmpty

        if ($IsWindows) {
            $global:startProcessCalled | Should -BeTrue
        } else {
            # Privilege escalation is skipped on non-Windows platforms.
            $global:startProcessCalled | Should -BeFalse
        }

        (Test-Path $global:OpenTofuInstallerLogDir) | Should -BeFalse
        Remove-Item Function:Start-Process -ErrorAction SilentlyContinue
        }

        It 'gracefully handles missing log directory' {
        $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1'
        $temp = $script:temp
        $zipPath = Join-Path $temp 'tofu_0.0.0_windows_amd64.zip'
        'dummy' | Set-Content $zipPath
        $hash = (Get-FileHash -Algorithm SHA256 $zipPath).Hash
        Mock Invoke-WebRequest {
            param([string]$Uri, [string]$OutFile)
            if ($Uri -match 'SHA256SUMS$') {
                "${hash}  tofu_0.0.0_windows_amd64.zip" | Set-Content $OutFile
            } else { 'dummy' | Set-Content $OutFile }
        }
        Mock Expand-Archive {}
        function global:Test-IsAdmin { $false }
        $Env:Programfiles = $temp
        $global:startProcessCalled = $false
        function global:Start-Process {
            param(
                $FilePath,
                $ArgumentList,
                $Verb,
                $WorkingDirectory,
                [switch]$Wait,
                [switch]$Passthru
            )
            $global:startProcessCalled = $true

            $dir = $global:OpenTofuInstallerLogDir
            if ($dir -and (Test-Path $dir)) { Remove-Item -Recurse -Force $dir }
            $proc = [pscustomobject]@{ ExitCode = 0 }
            $proc | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $proc
        }
        & $script:scriptPath -installMethod standalone -opentofuVersion '0.0.0' -installPath $temp -allUsers -skipVerify -skipChangePath | Out-Null
        $global:startProcessCalled | Should -BeTrue
        $LASTEXITCODE | Should -Be 0
        Remove-Item Function:Start-Process -ErrorAction SilentlyContinue
        }
    }

    Describe 'error handling' {
        It 'returns install failed exit code when cosign is missing' {
            $script:scriptPath = Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1'
            $arguments = @(
                '-NoLogo',
                '-NoProfile',
                '-File', $script:scriptPath,
                '-installMethod', 'standalone',
                '-cosignPath', 'nonexistent.exe',
                '-gpgPath', 'nonexistent.exe'
            )
            $Env:Programfiles = $script:temp
            $proc = Microsoft.PowerShell.Management\Start-Process pwsh -ArgumentList $arguments -Wait -PassThru
            $proc.ExitCode | Should -Be 2
        }
    }

    Describe 'macOS defaults' {
        It 'allows -allUsers when Programfiles is missing' -Skip:(-not $IsMacOS) {
            $scriptPath = Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'OpenTofuInstaller.ps1'
            $zip = Join-Path $script:temp 'dummy.zip'
            'dummy' | Set-Content $zip
            Mock Expand-Archive {}
            $Env:Programfiles = $null
            { & $scriptPath -installMethod standalone -installPath $script:temp -allUsers -skipVerify -skipChangePath -internalContinue -internalZipFile $zip } | Should -Not -Throw
        }
    }

}
