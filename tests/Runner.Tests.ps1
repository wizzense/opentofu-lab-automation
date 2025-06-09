Describe 'runner.ps1 configuration' {
    It 'loads default configuration without errors' {
        $modulePath = Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1'
        . $modulePath
        $configPath = Join-Path $PSScriptRoot '..\config_files\default-config.json'
        { Get-LabConfig -Path $configPath } | Should -Not -Throw
    }
}

Describe 'runner.ps1 script selection' {
    BeforeAll {
        $runnerPath = Join-Path $PSScriptRoot '..\runner.ps1'
        $modulePath = Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1'
        . $modulePath
    }

    It 'runs non-interactively when -RunScripts is supplied' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $runnerPath -Destination $tempDir
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $dummy = Join-Path $scriptsDir '0001_Test.ps1'
            'Param([PSCustomObject]$Config)' | Set-Content -Path $dummy

            Push-Location $tempDir
            Mock Read-Host { throw 'Read-Host should not be called' }
            & "$tempDir/runner.ps1" -RunScripts '0001' -AutoAccept | Out-Null
            Pop-Location
        } finally {
            Remove-Item -Recurse -Force $tempDir
        }
    }

    It 'prompts for script selection when no -RunScripts argument is supplied' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
        $null = New-Item -ItemType Directory -Path $tempDir
        try {
            Copy-Item $runnerPath -Destination $tempDir
            $scriptsDir = Join-Path $tempDir 'runner_scripts'
            $null = New-Item -ItemType Directory -Path $scriptsDir
            $dummy = Join-Path $scriptsDir '0001_Test.ps1'
            'Param([PSCustomObject]$Config)' | Set-Content -Path $dummy

            $responses = @('0001')
            $index = 0
            Mock Read-Host { $responses[$index++] }
            Push-Location $tempDir
            & "$tempDir/runner.ps1" -AutoAccept | Out-Null
            Pop-Location
            Assert-MockCalled Read-Host -Times 1 -Exactly
        } finally {
            Remove-Item -Recurse -Force $tempDir
        }
    }
}

Describe 'Customize-Config' {
    function Customize-Config {
        param([hashtable]$ConfigObject)

        $installPrompts = @{ 
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

        return $ConfigObject
    }

    It 'updates selections and saves to JSON' {
        $config = @{
            InstallGit = $false
            InstallGo  = $false
            InstallOpenTofu = $false
            LocalPath = ''
            Node_Dependencies = @{ NpmPath = 'C:\\Old' }
        }

        $answers = @('Y','N','Y','C:\\Repo','C:\\Node')
        $idx = 0
        Mock Read-Host { $answers[$idx++] }

        $updated = Customize-Config -ConfigObject $config

        $temp = Join-Path $env:TEMP 'config-test.json'
        $updated | ConvertTo-Json -Depth 5 | Out-File -FilePath $temp -Encoding utf8

        $saved = Get-Content -Raw $temp | ConvertFrom-Json

        $saved.InstallGit | Should -BeTrue
        $saved.InstallGo  | Should -BeFalse
        $saved.InstallOpenTofu | Should -BeTrue
        $saved.LocalPath | Should -Be 'C:\\Repo'
        $saved.Node_Dependencies.NpmPath | Should -Be 'C:\\Node'

        Remove-Item $temp -ErrorAction SilentlyContinue
    }
}
