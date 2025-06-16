# Remove all unicode characters from YAML files
$ErrorActionPreference = "Stop"

# Get all YAML files
$files = Get-ChildItem ".github" -Recurse -Filter "*.yml" -File
$files += Get-ChildItem ".github" -Recurse -Filter "*.yaml" -File

Write-Host "Found $($files.Count) YAML files to clean"

foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)"
    
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        if ($content) {
            $originalContent = $content
            
            # Remove all non-ASCII characters (which includes emojis and unicode symbols)
            $content = $content -replace '[^\x00-\x7F]', ''
            
            # Clean up any double spaces that might have been created
            $content = $content -replace '  +', ' '
            
            # Only update if content changed
            if ($content -ne $originalContent) {
                Set-Content $file.FullName $content -Encoding UTF8 -NoNewline
                Write-Host "   Cleaned unicode characters from file" -ForegroundColor Green
            } else {
                Write-Host "  - No unicode characters found" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Error "Failed to process $($file.FullName): $($_.Exception.Message)"
    }
}

Write-Host "Unicode cleanup completed"
