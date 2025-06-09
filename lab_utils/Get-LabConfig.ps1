function Get-LabConfig {
    [CmdletBinding()]
    param(

        [string]$Path = (Join-Path $PSScriptRoot '..\config_files\default-config.json')
    )

    if (-not (Test-Path $Path)) {
        throw "Config file not found at $Path"
    }

    try {

        $content = Get-Content -Raw -Path $Path
        if ($Path -match '\.ya?ml$') {
            if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
                throw 'YAML support not available'
            }
            return $content | ConvertFrom-Yaml
        }
        else {
            return $content | ConvertFrom-Json
        }
    }
    catch {
        throw "Failed to parse config file $Path. $_"


    }
}
