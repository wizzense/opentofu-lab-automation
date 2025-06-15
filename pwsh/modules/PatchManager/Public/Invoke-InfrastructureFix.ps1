function Invoke-InfrastructureFix {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("All", "ImportPaths", "TestSyntax", "ModuleStructure")]
        [string]$Fix = "All",
        
        [Parameter(Mandatory=$false)]
        [switch]$AutoFix,
        
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )
    
    # Normalize project root to absolute path
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
    
    # Function for centralized logging
    function Write-FixLog {
        param (
            [string]$Message,
            [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "DEBUG")]
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [$Level] $Message"
        
        # Color coding based on level
        switch ($Level) {
            "INFO"    { Write-Host $formattedMessage -ForegroundColor Gray }
            "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
            "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
            "ERROR"   { Write-Host $formattedMessage -ForegroundColor Red }
            "DEBUG"   { Write-Host $formattedMessage -ForegroundColor DarkGray }
        }
    }
    
    Write-FixLog "Starting infrastructure fixes for $ProjectRoot..." "INFO"
    
    # Load manifest if available
    try {
        $manifest = Get-Content "$ProjectRoot/PROJECT-MANIFEST.json" -Raw | ConvertFrom-Json
        Write-FixLog "Project manifest loaded successfully" "SUCCESS"
    }
    catch {
        Write-FixLog "Failed to load project manifest: $_" "ERROR"
        $manifest = $null
    }
    
    $results = @{
        FixesApplied = 0
        FixesNeeded = 0
        ImportPaths = 0
        TestSyntax = 0
        ModuleStructure = 0
        Errors = 0
    }
    
    # Fix 1: Import paths - Use proper module paths from manifest
    if ($Fix -in @("All", "ImportPaths")) {
        Write-FixLog "Checking import paths..." "INFO"
        
        # Default module paths in case manifest is not available
        $modulePaths = @{
            "CodeFixer" = "/pwsh/modules/CodeFixer/"
            "LabRunner" = "/pwsh/modules/LabRunner/"
            "BackupManager" = "/pwsh/modules/BackupManager/"
        }
        
        # Use manifest if available
        if ($manifest -and $manifest.core -and $manifest.core.modules) {
            $modulePaths = @{}
            $manifest.core.modules.PSObject.Properties | ForEach-Object {
                $moduleName = $_.Name
                $modulePath = $_.Value.path
                $modulePaths[$moduleName] = $modulePath
            }
        }
        
        # Find all PS1 files that might have import statements
        $ps1Files = Get-ChildItem -Path $ProjectRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.FullName -notlike "*/archive/*" -and $_.FullName -notlike "*/backups/*" }
        
        foreach ($file in $ps1Files) {
            $content = Get-Content -Path $file.FullName -Raw
            $needsUpdate = $false
            $updatedContent = $content
            
            # Check for old style imports
            foreach ($moduleName in $modulePaths.Keys) {
                $correctPath = $modulePaths[$moduleName]
                
                # Patterns to fix
                $patterns = @(
                    "Import-Module .*?[/\\]$moduleName",
                    "Import-Module .*?[/\\]$moduleName[/\\]",
                    "Import-Module ['""].*?[/\\]$moduleName['""]",
                    "Import-Module ['""].*?[/\\]$moduleName[/\\]['""]"
                )
                
                foreach ($pattern in $patterns) {
                    if ($content -match $pattern -and $content -notmatch "Import-Module .*?$correctPath") {
                        $results.FixesNeeded++
                        
                        if ($AutoFix -and -not $WhatIf) {
                            # Replace with correct path
                            $updatedContent = $updatedContent -replace $pattern, "Import-Module `"/workspaces/opentofu-lab-automation$correctPath`""
                            $needsUpdate = $true
                            $results.ImportPaths++
                            $results.FixesApplied++
                            Write-FixLog "Fixed import path for $moduleName in $($file.Name)" "SUCCESS"
                        }
                        else {
                            Write-FixLog "Found incorrect import path for $moduleName in $($file.Name)" "WARNING"
                        }
                    }
                }
            }
            
            # Save changes if needed
            if ($needsUpdate -and -not $WhatIf) {
                try {
                    Set-Content -Path $file.FullName -Value $updatedContent -NoNewline
                }
                catch {
                    Write-FixLog "Failed to update $($file.Name): $_" "ERROR"
                    $results.Errors++
                }
            }
        }
    }
    
    # Fix 2: Test file syntax issues
    if ($Fix -in @("All", "TestSyntax")) {
        Write-FixLog "Checking test file syntax..." "INFO"
        
        # Focus on test files
        $testFiles = Get-ChildItem -Path "$ProjectRoot/tests" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $testFiles) {
            try {
                # Parse the file to check for syntax errors
                $parseErrors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$parseErrors)
                
                if ($parseErrors -and $parseErrors.Count -gt 0) {
                    $results.FixesNeeded++
                    Write-FixLog "Found syntax errors in $($file.Name): $($parseErrors.Count) errors" "WARNING"
                    
                    if ($AutoFix -and -not $WhatIf) {
                        # Read the file content
                        $content = Get-Content -Path $file.FullName -Raw
                        $fixed = $false
                        
                        # Common test file issues to fix
                        
                        # Fix 1: Missing closing braces
                        if ($parseErrors -match "missing closing brace") {
                            # Count opening and closing braces
                            $openBraces = ($content -split "{").Count - 1
                            $closeBraces = ($content -split "}").Count - 1
                            
                            if ($openBraces -gt $closeBraces) {
                                # Add missing closing braces
                                $missingBraces = $openBraces - $closeBraces
                                $content = $content.TrimEnd() + "`r`n" + ("}") * $missingBraces
                                $fixed = $true
                                Write-FixLog "Added $missingBraces closing braces to $($file.Name)" "SUCCESS"
                            }
                        }
                        
                        # Fix 2: Incomplete quotes
                        if ($parseErrors -match "Missing closing") {
                            # This is harder to fix automatically, just add some basic handling
                            $singleQuotes = ($content -split "'").Count - 1
                            $doubleQuotes = ($content -split '"').Count - 1
                            
                            if ($singleQuotes % 2 -eq 1) {
                                # Odd number of single quotes, try to fix last one
                                $lastLine = $content -split "`r?`n" | Select-Object -Last 1
                                if (-not $lastLine.Contains("'")) {
                                    $content = $content.TrimEnd() + "'"
                                    $fixed = $true
                                    Write-FixLog "Added closing single quote to $($file.Name)" "SUCCESS"
                                }
                            }
                            
                            if ($doubleQuotes % 2 -eq 1) {
                                # Odd number of double quotes, try to fix last one
                                $lastLine = $content -split "`r?`n" | Select-Object -Last 1
                                if (-not $lastLine.Contains('"')) {
                                    $content = $content.TrimEnd() + '"'
                                    $fixed = $true
                                    Write-FixLog "Added closing double quote to $($file.Name)" "SUCCESS"
                                }
                            }
                        }
                        
                        # Fix 3: Missing parentheses
                        if ($parseErrors -match "missing \(") {
                            # Just log this, it's too risky to auto-fix
                            Write-FixLog "Found missing parenthesis in $($file.Name) - needs manual fix" "WARNING"
                        }
                        
                        if ($fixed) {
                            # Save fixed content
                            try {
                                Set-Content -Path $file.FullName -Value $content -NoNewline
                                $results.TestSyntax++
                                $results.FixesApplied++
                            }
                            catch {
                                Write-FixLog "Failed to update $($file.Name): $_" "ERROR"
                                $results.Errors++
                            }
                        }
                    }
                }
            }
            catch {
                Write-FixLog "Error analyzing $($file.Name): $_" "ERROR"
                $results.Errors++
            }
        }
    }
    
    # Fix 3: Module structure issues
    if ($Fix -in @("All", "ModuleStructure")) {
        Write-FixLog "Checking module structures..." "INFO"
        
        # Define expected module structure
        $moduleStructures = @{
            "CodeFixer" = @("Public", "Private", "CodeFixer.psd1", "CodeFixer.psm1")
            "LabRunner" = @("Public", "Private", "LabRunner.psd1", "LabRunner.psm1")
            "BackupManager" = @("Public", "Private", "BackupManager.psd1", "BackupManager.psm1")
            "PatchManager" = @("Public", "Private", "PatchManager.psd1", "PatchManager.psm1")
        }
        
        # Use manifest if available
        if ($manifest -and $manifest.core -and $manifest.core.modules) {
            $moduleStructures = @{}
            $manifest.core.modules.PSObject.Properties | ForEach-Object {
                $moduleName = $_.Name
                $moduleInfo = $_.Value
                $entryPoint = if ($moduleInfo.entryPoint) { $moduleInfo.entryPoint } else { "$moduleName.psd1" }
                $moduleStructures[$moduleName] = @("Public", "Private", $entryPoint, "$moduleName.psm1")
            }
        }
        
        foreach ($moduleName in $moduleStructures.Keys) {
            # Determine the module path
            $modulePath = if ($modulePaths -and $modulePaths.ContainsKey($moduleName)) {
                Join-Path $ProjectRoot ($modulePaths[$moduleName] -replace "^/", "")
            } else {
                Join-Path $ProjectRoot "pwsh/modules/$moduleName"
            }
            
            # Check if module exists
            if (Test-Path $modulePath) {
                $expectedItems = $moduleStructures[$moduleName]
                $missingItems = @()
                
                foreach ($item in $expectedItems) {
                    $itemPath = Join-Path $modulePath $item
                    if (-not (Test-Path $itemPath)) {
                        $missingItems += $item
                    }
                }
                
                if ($missingItems.Count -gt 0) {
                    $results.FixesNeeded++
                    Write-FixLog "Module $moduleName is missing: $($missingItems -join ', ')" "WARNING"
                    
                    if ($AutoFix -and -not $WhatIf) {
                        foreach ($item in $missingItems) {
                            $itemPath = Join-Path $modulePath $item
                            
                            # Create directory if it's a folder
                            if ($item -in @("Public", "Private")) {
                                if (-not (Test-Path $itemPath)) {
                                    try {
                                        $null = New-Item -Path $itemPath -ItemType Directory -Force -ErrorAction Stop
                                        Write-FixLog "Created directory $item for module $moduleName" "SUCCESS"
                                        $results.ModuleStructure++
                                        $results.FixesApplied++
                                    }                                    catch {
                                        $errorMsg = $_.Exception.Message
                                        Write-FixLog "Failed to create directory $item for module $moduleName - $errorMsg" "ERROR"
                                        $results.Errors++
                                    }
                                }
                            }
                            # Create basic module files if missing
                            elseif ($item -match "\.ps[md]1$") {
                                if (-not (Test-Path $itemPath)) {
                                    try {
                                        # Create basic file content based on type
                                        $fileContent = ""
                                        
                                        if ($item -match "\.psd1$") {
                                            # Module manifest
                                            $manifestCmd = @"
@{
    RootModule = '$moduleName.psm1'
    ModuleVersion = '0.1.0'
    GUID = '$([Guid]::NewGuid().ToString())'
    Author = 'OpenTofu Lab Automation Team'
    CompanyName = 'OpenTofu'
    Copyright = '(c) $(Get-Date -Format "yyyy") OpenTofu. All rights reserved.'
    Description = '$moduleName module for OpenTofu Lab Automation'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()*
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('OpenTofu', 'Lab', 'Automation')
            ProjectUri = 'https://github.com/yourusername/opentofu-lab-automation'
        }
    }
}
"@
                                            $fileContent = $manifestCmd
                                        }
                                        elseif ($item -match "\.psm1$") {
                                            # Module file
                                            $moduleCmd = @"
# $moduleName Module
# Part of OpenTofu Lab Automation

# Get public and private function definition files
`$Public = @(Get-ChildItem -Path `$PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
`$Private = @(Get-ChildItem -Path `$PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach (`$import in @(`$Public + `$Private)) {
    try {
        . `$import.FullName
    } catch {
        Write-Error -Message "Failed to import function `$(`$import.FullName): `$_"
    }
}

# Export Public functions
Export-ModuleMember -Function `$Public.BaseName
"@
                                            $fileContent = $moduleCmd
                                        }
                                        
                                        # Write the file
                                        Set-Content -Path $itemPath -Value $fileContent -NoNewline
                                        Write-FixLog "Created $item file for module $moduleName" "SUCCESS"
                                        $results.ModuleStructure++
                                        $results.FixesApplied++
                                    }                                    catch {
                                        $errorMsg = $_.Exception.Message
                                        Write-FixLog "Failed to create $item file for module $moduleName - $errorMsg" "ERROR"
                                        $results.Errors++
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    Write-FixLog "Module $moduleName structure is complete" "SUCCESS"
                }
            }
            else {
                Write-FixLog "Module $moduleName not found at $modulePath" "WARNING"
            }
        }
    }
    
    # Summary
    Write-FixLog "Infrastructure fixes summary:" "INFO"
    Write-FixLog "  Total issues found: $($results.FixesNeeded)" "INFO"
    Write-FixLog "  Import paths fixed: $($results.ImportPaths)" "INFO"
    Write-FixLog "  Test syntax issues fixed: $($results.TestSyntax)" "INFO"
    Write-FixLog "  Module structure fixes: $($results.ModuleStructure)" "INFO"
    Write-FixLog "  Total fixes applied: $($results.FixesApplied)" "INFO"
    Write-FixLog "  Errors encountered: $($results.Errors)" "INFO"
    
    if ($results.FixesNeeded -eq 0) {
        Write-FixLog "No infrastructure issues found" "SUCCESS"
    }
    elseif ($results.FixesApplied -eq $results.FixesNeeded) {
        Write-FixLog "All infrastructure issues fixed successfully" "SUCCESS"
    }
    elseif ($results.FixesApplied -gt 0) {
        Write-FixLog "Some infrastructure issues fixed, some remain" "WARNING"
    }
    elseif (-not $AutoFix) {
        Write-FixLog "Infrastructure issues found but no fixes applied (AutoFix not enabled)" "WARNING"
    }
    else {
        Write-FixLog "Failed to fix all infrastructure issues" "ERROR"
    }
    
    return [PSCustomObject]$results
}
