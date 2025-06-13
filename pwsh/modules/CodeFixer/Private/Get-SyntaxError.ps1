# Get-SyntaxError.ps1
# Helper function to parse PowerShell script and return syntax errors

function Get-SyntaxError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)






]
        [string]$FilePath
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }
    
    try {
        $errors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
        return $errors
    } catch {
        Write-Error "Failed to parse file $FilePath`: $_"
        return $null
    }
}



