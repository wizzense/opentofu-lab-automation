<#
.SYNOPSIS
Tests whether OpenTofu configuration files are syntactically valid and conform to best practices.

.DESCRIPTION
This function validates OpenTofu (Terraform) configuration files for syntax errors,
missing required blocks, and adherence to best practices. It can run in parallel
for faster processing of large projects.

.PARAMETER Path
The root directory to search for *.tf and *.tfvars files

.PARAMETER OutputFormat
The output format: Text, JSON, or CI (for GitHub Actions)

.PARAMETER RunParallel
Run validation in parallel for faster processing of large projects

.PARAMETER UseOpenTofu
Use OpenTofu CLI for validation instead of internal parsing (requires tofu)

.PARAMETER ExcludePath
Directories or files to exclude from validation (wildcards accepted)

.PARAMETER PassThru
Return the validation results as objects

.EXAMPLE
Test-OpenTofuConfig -Path ./infrastructure -RunParallel

.EXAMPLE
Test-OpenTofuConfig -Path ./modules -OutputFormat JSON -UseOpenTofu
#>
function Test-OpenTofuConfig {
    CmdletBinding()
    param(
        Parameter(Position = 0)
        string$Path = ".",
        
        ValidateSet('Text', 'JSON', 'CI')
        string$OutputFormat = 'Text',
        
        switch$RunParallel,
        
        switch$UseOpenTofu,
        
        string$ExcludePath = @("**/modules/**", "**/vendor/**"),
        
        switch$PassThru
    )
    
    Write-Host "Validating OpenTofu configuration files..." -ForegroundColor Cyan
    
    # Check if OpenTofu is available when requested
    if ($UseOpenTofu) {
        try {
            $openTofuVersion = & tofu version 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Warning: OpenTofu not found, falling back to internal parsing" -ForegroundColor Yellow
                $UseOpenTofu = $false
            } else {
                Write-Host "Using OpenTofu version: $openTofuVersion" -ForegroundColor Green
            }
        } catch {
            Write-Host "OpenTofu not installed, falling back to internal parsing" -ForegroundColor Yellow
            $UseOpenTofu = $false
        }
    }
    
    # Find Terraform/OpenTofu files
    $tfFiles = Get-ChildItem -Path $Path -Recurse -Include *.tf,*.tfvars -File | Where-Object{ 
            $include = $true
            foreach ($pattern in $ExcludePath) {
                if ($_.FullName -like $pattern) {
                    $include = $false
                    break
                }
            }
            $include
        }
    
    if ($tfFiles.Count -eq 0) {
        Write-Host "No OpenTofu files found in $Path" -ForegroundColor Yellow
        if ($PassThru) {
            return @()
        }
        return
    }
    
    Write-Host "Found $($tfFiles.Count) OpenTofu files to validate" -ForegroundColor Green
    
    $results = @()
    
    # Define validation script block for parallel execution
    $validationBlock = {
        param($file, $useTofu)
        
        $fileResult = @{
            File = $file.FullName
            Valid = $false
            Errors = @()
            Warnings = @()
        }
        
        try {
            if ($useTofu) {
                # Use OpenTofu CLI for validation
                $output = $null
                $fileDir = Split-Path -Parent $file.FullName
                
                Push-Location $fileDir
                try {
                    # Format check
                    $formatOutput = & tofu fmt -check $file.FullName 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        $fileResult.Warnings += PSCustomObject@{
                            Line = 1
                            Message = "File needs formatting"
                            RuleName = "Format"
                        }
                    }
                    
                    # Validate syntax
                    $output = & tofu validate -json $fileDir 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $fileResult.Valid = $true
                    } else {
                        $errors = $output | ConvertFrom-Json-ErrorAction SilentlyContinue
                        if ($errors.diagnostics) {
                            foreach ($diag in $errors.diagnostics) {
                                $fileResult.Errors += PSCustomObject@{
                                    Line = $diag.range.start.line
                                    Message = $diag.summary
                                    RuleName = "TofuValidation"
                                }
                            }
                        } else {
                            $fileResult.Errors += PSCustomObject@{
                                Line = 1
                                Message = "Validation error: $output"
                                RuleName = "TofuValidation"
                            }
                        }
                    }
                }
                finally {
                    Pop-Location
                }
            }
            else {
                # Internal validation - basic syntax checking
                $content = Get-Content -Path $file.FullName -Raw
                  # Basic syntax validations - Fixed patterns to match valid HCL syntax
                $validationRules = @(
                    @{
                        Pattern = '(?m)^\s*resource\s+"^"+"\s+"^"+"\s*\{'
                        Name = "ValidResourceType"
                        Message = "Invalid resource block syntax"
                        Type = "Error"
                        Invert = $true  # This is a valid pattern, so invert to flag invalid ones
                    },
                    @{
                        Pattern = '(?m)^\s*variable\s+"^"+"\s*\{'
                        Name = "ValidVariableName"
                        Message = "Invalid variable block syntax"
                        Type = "Error"
                        Invert = $true
                    },
                    @{
                        Pattern = '(?m)^\s*output\s+"^"+"\s*\{'
                        Name = "ValidOutputName"
                        Message = "Invalid output block syntax"
                        Type = "Error"
                        Invert = $true
                    },
                    @{
                        Pattern = '\$\{^}*\}'
                        Name = "InterpolationSyntax"
                        Message = "Use HCL2 syntax: use var.name instead of \${var.name}"
                        Type = "Warning"
                        Invert = $false
                    },
                    @{
                        Pattern = '(?m)^\s*#.*TODO'
                        Name = "TodoComments"
                        Message = "TODO comment found - consider completing"
                        Type = "Warning"
                        Invert = $false
                    }
                )
                
                # Check for balanced braces
                $openBraces = ($content  Select-String -Pattern '\{' -AllMatches).Matches.Count
                $closeBraces = ($content  Select-String -Pattern '\}' -AllMatches).Matches.Count
                
                if ($openBraces -ne $closeBraces) {
                    $fileResult.Errors += PSCustomObject@{
                        Line = 1
                        Message = "Unbalanced braces: $openBraces open, $closeBraces close"
                        RuleName = "BalancedBraces"
                    }
                }
                
                # Check for quotes balance
                $quotes = ($content  Select-String -Pattern '"' -AllMatches).Matches.Count
                if ($quotes % 2 -ne 0) {
                    $fileResult.Warnings += PSCustomObject@{
                        Line = 1
                        Message = "Unbalanced quotes detected"
                        RuleName = "BalancedQuotes"
                    }
                }
                  # Apply validation rules
                foreach ($rule in $validationRules) {
                    $regexMatches = regex::Matches($content, $rule.Pattern)
                    
                    if ($rule.Invert) {
                        # For inverted patterns, find lines that DON'T match the valid pattern
                        $lines = $content -split "`n"
                        for ($i = 0; $i -lt $lines.Count; $i++) {
                            $line = $lines$i
                            if ($line -match '^\s*(resourcevariableoutput)\s+') {
                                if (-not ($line -match $rule.Pattern)) {
                                    $violation = PSCustomObject@{
                                        Line = $i + 1
                                        Message = $rule.Message
                                        RuleName = $rule.Name
                                    }
                                    
                                    if ($rule.Type -eq "Error") {
                                        $fileResult.Errors += $violation
                                    } else {
                                        $fileResult.Warnings += $violation
                                    }
                                }
                            }
                        }
                    } else {
                        # For normal patterns, find lines that DO match (problematic patterns)
                        foreach ($match in $regexMatches) {
                            # Calculate line number
                            $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
                            
                            $violation = PSCustomObject@{
                                Line = $lineNumber
                                Message = $rule.Message
                                RuleName = $rule.Name
                            }
                            
                            if ($rule.Type -eq "Error") {
                                $fileResult.Errors += $violation
                            } else {
                                $fileResult.Warnings += $violation
                            }
                        }
                    }
                }
                
                # File is valid if no errors
                $fileResult.Valid = $fileResult.Errors.Count -eq 0
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
    if ($RunParallel -and $tfFiles.Count -gt 1) {
        Write-Host "Running parallel validation..." -ForegroundColor Yellow
        $results = tfFiles | ForEach-Object-Parallel $validationBlock -ArgumentList $_, $UseOpenTofu -ThrottleLimit 4
    } else {
        foreach ($file in $tfFiles) {
            Write-Host "Validating: $($file.Name)" -ForegroundColor Gray
            $results += & $validationBlock $file $UseOpenTofu
        }
    }
    
    # Generate summary
    $totalFiles = $results.Count
    $validFiles = (results | Where-Object{ $_.Valid }).Count
    $totalErrors = (results | ForEach-Object{ $_.Errors.Count }  Measure-Object -Sum).Sum
    $totalWarnings = (results | ForEach-Object{ $_.Warnings.Count }  Measure-Object -Sum).Sum
    
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
            $json = output | ConvertTo-Json-Depth 10
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
            Write-Host "`n=== OpenTofu Validation Summary ===" -ForegroundColor Cyan
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

