# Fix missing pipe syntax in New-Item commands
$scriptFiles = Get-ChildItem -Path . -Recurse -Include "*.ps1" -Exclude "*.disabled*","*.bak*" | Where-Object { $_.FullName -notmatch "\\archive\\" -and $_.FullName -notmatch "\\backups\\" }
$fileCount = 0
$fixCount = 0

foreach ($file in $scriptFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $updatedContent = $content -replace '(New-Item\s+.*?)\s+Out-Null', '$1 | Out-Null'
    
    if ($content -ne $updatedContent) {
        $fixCount++
        $fileCount++
        Set-Content -Path $file.FullName -Value $updatedContent -NoNewline -Encoding UTF8
        Write-Host "Fixed missing pipe in $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "Fixed $fixCount pipe syntax issues in $fileCount files" -ForegroundColor Cyan
