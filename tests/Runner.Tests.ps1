. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
. (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')
# These tests exercise logic that works on all platforms. Avoid skipping when
# running on Linux or macOS so we can verify behaviour in CI.
$script:SkipNonWindows = $false

if (-not (Get-Command Get-MenuSelection -ErrorAction SilentlyContinue)) {
    function global:Get-MenuSelection {}
}

Describe 'runner.ps1 syntax' {
    It 'parses without errors' {
        $path = Join-Path $PSScriptRoot '..' 'runner.ps1'
        $errs = $null
        [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs) | Out-Null
        ($errs ? $errs.Count : 0) | Should -Be 0
    }
}

Describe 'runner.ps1 configuration' {
    It 'loads default configuration without errors' {
        $modulePath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-LabConfig.ps1'
        . $modulePath
        $configPath = Join-Path $PSScriptRoot '..' 'config_files' 'default-config.json'
        { Get-LabConfig -Path $configPath } | Should -Not -Throw
    }
}

Describe 'runner.ps1 script selection' -Skip:($SkipNonWindows) {
    BeforeAll {
        # Use script-scoped variable so PSScriptAnalyzer recognizes cross-block usage
        $script:runnerPath = Join-Path $PSScriptRoot '..' 'runner.ps1'
        . (Join-Path $PSScriptRoot 'helpers' 'TestHelpers.ps1')

        function New-RunnerTestEnv {
            $root = Join-Path $TestDrive ([guid]::NewGuid())
            New-Item -ItemType Directory -Path $root | Out-Null
            Copy-Item $script:runnerPath -Destination $root

            $rsDir = Join-Path $root 'runner_scripts'
            New-Item -ItemType Directory -Path $rsDir | Out-Null

            $utils = Join-Path $root 'runner_utility_scripts'
            New-Item -ItemType Directory -Path $utils | Out-Null
            'function Write-CustomLog { param([string]$Message,[string]$Level) }' |
                Set-Content -Path (Join-Path $utils 'Logger.ps1')

            $labs = Join-Path $root 'lab_utils'
            New-Item -ItemType Directory -Path $labs | Out-Null
            'function Get-LabConfig { param([string]$Path) Get-Content -Raw $Path | ConvertFrom-Json }' |
                Set-Content -Path (Join-Path $labs 'Get-LabConfig.ps1')
            'function Format-Config { param($Config) $Config | ConvertTo-Json -Depth 5 }' |
                Set-Content -Path (Join-Path $labs 'Format-Config.ps1')
            'function Get-MenuSelection { }' |
                Set-Content -Path (Join-Path $labs 'Menu.ps1')

            $cfgDir = Join-Path $root 'config_files'
            New-Item -ItemType Directory -Path $cfgDir | Out-Null
            '{}' | Set-Content -Path (Join-Path $cfgDir 'default-config.json')
            '{}' | Set-Content -Path (Join-Path $cfgDir 'recommended-config.json')

            return $root
        }
    }
    AfterEach {
        Remove-Item Function:Write-Host -ErrorAction SilentlyContinue
        Remove-Item Function:Read-Host -ErrorAction SilentlyContinue
        Remove-Item Function:Write-Warning -ErrorAction SilentlyContinue
        Remove-Item Function:Write-Error -ErrorAction SilentlyContinue
    }

    It 'runs non-interactively when -Scripts is supplied' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $dummy      = Join-Path $scriptsDir '0001_Test.ps1'
        "Param([PSCustomObject]`$Config)
exit 0" | Set-Content -Path $dummy

        Push-Location $tempDir
        Mock Get-MenuSelection {}
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
        Pop-Location

        Should -Invoke -CommandName Get-MenuSelection -Times 0

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'uses pwsh from PSHOME when not in PATH' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $dummy      = Join-Path $scriptsDir '0001_Test.ps1'
        "Param([PSCustomObject]`$Config)
exit 0" | Set-Content -Path $dummy

        $oldPath = $env:PATH
        $env:PATH  = ''
        try {
            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location
        } finally {
            $env:PATH = $oldPath
        }

        $code | Should -Be 0

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'exits with code 1 when -Scripts has no matching prefixes' {
        $tempDir   = New-RunnerTestEnv
        Push-Location $tempDir
        Mock-WriteLog
        & "$tempDir/runner.ps1" -Scripts '9999' -Auto | Out-Null
        $code = $LASTEXITCODE
        Pop-Location

        $code | Should -Be 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'continues executing all scripts even if one fails' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out1       = Join-Path $tempDir 'out1.txt'
        $out2       = Join-Path $tempDir 'out2.txt'
        @"
Param([PSCustomObject]`$Config)
'1' | Out-File -FilePath "$out1"
exit 1
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Fail.ps1')
        @"
Param([PSCustomObject]`$Config)
'2' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path (Join-Path $scriptsDir '0002_Success.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001,0002' -Auto | Out-Null
        $code = $LASTEXITCODE
        Pop-Location

        Test-Path $out1 | Should -BeTrue
        Test-Path $out2 | Should -BeTrue
        $code | Should -Be 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'continues executing all scripts when one throws' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out1       = Join-Path $tempDir 'out1_throw.txt'
        $out2       = Join-Path $tempDir 'out2_throw.txt'
        @"
Param([PSCustomObject]`$Config)
'1' | Out-File -FilePath "$out1"
throw 'bad'
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Throw.ps1')
        @"
Param([PSCustomObject]`$Config)
'2' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path (Join-Path $scriptsDir '0002_Success.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001,0002' -Auto | Out-Null
        $code = $LASTEXITCODE
        Pop-Location

        Test-Path $out1 | Should -BeTrue
        Test-Path $out2 | Should -BeTrue
        $code | Should -Be 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'runs only cleanup script when 0000 is combined with others in Auto mode' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out1       = Join-Path $tempDir 'out_cleanup.txt'
        $out2       = Join-Path $tempDir 'out_other.txt'
        @"
Param([PSCustomObject]`$Config)
'c' | Out-File -FilePath "$out1"
exit 0
"@ | Set-Content -Path (Join-Path $scriptsDir '0000_Cleanup.ps1')
        @"
Param([PSCustomObject]`$Config)
'o' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Other.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0000,0001' -Auto | Out-Null
        $code = $LASTEXITCODE
        Pop-Location

        Test-Path $out1 | Should -BeTrue
        Test-Path $out2 | Should -BeFalse
        $code | Should -Be 0

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'forces script execution when flag disabled using -Force' {
        $tempDir   = New-RunnerTestEnv
        $configDir = Join-Path $tempDir 'config_files'
        $configFile = Join-Path $configDir 'config.json'
        '{ "RunFoo": false }' | Set-Content -Path $configFile
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out = Join-Path $tempDir 'out.txt'
        @"
Param([PSCustomObject]`$Config)
if (`$Config.RunFoo -eq `$true) { 'foo' | Out-File -FilePath "$out" } else { Write-Output 'skip' }
"@ |
            Set-Content -Path (Join-Path $scriptsDir '0001_Test.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001' -Auto -ConfigFile $configFile -Force | Out-Null
        $updated = Get-Content -Raw $configFile | ConvertFrom-Json
        Pop-Location

        Test-Path $out | Should -BeTrue
        $updated.RunFoo | Should -BeTrue

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'skips script action when flag disabled and -Force not used' {
        $tempDir   = New-RunnerTestEnv
        $configDir = Join-Path $tempDir 'config_files'
        $configFile = Join-Path $configDir 'config.json'
        '{ "RunFoo": false }' | Set-Content -Path $configFile
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out = Join-Path $tempDir 'out.txt'
        @"
Param([PSCustomObject]`$Config)
if (`$Config.RunFoo -eq `$true) { 'foo' | Out-File -FilePath "$out" }
"@ |
            Set-Content -Path (Join-Path $scriptsDir '0001_Test.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001' -Auto -ConfigFile $configFile | Out-Null
        $updated = Get-Content -Raw $configFile | ConvertFrom-Json
        Pop-Location

        Test-Path $out | Should -BeFalse
        $updated.RunFoo | Should -BeFalse

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'reports success when script omits an exit statement' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out        = Join-Path $tempDir 'out.txt'
        @"
Param([PSCustomObject]`$Config)
'ok' | Out-File -FilePath "$out"
"@ |
            Set-Content -Path (Join-Path $scriptsDir '0001_NoExit.ps1')

        Push-Location $tempDir
        Mock Read-Host { throw 'Read-Host should not be called' }
        & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
        $code = $LASTEXITCODE
        Pop-Location

        Test-Path $out | Should -BeTrue
        $code | Should -Be 0

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'suppresses informational logs when -Verbosity silent is used' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        @"
Param([PSCustomObject]`$Config)
Write-Warning 'warn message'
Write-Error 'err message'
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Log.ps1')

        Push-Location $tempDir
        $script:logLines = @()
        $script:warnings = @()
        $script:errors   = @()
        function global:Write-Host {
            param([object]$Object,[string]$ForegroundColor)
            process { $script:logLines += "$Object" }
        }
        function global:Write-Warning { param([string]$Message) $script:warnings += $Message }
        function global:Write-Error   { param([string]$Message) $script:errors   += $Message }
        $output = & "$tempDir/runner.ps1" -Scripts '0001' -Auto -Verbosity 'silent' *>&1
        Pop-Location

        ($script:logLines | Measure-Object).Count | Should -Be 0
        ($output | Out-String).Trim()       | Should -BeEmpty
        $script:warnings | Should -Contain 'warn message'
        $script:errors   | Should -Contain 'err message'

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}

    It 'suppresses informational logs when -Verbosity silent is used' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        @"
Param([PSCustomObject]`$Config)
Write-Warning 'warn message'
Write-Error 'err message'
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Log.ps1')

        Push-Location $tempDir
        $script:logLines = @()
        $script:warnings = @()
        $script:errors   = @()
        function global:Write-Host { param([object]$Object,[string]$ForegroundColor) process { $script:logLines += "$Object" } }
        function global:Write-Warning { param([string]$Message) $script:warnings += $Message }
        function global:Write-Error   { param([string]$Message) $script:errors   += $Message }
        $output = & "$tempDir/runner.ps1" -Scripts '0001' -Auto -Verbosity silent *>&1
        Pop-Location

        ($script:logLines | Measure-Object).Count | Should -Be 0
        ($output | Out-String).Trim()       | Should -BeEmpty
        $script:warnings | Should -Contain 'warn message'
        $script:errors   | Should -Contain 'err message'

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'prompts twice when -Auto is used without -Scripts' -Skip:($SkipNonWindows) {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        "Param([PSCustomObject]`$Config)
exit 0" | Set-Content -Path (Join-Path $scriptsDir '0001_Test.ps1')

        $script:idx = 0
        Mock Get-MenuSelection {
            if ($script:idx -eq 0) { $script:idx++; return '0001_Test.ps1' }
            return @()
        }

        Push-Location $tempDir
        & "$tempDir/runner.ps1" -Auto | Out-Null
        Pop-Location

        Should -Invoke -CommandName Get-MenuSelection -Times 2

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'handles empty or invalid selection by logging and doing nothing' -Skip:($SkipNonWindows) {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        $out        = Join-Path $tempDir 'out.txt'
        @"
Param([PSCustomObject]`$Config)
'ran' | Out-File -FilePath "$out"
exit 0
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Test.ps1')

        Mock Get-MenuSelection { @() }
        Mock-WriteLog

        Push-Location $tempDir
        & "$tempDir/runner.ps1" -Auto | Out-Null
        Pop-Location

        Test-Path $out | Should -BeFalse
        Should -Invoke -CommandName Write-CustomLog -Times 1 -ParameterFilter { $Message -eq 'No scripts selected.' }
        Should -Invoke -CommandName Get-MenuSelection -Times 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }

    It 'logs script output exactly once' {
        $tempDir   = New-RunnerTestEnv
        $scriptsDir = Join-Path $tempDir 'runner_scripts'
        @"
Param([PSCustomObject]`$Config)
Write-Output 'hello world'
"@ | Set-Content -Path (Join-Path $scriptsDir '0001_Echo.ps1')

        Push-Location $tempDir
        $script:messages = @()
        Mock-WriteLog
        Set-Item -Path Function:Write-CustomLog -Value { param($Message,$Level) $script:messages += $Message }
        & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
        Pop-Location

        ($script:messages | Where-Object { $_ -match 'hello world' }).Count | Should -Be 1

        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}

Describe 'Set-LabConfig' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Menu.ps1')
        function Set-LabConfig {
            [CmdletBinding(SupportsShouldProcess)]
            param([hashtable]$ConfigObject)

            if (-not $PSCmdlet.ShouldProcess('ConfigObject', 'Update configuration prompts')) {
                return $ConfigObject
            }

            $menu = @('InstallGit','InstallGo','InstallOpenTofu','LocalPath','Node_Dependencies','Done')
            $selection = Get-MenuSelection -Items $menu -Title 'Edit configuration'
            foreach ($choice in $selection) {
                switch ($choice) {
                    'Done' { return $ConfigObject }
                    'InstallGit' {
                        $ans = Read-Host "InstallGit? (Y/N) [$($ConfigObject.InstallGit)]"
                        if ($ans) { $ConfigObject.InstallGit = $ans -match '^(?i)y' }
                    }
                    'InstallGo' {
                        $ans = Read-Host "InstallGo? (Y/N) [$($ConfigObject.InstallGo)]"
                        if ($ans) { $ConfigObject.InstallGo = $ans -match '^(?i)y' }
                    }
                    'InstallOpenTofu' {
                        $ans = Read-Host "InstallOpenTofu? (Y/N) [$($ConfigObject.InstallOpenTofu)]"
                        if ($ans) { $ConfigObject.InstallOpenTofu = $ans -match '^(?i)y' }
                    }
                    'LocalPath' {
                        $ans = Read-Host "Local repo path [$($ConfigObject.LocalPath)]"
                        if ($ans) { $ConfigObject.LocalPath = $ans }
                    }
                    'Node_Dependencies' {
                        $p1 = Read-Host "Path to Node project [$($ConfigObject.Node_Dependencies.NpmPath)]"
                        if ($p1) { $ConfigObject.Node_Dependencies.NpmPath = $p1 }
                        $p2 = Read-Host "Create NpmPath if missing? (Y/N) [$($ConfigObject.Node_Dependencies.CreateNpmPath)]"
                        if ($p2) { $ConfigObject.Node_Dependencies.CreateNpmPath = $p2 -match '^(?i)y' }
                    }
                }
            }
            return $ConfigObject
        }
    }

    It 'updates selections and saves to JSON' -Skip:($SkipNonWindows) {
        $config = @{
            InstallGit = $false
            InstallGo  = $false
            InstallOpenTofu = $false
            LocalPath = ''
            Node_Dependencies = @{ NpmPath = 'C:\\Old'; CreateNpmPath = $false }
        }

        $answers = @(
            'Y',      # InstallGit
            'Y',      # InstallOpenTofu
            'C:\\Repo',
            'C:\\Node',
            'Y'
        )
        $script:idx = 0
        function global:Read-Host {
            param([string]$Prompt)
            $null = $Prompt
            $answers[$script:idx++]
        }

        Mock Get-MenuSelection {
            'InstallGit',
            'InstallOpenTofu',
            'LocalPath',
            'Node_Dependencies',
            'Done'
        }

        $updated = Set-LabConfig -ConfigObject $config

        $temp = Join-Path ([System.IO.Path]::GetTempPath()) 'config-test.json'
        $updated | ConvertTo-Json -Depth 5 | Out-File -FilePath $temp -Encoding utf8

        $saved = Get-Content -Raw $temp | ConvertFrom-Json

        $saved.InstallGit | Should -BeTrue
        $saved.InstallGo  | Should -BeFalse
        $saved.InstallOpenTofu | Should -BeTrue
        $saved.LocalPath | Should -Be 'C:\\Repo'
        $saved.Node_Dependencies.NpmPath | Should -Be 'C:\\Node'
        $saved.Node_Dependencies.CreateNpmPath | Should -BeTrue

        Remove-Item $temp -ErrorAction SilentlyContinue
    }
}
