<#
.SYNOPSIS
Tests whether YAML configuration files are syntactically valid and well-formed.

.DESCRIPTION
This function validates YAML configuration files for syntax errors, proper structure,
and common formatting issues. It supports various YAML files including workflow files,
configuration files, and documentation.

.PARAMETER Path
The root directory to search for *.yaml, *.yml files

.PARAMETER OutputFormat
The output format: Text, JSON, or CI (for GitHub Actions)

.PARAMETER RunParallel
Run validation in parallel for faster processing of large projects

.PARAMETER ExcludePath
Directories or files to exclude from validation (wildcards accepted)

.PARAMETER PassThru
Return the validation results as objects

.PARAMETER UseYamlLint
Use yamllint external tool if available for enhanced validation

.EXAMPLE
Test-YamlConfig -Path ./.github/workflows -RunParallel

.EXAMPLE
Test-YamlConfig -Path ./configs -OutputFormat JSON -UseYamlLint
#>
function Test-YamlConfig {
    CmdletBinding()
    param(
        Parameter(Position = 0)
        string$Path = ".",
        
        ValidateSet('Text', 'JSON', 'CI')
        string$OutputFormat = 'Text',
        
        switch$RunParallel,
        
        string$ExcludePath = @("**/node_modules/**", "**/vendor/**"),
        
        switch$PassThru,
        
        switch$UseYamlLint
    )
    
    Write-Host "Validating YAML configuration files..." -ForegroundColor Cyan
    
    # Check if yamllint is available when requested
    if ($UseYamlLint) {
        try {
            $yamlLintVersion = & yamllint --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: yamllint not found, falling back to internal parsing" -ForegroundColor Yellow
                $UseYamlLint = $false
            } else {
                Write-Host "Using yamllint: $yamlLintVersion" -ForegroundColor Green
            }
        } catch {
            Write-Host "yamllint not installed, falling back to internal parsing" -ForegroundColor Yellow
            $UseYamlLint = $false
        }
    }
    
    # Find YAML files
    $yamlFiles = Get-ChildItem -Path $Path -Recurse -Include *.yaml,*.yml -File  
        Where-Object { 
            $include = $true
            foreach ($pattern in $ExcludePath) {
                if ($_.FullName -like $pattern) {
                    $include = $false
                    break
                }
            }
            $include
        }
    
    if ($yamlFiles.Count -eq 0) {
        Write-Host "No YAML files found in $Path" -ForegroundColor Yellow
        if ($PassThru) {
            return @()
        }
        return
    }
    
    Write-Host "Found $($yamlFiles.Count) YAML files to validate" -ForegroundColor Green
    
    $results = @()
    
    # Define validation script block for parallel execution
    $validationBlock = {
        param($file, $useYamlLint)
        
        $fileResult = @{
            File = $file.FullName
            Valid = $false
            Errors = @()
            Warnings = @()
        }
        
        try {
            if ($useYamlLint) {
                # Use yamllint for validation
                $output = & yamllint -f parsable $file.FullName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $fileResult.Valid = $true
                } else {
                    foreach ($line in $output) {
                        if ($line -match '^(.+):(\d+):(\d+):\s*\(\w+)\\s*(.+)$') {
                            $lineNum = int$matches2
                            $level = $matches4
                            $message = $matches5
                            
                            $violation = PSCustomObject@{
                                Line = $lineNum
                                Message = $message
                                RuleName = "YamlLint"
                            }
                            
                            if ($level -eq "error") {
                                $fileResult.Errors += $violation
                            } else {
                                $fileResult.Warnings += $violation
                            }
                        }
                    }
                }
            }
            else {
                # Internal validation - basic YAML parsing
                $content = Get-Content -Path $file.FullName -Raw
                
                try {                    # Try to parse YAML using PowerShell-Yaml if available
                    if (Get-Module -ListAvailable -Name powershell-yaml) {
                        Import-Module powershell-yaml -Force
                        $null = ConvertFrom-Yaml -Yaml $content
                        $fileResult.Valid = $true
                    }
                    else {
                        # Basic validation without YAML parser
                        $lines = $content -split "`n"
                        $lineNumber = 0
                        
                        foreach ($line in $lines) {
                            $lineNumber++
                            $trimmedLine = $line.TrimEnd()
                            
                            # Skip empty lines and comments
                            if (string::IsNullOrWhiteSpace($trimmedLine) -or $trimmedLine.StartsWith('#')) {
                                continue
                            }
                            
                            # Check for basic YAML syntax issues
                            if ($trimmedLine.Contains("`t")) {
                                $fileResult.Errors += PSCustomObject@{
                                    Line = $lineNumber
                                    Message = "Tab characters not allowed in YAML (use spaces)"
                                    RuleName = "NoTabs"
                                }
                            }
                            
                            # Check for trailing spaces
                            if ($line -ne $trimmedLine) {
                                $fileResult.Warnings += PSCustomObject@{
                                    Line = $lineNumber
                                    Message = "Trailing whitespace detected"
                                    RuleName = "TrailingSpaces"
                                }
                            }
                            
                            # Check for common YAML mistakes
                            if ($trimmedLine -match ':\s*$' -and -not $trimmedLine.StartsWith('-')) {
                                # Key without value - could be intentional for objects
                                continue
                            }
                            
                            if ($trimmedLine -match '^\s*-\s*$') {
                                $fileResult.Warnings += PSCustomObject@{
                                    Line = $lineNumber
                                    Message = "Empty list item"
                                    RuleName = "EmptyListItem"
                                }
                            }
                        }
                        
                        # If no errors found in basic checks, consider it valid
                        $fileResult.Valid = $fileResult.Errors.Count -eq 0
                    }
                }
                catch {
                    $fileResult.Errors += PSCustomObject@{
                        Line = 1
                        Message = "YAML parsing error: $($_.Exception.Message)"
                        RuleName = "ParseError"
                    }
                }
            }
        }
        catch {
            $fileResult.Errors += PSCustomObject@{
                Line = 1
                Message = "Exception during validation: $($_.Exception.Message)"
                RuleName = "ValidationException"
            }
        }
        
        return $fileResult
    }
    
    # Run validation (parallel or sequential)
    if ($RunParallel -and $yamlFiles.Count -gt 1) {
        Write-Host "Running parallel validation..." -ForegroundColor Yellow
        $results = yamlFiles | ForEach-Object -Parallel $validationBlock -ArgumentList $_, $UseYamlLint -ThrottleLimit 4
    } else {
        foreach ($file in $yamlFiles) {
            Write-Host "Validating: $($file.Name)" -ForegroundColor Gray
            $results += & $validationBlock $file $UseYamlLint
        }
    }
    
    # Generate summary
    $totalFiles = $results.Count
    $validFiles = (results | Where-Object { $_.Valid }).Count
    $totalErrors = (results | ForEach-Object { $_.Errors.Count }  Measure-Object -Sum).Sum
    $totalWarnings = (results | ForEach-Object { $_.Warnings.Count }  Measure-Object -Sum).Sum
    
    # Output results based on format
    switch ($OutputFormat) {
        'JSON' {
            $output = @{
                Summary = @{
                    TotalFiles = $totalFiles
                    ValidFiles = $validFiles
                    InvalidFiles = $totalFiles - $validFiles
                    TotalErrors = $totalErrors
                    TotalWarnings = $totalWarnings
                }
                Results = $results
            }
            $json = output | ConvertTo-Json -Depth 10
            Write-Output $json
        }
        
        'CI' {
            foreach ($result in $results) {
                foreach ($error in $result.Errors) {
                    Write-Output "::error file=$($result.File),line=$($error.Line)::$($error.Message)"
                }
                foreach ($warning in $result.Warnings) {
                    Write-Output "::warning file=$($result.File),line=$($warning.Line)::$($warning.Message)"
                }
            }
        }
        
        'Text' {
            Write-Host "`n=== YAML Validation Summary ===" -ForegroundColor Cyan
            Write-Host "Total files: $totalFiles" -ForegroundColor White
            Write-Host "Valid files: $validFiles" -ForegroundColor Green
            Write-Host "Invalid files: $($totalFiles - $validFiles)" -ForegroundColor Red
            Write-Host "Total errors: $totalErrors" -ForegroundColor Red
            Write-Host "Total warnings: $totalWarnings" -ForegroundColor Yellow
            
            foreach ($result in $results) {
                if (-not $result.Valid -or $result.Warnings.Count -gt 0) {
                    Write-Host "`n--- $($result.File) ---" -ForegroundColor White
                    
                    foreach ($error in $result.Errors) {
                        Write-Host "  ERROR (Line $($error.Line)): $($error.Message)" -ForegroundColor Red
                    }
                    
                    foreach ($warning in $result.Warnings) {
                        Write-Host "  WARNING (Line $($warning.Line)): $($warning.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    
    # Return results if PassThru is specified
    if ($PassThru) {
        return $results
    }
    
    # Set exit code for CI scenarios
    if ($totalErrors -gt 0) {
        $global:LASTEXITCODE = 1
    } else {
        $global:LASTEXITCODE = 0
    }
}

