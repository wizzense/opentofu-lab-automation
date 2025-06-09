Describe 'Write-CustomLog' {
    It 'works when LogFilePath variable is not defined' {
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        { Write-CustomLog 'test message' } | Should -Not -Throw
    }

    It 'writes to specified log file when provided' {
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()).ToString() + '.log'
        Remove-Variable -Name LogFilePath -Scope Global -ErrorAction SilentlyContinue
        Write-CustomLog 'hello world' -LogFile $tempFile
        $content = Get-Content $tempFile -Raw
        $content | Should -Match 'hello world'
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}
