# Remove all emojis and unicode characters from files
$ErrorActionPreference = "Stop"

# Define emoji patterns to remove
$emojiPatterns = @(
    '🔍', '🏥', '❌', '✅', '⚠️', '🌿', '🛠️', '🧹', '🚀'
)

# Get all markdown files in .github directory
$files = Get-ChildItem ".github" -Recurse -Filter "*.md" -File

Write-Host "Found $($files.Count) markdown files to clean"

foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)"
    
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        if ($content) {
            $originalContent = $content
            
            # Remove specific emojis
            foreach ($emoji in $emojiPatterns) {
                $content = $content -replace [regex]::Escape($emoji), ''
            }
            
            # Remove any remaining non-ASCII characters (potential emojis)
            $content = $content -replace '[^\x00-\x7F]', ''
            
            # Only update if content changed
            if ($content -ne $originalContent) {
                Set-Content $file.FullName $content -Encoding UTF8 -NoNewline
                Write-Host "  ✓ Cleaned emojis from file" -ForegroundColor Green
            } else {
                Write-Host "  - No emojis found" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Error "Failed to process $($file.FullName): $($_.Exception.Message)"
    }
}

Write-Host "Emoji cleanup completed"
