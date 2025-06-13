function Normalize-RelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)



][string]$Path
    )
    if ([string]::IsNullOrEmpty($Path)) {
        throw [System.ArgumentException]::new("Path cannot be null or empty", "Path")
    }
    $segments = $Path -split '[\\/]+'
    $segments -join [System.IO.Path]::DirectorySeparatorChar
}


