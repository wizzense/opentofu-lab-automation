. (Join-Path $PSScriptRoot 'TestDriveCleanup.ps1')
if ($IsLinux -or $IsMacOS) { return }
Describe 'runner.ps1 configuration' {
    It 'loads default configuration without errors' {
        $modulePath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-LabConfig.ps1'
        . $modulePath
        $configPath = Join-Path $PSScriptRoot '..' 'config_files' 'default-config.json'
        { Get-LabConfig -Path $configPath } | Should -Not -Throw
    }
}

Describe 'runner.ps1 script selection' -Skip:($IsLinux -or $IsMacOS) {
    BeforeAll {
        # Use script-scoped variable so PSScriptAnalyzer recognizes cross-block usage
        $script:runnerPath = Join-Path $PSScriptRoot '..' 'runner.ps1'
        $modulePath = Join-Path $PSScriptRoot '..' 'lab_utils' 'Get-LabConfig.ps1'
        . $modulePath
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
        . (Join-Path $PSScriptRoot '..' 'lab_utils' 'Menu.ps1')
    }

    It 'runs non-interactively when -Scripts is supplied' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $dummy = Join-Path $scriptsDir '0001_Test.ps1'
            'Param([PSCustomObject]$Config)
exit 0' | Set-Content -Path $dummy

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
            Pop-Location
        } finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'exits with code 1 when -Scripts has no matching prefixes' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir

            Push-Location $tempDir
            Mock Write-CustomLog {}
            & "$tempDir/runner.ps1" -Scripts '9999' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location

            $code | Should -Be 1
        } finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'continues executing all scripts even if one fails' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out1 = Join-Path $tempDir 'out1.txt'
            $out2 = Join-Path $tempDir 'out2.txt'
            $fail = Join-Path $scriptsDir '0001_Fail.ps1'
            @"
Param([PSCustomObject]`$Config)
'1' | Out-File -FilePath "$out1"
exit 1
"@ | Set-Content -Path $fail
            $succ = Join-Path $scriptsDir '0002_Success.ps1'
            @"
Param([PSCustomObject]`$Config)
'2' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path $succ

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001,0002' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location

            Test-Path $out1 | Should -BeTrue
            Test-Path $out2 | Should -BeTrue
            $code | Should -Be 1
        } finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'continues executing all scripts when one throws' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out1 = Join-Path $tempDir 'out1_throw.txt'
            $out2 = Join-Path $tempDir 'out2_throw.txt'
            $fail = Join-Path $scriptsDir '0001_Throw.ps1'
            @"
Param([PSCustomObject]`$Config)
'1' | Out-File -FilePath "$out1"
throw 'bad'
"@ | Set-Content -Path $fail
            $succ = Join-Path $scriptsDir '0002_Success.ps1'
            @"
Param([PSCustomObject]`$Config)
'2' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path $succ

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001,0002' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location

            Test-Path $out1 | Should -BeTrue
            Test-Path $out2 | Should -BeTrue
            $code | Should -Be 1
        }
        finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'runs only cleanup script when 0000 is combined with others in Auto mode' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out1 = Join-Path $tempDir 'out_cleanup.txt'
            $out2 = Join-Path $tempDir 'out_other.txt'
            $clean = Join-Path $scriptsDir '0000_Cleanup.ps1'
            @"
Param([PSCustomObject]`$Config)
'c' | Out-File -FilePath "$out1"
exit 0
"@ | Set-Content -Path $clean
            $other = Join-Path $scriptsDir '0001_Other.ps1'
            @"
Param([PSCustomObject]`$Config)
'o' | Out-File -FilePath "$out2"
exit 0
"@ | Set-Content -Path $other

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0000,0001' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location

            Test-Path $out1 | Should -BeTrue
            Test-Path $out2 | Should -BeFalse
            $code | Should -Be 0
        } finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'forces script execution when flag disabled using -Force' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            $configDir = Join-Path $tempDir 'config_files'
            $null = New-Item -ItemType Directory -Path $configDir
            $configFile = Join-Path $configDir 'config.json'
            '{ "RunFoo": false }' | Set-Content -Path $configFile
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out = Join-Path $tempDir 'out.txt'
            $scriptFile = Join-Path $scriptsDir '0001_Test.ps1'
            @"
Param([PSCustomObject]`$Config)
if (`$Config.RunFoo -eq `$true) { 'foo' | Out-File -FilePath "$out" } else { Write-Output 'skip' }
"@ | Set-Content -Path $scriptFile

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001' -Auto -ConfigFile $configFile -Force | Out-Null
            $updated = Get-Content -Raw $configFile | ConvertFrom-Json
            Pop-Location

            Test-Path $out | Should -BeTrue
            $updated.RunFoo | Should -BeTrue
        }
        finally { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }

    It 'reports success when script omits an exit statement' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out = Join-Path $tempDir 'out.txt'
            $scriptFile = Join-Path $scriptsDir '0001_NoExit.ps1'
            @"
Param([PSCustomObject]`$Config)
'ok' | Out-File -FilePath "$out"
"@ | Set-Content -Path $scriptFile

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -Scripts '0001' -Auto | Out-Null
            $code = $LASTEXITCODE
            Pop-Location

            Test-Path $out | Should -BeTrue
            $code | Should -Be 0
        }
        finally { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }

    It 'suppresses informational logs when -Quiet is used' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $scriptFile = Join-Path $scriptsDir '0001_Log.ps1'
            @"
