<#
.SYNOPSIS
Monitors a directory for script changes and automatically generates tests

.DESCRIPTION
Watches a directory for new or changed PowerShell scripts and automatically
generates corresponding test files. This is useful for ensuring that all
scripts have associated tests.

.PARAMETER Directory
Directory to monitor for changes

.PARAMETER OutputDirectory
Directory where test files will be created (default: "tests")

.PARAMETER IntervalSeconds
How often to check for changes (default: 30 seconds)

.EXAMPLE
Watch-ScriptDirectory -Directory "pwsh/runner_scripts"

.EXAMPLE
Watch-ScriptDirectory -Directory "pwsh/runner_scripts" -IntervalSeconds 10
#>
function Watch-ScriptDirectory {
    CmdletBinding()
    param(
        Parameter(Mandatory=$true, Position=0)







        string$Directory,
        
        Parameter(Mandatory=$false)
        string$OutputDirectory = "tests",
        
        int$IntervalSeconds = 30
    )
    
    $ErrorActionPreference = "Stop"
    
    # Resolve paths
    $fullDir = Resolve-Path $Directory -ErrorAction Stop
    $fullOutputDir = Resolve-Path $OutputDirectory -ErrorAction SilentlyContinue
    
    if (-not $fullOutputDir) {
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        }
        $fullOutputDir = Resolve-Path $OutputDirectory
    }
    
    Write-Host "Starting script directory watch on $fullDir" -ForegroundColor Cyan
    Write-Host "Tests will be generated in $fullOutputDir" -ForegroundColor Cyan
    Write-Host "Checking every $IntervalSeconds seconds. Press Ctrl+C to stop." -ForegroundColor Cyan
    
    # Load the auto test generator
    $autoTestGeneratorPath = Join-Path $PSScriptRoot ".." ".." ".." "tests" "helpers" "New-AutoTestGenerator.ps1"
    if (-not (Test-Path $autoTestGeneratorPath)) {
        Write-Error "Auto test generator not found: $autoTestGeneratorPath"
        return
    }
    
    # Import helper function
    . $autoTestGeneratorPath
    
    # Track processed files
    $processedFiles = @{}
    
    # Start watch loop
    try {
        while ($true) {
            # Get all script files in directory
            $scriptFiles = Get-ChildItem -Path $fullDir -Filter "*.ps1" -Recurse  
                Where-Object { -not $_.Name.EndsWith('.Tests.ps1') }
            
            Write-Verbose "Found $($scriptFiles.Count) script files"
            
            foreach ($script in $scriptFiles) {
                $key = $script.FullName
                $lastWrite = $script.LastWriteTime
                
                # Check if file is new or modified
                if (-not $processedFiles.ContainsKey($key) -or $processedFiles$key -ne $lastWrite) {
                    Write-Host "Processing script: $($script.Name)" -ForegroundColor Yellow
                    
                    try {
                        # Standardize naming if needed
                        $scriptName = $script.Name
                        if ($script.Directory.FullName -like "*runner_scripts*" -and -not ($scriptName -match '^0-9{4}_')) {
                            # Get next available sequence number
                            $existingScripts = Get-ChildItem $script.Directory -Filter "*.ps1"  
                                Where-Object { $_.Name -match '^0-9{4}_' } 
                                ForEach-Object { int($_.Name.Substring(0,4)) } 
                                Sort-Object
                            
                            $nextNumber = if ($existingScripts.Count -gt 0) { $existingScripts-1 + 1    } else { 100    }
                            $newName = "{0:D4}_{1}" -f $nextNumber, $scriptName
                            $newPath = Join-Path $script.Directory $newName
                            
                            Write-Host "  Renaming script to follow convention: $scriptName -> $newName" -ForegroundColor Yellow
                            Move-Item $script.FullName $newPath
                            $script = Get-Item $newPath
                        }
                        
                        # Generate test if it doesn't exist
                        $testName = $script.Name -replace '\.ps1$', '.Tests.ps1'
                        $testPath = Join-Path $fullOutputDir $testName
                        
                        if (-not (Test-Path $testPath)) {
                            Write-Host "  Generating test file: $testName" -ForegroundColor Green
                            New-TestForScript -ScriptPath $script.FullName -OutputPath $testPath
                        }
                        
                        $processedFiles$key = $lastWrite
                        
                    } catch {
                        Write-Error "Failed to process script $($script.Name): $_"
                    }
                }
            }
            
            # Wait for next check
            Write-Verbose "Waiting $IntervalSeconds seconds before next check..."
            Start-Sleep -Seconds $IntervalSeconds
        }
    } catch {
        Write-Error "Error in watch loop: $_"
        Start-Sleep 5
    }
}



