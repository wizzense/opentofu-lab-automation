function Repair-PowerShellSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    Write-PatchLog "Repairing PowerShell syntax errors in $FilePath" "INFO"
    
    if (-not (Test-Path $FilePath)) {
        Write-PatchLog "File not found: $FilePath" "ERROR"
        return $false
    }
    
    try {        $content = Get-Content -Path $FilePath -Raw
        $fixed = $false
        
        # Fix 1: Variable reference issues with Exception.Message
        if ($content -match '\$\(\$_\.Exception\.Message\)') {
            Write-PatchLog "Fixing variable reference issues with Exception.Message" "INFO"
            $content = $content -replace '\$\(\$_\.Exception\.Message\)', '${_}.Exception.Message'
            $fixed = $true
        }
        
        # Fix 2: Unexpected token '}' issues - often caused by missing opening braces
        # Look for patterns that might indicate missing opening braces
        $lines = $content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            # Check for standalone closing braces that might be syntax errors
            if ($line.Trim() -eq '}' -and $i -gt 0) {
                $previousLine = $lines[$i-1].Trim()
                
                # If previous line doesn't end with expected patterns, this might be an orphaned brace
                if ($previousLine -notmatch '(^|\s+)(catch|finally|else|\{|\}|;)$' -and $previousLine -ne '') {
                    Write-PatchLog "Found potentially orphaned closing brace at line $($i+1)" "WARNING"
                    # We'll be conservative and not auto-fix this without more context
                }
            }
        }
        
        # Fix 3: Function definition issues
        if ($content -match 'function\s+\w+\s*\{[^}]*$') {
            Write-PatchLog "Checking for incomplete function definitions" "INFO"
            # This is complex to fix automatically, so we'll just report it
        }
        
        if ($fixed -and -not $WhatIf) {
            # Create backup
            $backupPath = "$FilePath.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -Path $FilePath -Destination $backupPath
            Write-PatchLog "Created backup: $backupPath" "INFO"
            
            # Apply fixes
            Set-Content -Path $FilePath -Value $content -Encoding UTF8
            Write-PatchLog "Applied PowerShell syntax fixes to $FilePath" "SUCCESS"
        } elseif ($fixed -and $WhatIf) {
            Write-PatchLog "WhatIf: Would fix PowerShell syntax issues in $FilePath" "INFO"
        } else {
            Write-PatchLog "No PowerShell syntax fixes needed for $FilePath" "INFO"
        }
        
        return $fixed
    } catch {
        Write-PatchLog "Error repairing PowerShell syntax in ${FilePath}: ${_}.Exception.Message" "ERROR"
        return $false
    }
}
