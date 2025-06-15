function Invoke-YamlValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Path = ".github/workflows",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Check", "Fix", "Report")]
        [string]$Mode = "Check",
        
        [Parameter(Mandatory=$false)]
        [switch]$Quiet,
        
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-YamlLog {
        param (
            [string]$Message,
            [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        if ($Quiet -and $Level -ne "ERROR") { return }
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [$Level] $Message"
        
        # Color coding based on level
        switch ($Level) {
            "INFO"    { Write-Host $formattedMessage -ForegroundColor Gray }
            "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
            "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
            "ERROR"   { Write-Host $formattedMessage -ForegroundColor Red }
            "DEBUG"   { 
                if (-not $Quiet) { 
                    Write-Host $formattedMessage -ForegroundColor DarkGray 
                }
            }
        }
    }
    
    # Resolve correct path for yamllint config
    $yamlConfigPaths = @(
        "$ProjectRoot/configs/yamllint.yaml",
        "$ProjectRoot/configs/yamllint.yml",
        "$ProjectRoot/.yamllint.yaml",
        "$ProjectRoot/.yamllint.yml",
        "$ProjectRoot/.yamllint"
    )
    
    $yamlConfigPath = $yamlConfigPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $yamlConfigPath) {
        Write-YamlLog "No yamllint config found, creating a default one..." "WARNING"
        # Create a basic yamllint config
        $defaultConfig = @"
extends: default

rules:
  line-length: 
    max: 100
  document-start: disable
  truthy:
    check-keys: false
"@
        $yamlConfigPath = "$ProjectRoot/configs/yamllint.yaml"
        $null = New-Item -Path (Split-Path $yamlConfigPath -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue
        Set-Content -Path $yamlConfigPath -Value $defaultConfig
    }
    
    # Check if yamllint is installed
    try {
        $yamlLintVersion = & yamllint --version 2>&1
        Write-YamlLog "yamllint $yamlLintVersion detected" "DEBUG"
    }
    catch {
        Write-YamlLog "yamllint not found. Attempting to install..." "WARNING"
        try {
            # Try to install yamllint with pip
            & pip install yamllint --quiet
            $yamlLintVersion = & yamllint --version 2>&1
            Write-YamlLog "yamllint installed: $yamlLintVersion" "SUCCESS"
        }
        catch {
            Write-YamlLog "Failed to install yamllint. YAML validation will be minimal." "ERROR"
            # We'll fall back to basic validation below
        }
    }
    
    # Resolve path to check
    $fullPath = Join-Path $ProjectRoot $Path
    
    if (-not (Test-Path $fullPath)) {
        Write-YamlLog "Path not found: $fullPath" "ERROR"
        return $false
    }
    
    # Get all YAML files in the specified path
    $yamlFiles = Get-ChildItem -Path $fullPath -Filter "*.yml","*.yaml" -Recurse -ErrorAction SilentlyContinue
    
    if (-not $yamlFiles -or $yamlFiles.Count -eq 0) {
        Write-YamlLog "No YAML files found in $fullPath" "WARNING"
        return $true
    }
    
    Write-YamlLog "Found $($yamlFiles.Count) YAML files to validate" "INFO"
    
    $results = @{
        Checked = 0
        Fixed = 0
        Errors = 0
        Files = @()
    }
    
    # Process each YAML file
    foreach ($file in $yamlFiles) {
        Write-YamlLog "Processing $($file.Name)..." "DEBUG"
        $results.Checked++
        
        try {
            # First, check if it's valid YAML by attempting to parse it
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            try {
                # Try to parse YAML
                $yamlContent = ConvertFrom-Yaml $content -ErrorAction Stop
                $isValidYaml = $true
            }
            catch {
                # If PowerShell's YAML parsing fails, the file isn't valid YAML
                $isValidYaml = $false
            }
            
            # If we have yamllint, use it for detailed checking
            if ($yamlLintVersion) {
                $lintResults = & yamllint -c $yamlConfigPath $file.FullName 2>&1
                
                if ($lintResults -and $lintResults -match "error|warning") {
                    Write-YamlLog "$($file.Name) has YAML issues:" "WARNING"
                    foreach ($line in $lintResults) {
                        Write-YamlLog "  $line" "DEBUG"
                    }
                    
                    # If in Fix mode, attempt to fix common issues
                    if ($Mode -eq "Fix") {
                        $needsSave = $false
                        
                        # Fix 1: Convert spaces to tabs if inconsistent indentation
                        if ($lintResults -match "indentation") {
                            $content = $content -replace "\t", "  "
                            $needsSave = $true
                        }
                        
                        # Fix 2: Remove trailing spaces
                        if ($lintResults -match "trailing-spaces") {
                            $content = $content -replace " +$", ""
                            $needsSave = $true
                        }
                        
                        # Fix 3: Ensure a single newline at end of file
                        if ($lintResults -match "new-line-at-end-of-file" -or -not $content.EndsWith("`n")) {
                            if ($content.EndsWith("`r`n")) {
                                $content = $content.TrimEnd() + "`r`n"
                            } else {
                                $content = $content.TrimEnd() + "`n"
                            }
                            $needsSave = $true
                        }
                        
                        if ($needsSave) {
                            Set-Content -Path $file.FullName -Value $content -NoNewline
                            $results.Fixed++
                            Write-YamlLog "Applied fixes to $($file.Name)" "SUCCESS"
                            
                            # Check if the fixes resolved the issues
                            $lintResultsAfter = & yamllint -c $yamlConfigPath $file.FullName 2>&1
                            if ($lintResultsAfter -and $lintResultsAfter -match "error|warning") {
                                Write-YamlLog "Some YAML issues remain in $($file.Name)" "WARNING"
                                $results.Errors++
                            }
                        }
                    }
                    else {
                        # In check mode, just report errors
                        $results.Errors++
                    }
                }
                else {
                    Write-YamlLog "$($file.Name) is valid YAML" "SUCCESS"
                }
            }
            elseif (-not $isValidYaml) {
                Write-YamlLog "$($file.Name) is not valid YAML" "ERROR"
                $results.Errors++
                
                # Basic auto-fix without yamllint
                if ($Mode -eq "Fix") {
                    # Try to clean up common YAML issues
                    $content = $content -replace " +$", ""  # Remove trailing spaces
                    if (-not $content.EndsWith("`n")) {
                        if ($content.EndsWith("`r`n")) {
                            $content = $content.TrimEnd() + "`r`n"
                        } else {
                            $content = $content.TrimEnd() + "`n"
                        }
                    }
                    Set-Content -Path $file.FullName -Value $content -NoNewline
                    
                    # Re-check if it's valid now
                    try {
                        $yamlContent = ConvertFrom-Yaml (Get-Content -Path $file.FullName -Raw) -ErrorAction Stop
                        Write-YamlLog "Fixed basic issues in $($file.Name)" "SUCCESS"
                        $results.Fixed++
                    }
                    catch {
                        Write-YamlLog "Could not fully fix $($file.Name)" "ERROR"
                    }
                }
            }
            
            $results.Files += $file.FullName
        }
        catch {
            Write-YamlLog "Error processing $($file.Name): $_" "ERROR"
            $results.Errors++
        }
    }
    
    # Summary report
    Write-YamlLog "YAML Validation Summary:" "INFO"
    Write-YamlLog "  Files checked: $($results.Checked)" "INFO"
    Write-YamlLog "  Files fixed: $($results.Fixed)" "INFO"
    Write-YamlLog "  Files with errors: $($results.Errors)" "INFO"
    
    # Return true if no errors or all were fixed
    return ($results.Errors -eq 0)
}
