Describe 'OpenTofuInstaller' {

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
        $principal = New-Object psobject
        $principal | Add-Member -MemberType ScriptMethod -Name IsInRole -Value { param($role) $false }
        Mock New-Object -ParameterFilter { $TypeName -eq 'Security.Principal.WindowsPrincipal' } -MockWith { $principal }
        $script:logFile = $null
        $Env:Programfiles = $temp
        $global:startProcessCalled = $false
        function global:Start-Process {
            param(
                $FilePath,
                $ArgumentList,
                $RedirectStandardOutput,
                $RedirectStandardError,
                $Verb,
                $WorkingDirectory,
                [switch]$Wait,
                [switch]$Passthru
            )
            $global:startProcessCalled = $true
            $null = $FilePath
            $null = $ArgumentList
            if ($RedirectStandardOutput) {
                $script:logFile = $RedirectStandardOutput
                New-Item -ItemType File -Path $RedirectStandardOutput -Force | Out-Null
            }
            if ($RedirectStandardError) {
                New-Item -ItemType File -Path $RedirectStandardError -Force | Out-Null
            }
            $proc = [pscustomobject]@{ ExitCode = 0 }
            $proc | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { }
            return $proc
        }
        & $script:scriptPath -installMethod standalone -opentofuVersion '0.0.0' -installPath $temp -allUsers -skipVerify -skipChangePath | Out-Null
        if ($IsWindows) {
            $global:startProcessCalled | Should -BeTrue
        } else {
            # Privilege escalation is skipped on non-Windows platforms.
            $global:startProcessCalled | Should -BeFalse
        }
        (Test-Path $script:logFile) | Should -BeFalse
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
        $principal = New-Object psobject
        $principal | Add-Member -MemberType ScriptMethod -Name IsInRole -Value { param($role) $false }
        Mock New-Object -ParameterFilter { $TypeName -eq 'Security.Principal.WindowsPrincipal' } -MockWith { $principal }
        $Env:Programfiles = $temp
        $global:startProcessCalled = $false
        function global:Start-Process {
            param(
                $FilePath,
                $ArgumentList,
                $RedirectStandardOutput,
                $RedirectStandardError,
                $Verb,
                $WorkingDirectory,
                [switch]$Wait,
                [switch]$Passthru
            )
            $global:startProcessCalled = $true
            $dir = Split-Path $RedirectStandardOutput -Parent
            if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
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


}
