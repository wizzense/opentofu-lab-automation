Describe 'Get-LabConfig' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\lab_utils\Get-LabConfig.ps1')
    }

    It 'successfully loads default configuration' {
        $config = Get-LabConfig
        ($config -is [pscustomobject]) | Should -BeTrue
        $config.ConfigFile | Should -Match 'default-config.json'
    }

    It 'throws if file is missing' {
        { Get-LabConfig -Path 'nope.json' } | Should -Throw
    }

    It 'throws on malformed JSON' {
        $bad = Join-Path $PSScriptRoot 'bad.json'
        Set-Content -Path $bad -Value '{bad json'
        try {
            { Get-LabConfig -Path $bad } | Should -Throw
        } finally {
            Remove-Item $bad
        }
    }
}
