Describe 'Write-CustomLog' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'runner_utility_scripts' 'Logger.ps1')
    }
    It 'works when LogFilePath variable is not defined' {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        { Write-CustomLog 'test message' } | Should -Not -Throw
    }

    It 'works under strict mode without global variable' {
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        Set-StrictMode -Version Latest
        { Write-CustomLog 'another test' } | Should -Not -Throw
        Set-StrictMode -Off
    }

    It 'writes to specified log file when provided' {
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid()).ToString() + '.log')
        Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        Write-CustomLog 'hello world' -LogFile $tempFile
        $content = Get-Content $tempFile -Raw
        $content | Should -Match 'hello world'
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }

    It 'defaults to LogFilePath variable when not provided' {
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid()).ToString() + '.log')
        $script:LogFilePath = $tempFile
        try {
            Write-CustomLog 'variable default works'
            $content = Get-Content $tempFile -Raw
            $content | Should -Match 'variable default works'
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            Remove-Variable -Name LogFilePath -Scope Script -ErrorAction SilentlyContinue
        }
    }
}
