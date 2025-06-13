# fix-ternary-syntax.ps1
# This script fixes the ternary operator and if-statement syntax issues in our test files

param(
    [switch]$WhatIf,
    [string]$Directory = "tests"
)





$ErrorActionPreference = 'Stop'

# Find all PowerShell files
$files = Get-ChildItem -Path $Directory -Recurse -Include "*.ps1" | Select-Object -ExpandProperty FullName

$fixedCount = 0
$fileCount = 0

Write-Host "Found $($files.Count) PowerShell files to check"

foreach ($file in $files) {
    $content = Get-Content -Path $file -Raw
    $originalContent = $content

    # Replace the ternary operator pattern
    # ($(if ($errors) { $errors.Count } else { 0) becomes $(if (errors) { $errors.Count } else { 0 }) })
    $newContent = $content -replace '\(\s*(\$\w+)\s*\?\s*([^:]+)\s*:\s*([^\)]+)\s*\)', '$(if (1) { $2 } else { $3 })'
    
    # Also fix ternary operators without parentheses
    $newContent = $newContent -replace '(\$\w+)\s+\?\s+(.+?)\s+:\s+(.+?)([;\r\n]|$)', 'if ($1) {$2} else {$3}$4'
    
    # Fix if statements without parentheses
    $newContent = $newContent -replace 'if\s+([^(].+?)\s+\{', 'if ($1) {'
    
    # Fix broken -if/-else constructs (from previous incorrect fixes)
    $newContent = $newContent -replace '(\S+)\s+-if\s+\{([^}]+)\}\s+-else\s+\{([^}]+)\}', 'if ($1) {$2} else {$3}'

    if ($newContent -ne $originalContent) {
        $fileCount++
        if ($WhatIf) {
            Write-Host "Would fix syntax in: $file"
        }
        else {
            $newContent | Set-Content -Path $file
            Write-Host "Fixed ternary operators in: $file"
            $fixedCount++
        }
    }
}

if ($WhatIf) {
    Write-Host "Would have fixed $fileCount files with ternary operator syntax."
} else {
    Write-Host "Fixed ternary operator syntax in $fixedCount files."
}


