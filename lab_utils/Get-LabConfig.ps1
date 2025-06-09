function Get-LabConfig {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot '..' 'config_files' 'default-config.json')
    )

    if (-not (Test-Path $Path)) {
        throw "Config file not found at $Path"
    }

    try {
        $content = Get-Content -Path $Path -Raw
        $ext = [IO.Path]::GetExtension($Path).ToLowerInvariant()
        switch ($ext) {
            '.json' { return $content | ConvertFrom-Json }
            '.yml' { if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) { return $content | ConvertFrom-Yaml } else { throw 'YAML parsing requires ConvertFrom-Yaml cmdlet.' } }
            '.yaml' { if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) { return $content | ConvertFrom-Yaml } else { throw 'YAML parsing requires ConvertFrom-Yaml cmdlet.' } }
            default { throw "Unsupported file extension: $ext" }
        }
    } catch {
        throw "Failed to parse configuration: $($_.Exception.Message)"
    }
}
