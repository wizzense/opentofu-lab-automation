#Requires -Version 7.0

<#
.SYNOPSIS
Auto-fix common syntax errors in test files

.DESCRIPTION
This script automatically fixes the most common syntax errors found in test files:
1. Extra closing braces
2. Missing closing braces
3. Updates hardcoded module imports to admin-friendly imports
#>

# Import required modules by name (admin-friendly)
Import-Module 'Logging' -Force

function Fix-TestFileSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        
        # Skip empty files
        if ([string]::IsNullOrWhiteSpace($content)) {
            return @{
                Status = 'Skipped'
                Message = 'File is empty'
                Changed = $false
            }
        }
        
        $originalContent = $content
        $changes = @()
        
        # Fix 1: Remove extra trailing closing braces and empty lines
        $content = $content -replace '\}\s*\}\s*$', '}'
        $content = $content.TrimEnd()
        if ($content -ne $originalContent) {
            $changes += 'Removed extra closing braces'
        }
        
        # Fix 2: Update hardcoded module imports to admin-friendly
        $oldImportPattern = 'Import-Module "\$env:PWSH_MODULES_PATH/(\w+)/" -Force'
        $newImportPattern = "Import-Module '$1' -Force"
        if ($content -match $oldImportPattern) {
            $content = $content -replace $oldImportPattern, $newImportPattern
            $changes += 'Updated module imports to admin-friendly'
        }
        
        # Fix 3: Ensure proper Describe block structure
        $describeCount = ($content | Select-String -Pattern 'Describe\s+' -AllMatches).Matches.Count
        $openBraceCount = ($content | Select-String -Pattern '\{' -AllMatches).Matches.Count
        $closeBraceCount = ($content | Select-String -Pattern '\}' -AllMatches).Matches.Count
        
        # If we have unmatched braces, try to fix simple cases
        if ($openBraceCount -gt $closeBraceCount) {
            $missingBraces = $openBraceCount - $closeBraceCount
            $content += ("`n}" * $missingBraces)
            $changes += "Added $missingBraces missing closing braces"
        }
        
        # Write the fixed content back if changes were made
        if ($content -ne $originalContent) {
            Set-Content -Path $FilePath -Value $content -Encoding UTF8
            return @{
                Status = 'Fixed'
                Message = $changes -join '; '
                Changed = $true
            }
        } else {
            return @{
                Status = 'NoChange'
                Message = 'No changes needed'
                Changed = $false
            }
        }
    }
    catch {
        return @{
            Status = 'Error'
            Message = $_.Exception.Message
            Changed = $false
        }
    }
}

function Fix-AllTestFiles {
    [CmdletBinding()]
    param()
    
    begin {
        Write-CustomLog "Starting auto-fix of test file syntax errors..." -Level INFO
        $totalFiles = 0
        $fixedFiles = 0
        $skippedFiles = 0
        $errorFiles = 0
        $unchangedFiles = 0
    }
    
    process {
        try {
            # Get all test files that currently have syntax errors
            $testFiles = Get-ChildItem -Path "tests" -Filter "*.Tests.ps1" -Recurse -ErrorAction Stop
            
            foreach ($file in $testFiles) {
                $totalFiles++
                Write-CustomLog "Processing: $($file.Name)" -Level INFO
                
                $result = Fix-TestFileSyntax -FilePath $file.FullName
                
                switch ($result.Status) {
                    'Fixed' {
                        Write-CustomLog "✅ $($file.Name): $($result.Message)" -Level SUCCESS
                        $fixedFiles++
                    }
                    'NoChange' {
                        Write-CustomLog "ℹ️  $($file.Name): No changes needed" -Level INFO
                        $unchangedFiles++
                    }
                    'Skipped' {
                        Write-CustomLog "⚠️  $($file.Name): $($result.Message)" -Level WARN
                        $skippedFiles++
                    }
                    'Error' {
                        Write-CustomLog "❌ $($file.Name): $($result.Message)" -Level ERROR
                        $errorFiles++
                    }
                }
            }
        }
        catch {
            Write-CustomLog "Error during auto-fix: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog "Auto-fix Summary:" -Level INFO
        Write-CustomLog "  Total files: $totalFiles" -Level INFO
        Write-CustomLog "  Fixed: $fixedFiles" -Level SUCCESS
        Write-CustomLog "  Unchanged: $unchangedFiles" -Level INFO
        Write-CustomLog "  Skipped: $skippedFiles" -Level WARN
        Write-CustomLog "  Errors: $errorFiles" -Level ERROR
        
        if ($fixedFiles -gt 0) {
            Write-CustomLog "🎉 Successfully fixed $fixedFiles test files!" -Level SUCCESS
            Write-CustomLog "Run Validate-TestSyntax.ps1 again to check the results" -Level INFO
        }
        
        return $fixedFiles
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Write-CustomLog "OpenTofu Lab Automation - Test File Auto-Fix" -Level INFO
    Write-CustomLog "=======================================" -Level INFO
    
    $fixedCount = Fix-AllTestFiles
    
    if ($fixedCount -gt 0) {
        Write-CustomLog "Auto-fix completed successfully!" -Level SUCCESS
        Write-CustomLog "Now run: ./Validate-TestSyntax.ps1 to verify the fixes" -Level INFO
        exit 0
    } else {
        Write-CustomLog "No files needed fixing" -Level INFO
        exit 0
    }
}
