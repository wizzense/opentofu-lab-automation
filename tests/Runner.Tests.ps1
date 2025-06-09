Describe 'runner.ps1 configuration' {
    It 'loads default configuration without errors' {
        $configPath = Join-Path $PSScriptRoot '..\config_files\default-config.json'
        { Get-Content -Raw $configPath | ConvertFrom-Json } | Should -Not -Throw
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