Param([PSCustomObject]`$Config)
Write-Warning 'warn message'
Write-Error 'err message'
"@ | Set-Content -Path $scriptFile

            Push-Location $tempDir
            $script:logLines = @()
            function global:Write-Host {
                param([Parameter(Mandatory=$true,Position=0)][string]$Object,
                      [Parameter(Position=1)][string]$ForegroundColor)
                $script:logLines += $Object
            }
            $output = & "$tempDir/runner.ps1" -Scripts '0001' -Auto -Quiet *>&1
            Remove-Item Function:\Write-Host -ErrorAction SilentlyContinue
            Pop-Location

        $script:logLines | Should -Not -Contain '==== Loading configuration ===='
        ($output | Out-String) | Should -Match 'warn message'
        ($output | Out-String) | Should -Match 'err message'
    }
    finally { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
}

    It 'suppresses informational logs when -Verbosity silent is used' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $scriptFile = Join-Path $scriptsDir '0001_Log.ps1'
            @"
Param([PSCustomObject]`$Config)
Write-Warning 'warn message'
Write-Error 'err message'
"@ | Set-Content -Path $scriptFile

            Push-Location $tempDir
            $script:logLines = @()
            function global:Write-Host {
                param([Parameter(Mandatory=$true,Position=0)][string]$Object,
                      [Parameter(Position=1)][string]$ForegroundColor)
                $script:logLines += $Object
            }
            $output = & "$tempDir/runner.ps1" -Scripts '0001' -Auto -Verbosity silent *>&1
            Remove-Item Function:\Write-Host -ErrorAction SilentlyContinue
            Pop-Location

            $script:logLines | Should -Not -Contain '==== Loading configuration ===='
            ($output | Out-String) | Should -Match 'warn message'
            ($output | Out-String) | Should -Match 'err message'
        }
        finally { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }

    It 'prompts for script selection when no -Scripts argument is supplied' -Skip:($IsLinux -or $IsMacOS) {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $dummy = Join-Path $scriptsDir '0001_Test.ps1'
            'Param([PSCustomObject]$Config)
exit 0' | Set-Content -Path $dummy

            $script:idx = 0
            Mock Get-MenuSelection {
                if ($script:idx -eq 0) {
                    $script:idx++
                    return '0001_Test.ps1'
                }
                return @()
            }

            Push-Location $tempDir
            & "$tempDir/runner.ps1" -Auto | Out-Null
            Pop-Location

            Assert-MockCalled Get-MenuSelection -Times 2
        } finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }

    It 'handles empty or invalid selection by logging and doing nothing' -Skip:($IsLinux -or $IsMacOS) {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $script:runnerPath -Destination $tempDir
            Copy-Item (Join-Path $PSScriptRoot '..' 'runner_utility_scripts') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'lab_utils') -Destination $tempDir -Recurse
            Copy-Item (Join-Path $PSScriptRoot '..' 'config_files') -Destination (Join-Path $tempDir 'config_files') -Recurse
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $out = Join-Path $tempDir 'out.txt'
            $scriptFile = Join-Path $scriptsDir '0001_Test.ps1'
            @"
Param([PSCustomObject]`$Config)
'ran' | Out-File -FilePath "$out"
exit 0
"@ | Set-Content -Path $scriptFile

            Mock Get-MenuSelection { @() }
            Mock Write-CustomLog {}

            Push-Location $tempDir
            & "$tempDir/runner.ps1" -Auto | Out-Null
            Pop-Location

            Test-Path $out | Should -BeFalse
            Assert-MockCalled Write-CustomLog -ParameterFilter { $Message -eq 'No scripts selected.' } -Times 1
            Assert-MockCalled Get-MenuSelection -Times 1
        }
        finally {
            Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Set-LabConfig' {
    BeforeAll {
        function Set-LabConfig {
            [CmdletBinding(SupportsShouldProcess)]
            param([hashtable]$ConfigObject)

            if (-not $PSCmdlet.ShouldProcess('ConfigObject', 'Update configuration prompts')) {
                return $ConfigObject
            }

        $installPrompts = [ordered]@{
            InstallGit      = 'Install Git'
            InstallGo       = 'Install Go'
            InstallOpenTofu = 'Install OpenTofu'
        }
        foreach ($key in $installPrompts.Keys) {
            $current = [bool]$ConfigObject[$key]
            $answer  = Read-Host "$($installPrompts[$key])? (Y/N) [$current]"
            if ($answer) { $ConfigObject[$key] = $answer -match '^(?i)y' }
        }

        $localPath = Read-Host "Local repo path [`$($ConfigObject['LocalPath'])`]"
        if ($localPath) { $ConfigObject['LocalPath'] = $localPath }

        $npmPath = Read-Host "Path to Node project [`$($ConfigObject.Node_Dependencies.NpmPath)`]"
        if ($npmPath) { $ConfigObject.Node_Dependencies.NpmPath = $npmPath }
        $createPath = Read-Host "Create NpmPath if missing? (Y/N) [`$($ConfigObject.Node_Dependencies.CreateNpmPath)`]"
        if ($createPath) { $ConfigObject.Node_Dependencies.CreateNpmPath = $createPath -match '^(?i)y' }

        return $ConfigObject
    }
    }

    It 'updates selections and saves to JSON' -Skip:($IsLinux -or $IsMacOS) {
        $config = @{
            InstallGit = $false
            InstallGo  = $false
            InstallOpenTofu = $false
            LocalPath = ''
            Node_Dependencies = @{ NpmPath = 'C:\\Old'; CreateNpmPath = $false }
        }

        $answers = @('Y','N','Y','C:\\Repo','C:\\Node','Y')
        $script:idx = 0
        function global:Read-Host {
            param([string]$Prompt)
            $null = $Prompt
            $answers[$script:idx++]
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
