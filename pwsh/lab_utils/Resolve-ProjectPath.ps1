function Resolve-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$Root
    )
    if (-not $Root) {
        $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    } else {
        $Root = (Resolve-Path $Root).Path
    }

    $match = Get-ChildItem -Path $Root -Recurse -File -Filter $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $match) { return $match.FullName }
    return $null
}
