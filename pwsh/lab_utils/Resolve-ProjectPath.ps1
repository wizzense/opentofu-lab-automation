. (Join-Path $PSScriptRoot 'PathUtils.ps1')

function Resolve-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)






][string]$Name,
        [string]$Root
    )
    if (-not $Root) {
        $Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    } else {
        $Root = (Resolve-Path $Root).Path
    }

    $indexPath = Join-Path $Root 'path-index.yaml'
    if (Test-Path $indexPath) {
        if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
            try { Import-Module powershell-yaml -ErrorAction Stop } catch {}
        }
        try { $index = [hashtable](Get-Content -Raw -Path $indexPath | ConvertFrom-Yaml) } catch { $index = @{} }
        if ($index.ContainsKey($Name) -and $index[$Name]) {
            $pathFromIndex = $index[$Name]
            # Defensive trim for potential CR from YAML value
            $trimmedPath = if ($pathFromIndex -is [string]) { $pathFromIndex.TrimEnd("`r")    } else { $pathFromIndex    }
            if (-not [string]::IsNullOrEmpty($trimmedPath)) {
                $normalizedPath = Normalize-RelativePath $trimmedPath
                return (Join-Path $Root $normalizedPath)
            }
        }
        foreach ($key in $index.Keys) {
            if ((Split-Path $key -Leaf) -eq $Name -and $index[$key]) {
                $pathFromIndex = $index[$key]
                # Defensive trim for potential CR from YAML value
                $trimmedPath = if ($pathFromIndex -is [string]) { $pathFromIndex.TrimEnd("`r")    } else { $pathFromIndex    }
                if (-not [string]::IsNullOrEmpty($trimmedPath)) {
                    $normalizedPath = Normalize-RelativePath $trimmedPath
                    return (Join-Path $Root $normalizedPath)
                }
            }
        }
    }

    $match = Get-ChildItem -Path $Root -Recurse -File -Filter $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $match) { return $match.FullName }
    return $null
}



