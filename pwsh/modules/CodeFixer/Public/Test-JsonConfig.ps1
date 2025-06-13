<#
.SYNOPSIS
Validates JSON configuration files

.DESCRIPTION
This function validates JSON configuration files for syntax errors,
structure issues, and required properties.

.PARAMETER Path
Root path to scan for JSON files (default: "configs")

.PARAMETER OutputFormat
Output format: Text (console), JSON, or CI (for pipelines)

.PARAMETER PassThru
Return the validation results object

.EXAMPLE
Test-JsonConfig

.EXAMPLE
Test-JsonConfig -Path "." -OutputFormat JSON
#>
function Test-JsonConfig {
    [CmdletBinding()]
    param(
        [string]$Path = ".",
        [string[]]$ExcludePattern = @("*backup*", "*archive*")



,
        [ValidateSet('Text', 'JSON', 'CI')]
        [string]$OutputFormat = 'Text',
        [string]$OutputPath,
        [switch]$PassThru
    )
    
    Write-Host "Validating JSON configuration files..." -ForegroundColor Cyan
    
    # Find JSON files
    $jsonFiles = Get-ChildItem -Path $Path -Recurse -Include *.json -File | 
        Where-Object { 
            $include = $true
            foreach ($pattern in $ExcludePattern) {
                if ($_.FullName -like $pattern) {
                    $include = $false
                    break
                }
            }
            $include
        }
    
    if ($jsonFiles.Count -eq 0) {
        Write-Host "No JSON files found in $Path" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found $($jsonFiles.Count) JSON files to validate" -ForegroundColor Green
    
    $allResults = @()
    
    foreach ($file in $jsonFiles) {
        Write-Host "Validating: $($file.Name)" -ForegroundColor Gray
        
        try {
            $content = Get-Content -Path $file.FullName -Raw
            
            # Test JSON parsing
            try {
                $jsonObj = $content | ConvertFrom-Json -ErrorAction Stop
                Write-Host "  ✓ Valid JSON syntax" -ForegroundColor Green
                
                # Additional validation for config files
                if ($file.Name -like "*config*") {
                    $configIssues = Test-ConfigFileStructure -JsonObject $jsonObj -FilePath $file.FullName
                    if ($configIssues.Count -gt 0) {
                        $allResults += $configIssues
                        Write-Host "  ⚠️  $($configIssues.Count) configuration issue(s)" -ForegroundColor Yellow
                    } else {
                        Write-Host "  ✓ Valid configuration structure" -ForegroundColor Green
                    }
                }
                
            } catch {
                $errorMessage = $_.Exception.Message
                $lineNumber = 1
                $columnNumber = 1
                
                # Try to extract line/column info from error message
                if ($errorMessage -match "line (\d+)") {
                    $lineNumber = [int]$Matches[1]
                }
                if ($errorMessage -match "position (\d+)") {
                    $columnNumber = [int]$Matches[1]
                }
                
                $allResults += [PSCustomObject]@{
                    File = $file.FullName
                    Line = $lineNumber
                    Column = $columnNumber
                    Severity = "Error"
                    Message = "Invalid JSON syntax: $errorMessage"
                    RuleName = "JsonSyntaxError"
                    ScriptName = $file.Name
                    ErrorType = "Syntax"
                    FixSuggestion = Get-JsonFixSuggestion -ErrorMessage $errorMessage
                }
                Write-Host "  ❌ JSON syntax error" -ForegroundColor Red
            }
            
        } catch {
            $allResults += [PSCustomObject]@{
                File = $file.FullName
                Line = 1
                Column = 1
                Severity = "Error"
                Message = "Could not read file: $($_.Exception.Message)"
                RuleName = "FileReadError"
                ScriptName = $file.Name
                ErrorType = "System"
                FixSuggestion = "Check file permissions and accessibility"
            }
            Write-Host "  ❌ File read error" -ForegroundColor Red
        }
    }
    
    # Display results based on format
    switch ($OutputFormat) {
        'JSON' {
            $allResults | ConvertTo-Json -Depth 3
        }
        'CI' {
            foreach ($result in $allResults) {
                $level = switch ($result.Severity) {
                    'Error' { 'error' }
                    'Warning' { 'warning' }
                    'Information' { 'notice' }
                    default { 'notice' }
                }
                Write-Host "::$level file=$($result.File),line=$($result.Line),col=$($result.Column)::[$($result.RuleName)] $($result.Message)"
            }
        }
        default {
            if ($allResults.Count -eq 0) {
                Write-Host "✅ All JSON files are valid!" -ForegroundColor Green
            } else {
                Write-Host "`n📋 JSON Validation Results:" -ForegroundColor Cyan
                Write-Host "============================" -ForegroundColor Cyan
                
                $groupedResults = $allResults | Group-Object File
                foreach ($group in $groupedResults) {
                    Write-Host "`n📄 $($group.Name)" -ForegroundColor Yellow
                    Write-Host ("-" * 50) -ForegroundColor Gray
                    
                    foreach ($result in $group.Group | Sort-Object Line) {
                        $color = switch ($result.Severity) {
                            'Error' { 'Red' }
                            'Warning' { 'Yellow' }
                            'Information' { 'Cyan' }
                            default { 'White' }
                        }
                        Write-Host "  Line $($result.Line): [$($result.Severity)] $($result.Message)" -ForegroundColor $color
                        if ($result.FixSuggestion) {
                            Write-Host "    💡 Fix: $($result.FixSuggestion)" -ForegroundColor Green
                        }
                    }
                }
                
                # Summary
                $errorCount = ($allResults | Where-Object Severity -eq 'Error').Count
                $warningCount = ($allResults | Where-Object Severity -eq 'Warning').Count
                $infoCount = ($allResults | Where-Object Severity -eq 'Information').Count
                
                Write-Host "`n📊 Summary:" -ForegroundColor Cyan
                Write-Host "===========" -ForegroundColor Cyan
                Write-Host "Errors: $errorCount" -ForegroundColor $$(if (errorCount -gt 0) { 'Red' } else { 'Green' })
                Write-Host "Warnings: $warningCount" -ForegroundColor $$(if (warningCount -gt 0) { 'Yellow' } else { 'Green' })
                Write-Host "Information: $infoCount" -ForegroundColor Cyan
            }
        }
    }
    
    if ($PassThru) {
        return $allResults
    }
}

function Test-ConfigFileStructure {
    param(
        [PSCustomObject]$JsonObject,
        [string]$FilePath
    )
    
    



$issues = @()
    
    # Check for required config properties
    $requiredProperties = @('RepoUrl', 'LocalPath', 'RunnerScriptName')
    
    foreach ($prop in $requiredProperties) {
        if (-not $JsonObject.PSObject.Properties[$prop]) {
            $issues += [PSCustomObject]@{
                File = $FilePath
                Line = 1
                Column = 1
                Severity = "Warning"
                Message = "Missing recommended property: $prop"
                RuleName = "MissingConfigProperty"
                ScriptName = Split-Path -Path $FilePath -Leaf
            }
        }
    }
    
    # Validate URLs if present
    if ($JsonObject.PSObject.Properties['RepoUrl'] -and $JsonObject.RepoUrl) {
        if ($JsonObject.RepoUrl -notmatch '^https?://') {
            $issues += [PSCustomObject]@{
                File = $FilePath
                Line = 1
                Column = 1
                Severity = "Warning"
                Message = "RepoUrl should start with http:// or https://"
                RuleName = "InvalidUrl"
                ScriptName = Split-Path -Path $FilePath -Leaf
            }
        }
    }
    
    return $issues
}


