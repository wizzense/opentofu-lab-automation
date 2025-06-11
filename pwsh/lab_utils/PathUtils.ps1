function Normalize-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Path
    )
    $segments = $Path -split '[\\/]+'
    $segments | Join-Path -Path $null
}
