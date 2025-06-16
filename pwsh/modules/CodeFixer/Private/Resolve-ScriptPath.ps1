# Resolve-ScriptPath.ps1
# Helper function to resolve script paths in the repository

function Resolve-ScriptPath {
    CmdletBinding()
    param(
        Parameter(Mandatory=$true, Position=0)







        string$Path,
        
        string$BaseDir = ""
    )
    
    # If BaseDir not specified, use current directory
    if (-not $BaseDir) {
        $BaseDir = Get-Location
    }
    
    # If path is absolute, return as-is
    if (System.IO.Path::IsPathRooted($Path)) {
        return $Path
    }
    
    # Try to find the repository root
    $repoRoot = $BaseDir
    while (-not (Test-Path (Join-Path $repoRoot ".git")) -and -not (Test-Path (Join-Path $repoRoot "CHANGELOG.md")) -and $repoRoot -ne "/") {
        $repoRoot = Split-Path $repoRoot -Parent
    }
    
    # Check if we found the repository root
    if ($repoRoot -eq "/" -and -not (Test-Path (Join-Path $repoRoot ".git")) -and -not (Test-Path (Join-Path $repoRoot "CHANGELOG.md"))) {
        # Failed to find repository root, just use the BaseDir
        $repoRoot = $BaseDir
    }
    
    # Common directories
    $directories = @(
        $BaseDir,
        $repoRoot,
        (Join-Path $repoRoot "pwsh"),
        (Join-Path $repoRoot "pwsh" "runner_scripts"),
        (Join-Path $repoRoot "tests"),
        (Join-Path $repoRoot "scripts")
    )
    
    # Try to find the script in common directories
    foreach ($dir in $directories) {
        $scriptPath = Join-Path $dir $Path
        if (Test-Path $scriptPath) {
            return $scriptPath
        }
    }
    
    # Return the path relative to the repository root if nothing else found
    return (Join-Path $repoRoot $Path)
}



