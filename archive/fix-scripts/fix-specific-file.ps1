






#!/usr/bin/env pwsh
# Fix a specific PowerShell test file

$filePath = "/workspaces/opentofu-lab-automation/tests/0000_Cleanup-Files.Tests.ps1"
$content = Get-Content -Path $filePath -Raw

# Replace the ternary operator pattern
$newContent = $content -replace '\(if\s+\(([$\w\s]+)\)\s+\{\s+([$\w\s\.]+)\s+\}\s+else\s+\{\s+(\d+)\s+\}\)', '($$(if (1) { $2 } else { $3)' })
$newContent = $newContent -replace '([$\w\s]+)\s+\?\s+([$\w\s\.]+)\s+:\s+(\d+)', 'if ($1) { $2 } else { $3 }'

# Fix if statements without parentheses
$newContent = $newContent -replace 'if\s+([^(].+?)\s+\{', 'if ($1) {'

# Save the modified content
$newContent | Set-Content -Path $filePath -NoNewline

Write-Host "Fixed file: $filePath" -ForegroundColor Green



