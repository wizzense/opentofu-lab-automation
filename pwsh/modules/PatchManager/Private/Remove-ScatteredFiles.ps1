function Remove-ScatteredFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ProjectRoot = $script:ProjectRoot,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile    )
    
    # Check if Write-PatchLog function is available, if not define a minimal version
    if (-not (Get-Command Write-PatchLog -ErrorAction SilentlyContinue)) {
        function Write-PatchLog {
            param($Message, $Level = "INFO", $LogFile)
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $formattedMessage = "[$timestamp] [$Level] $Message"
            Write-Host $formattedMessage -ForegroundColor $(switch($Level) {
                "ERROR" { "Red" }
                "WARNING" { "Yellow" }
                "SUCCESS" { "Green" }
                default { "White" }
            })
            if ($LogFile) {
                $formattedMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
            }
        }
    }
    
    Write-PatchLog "Starting cleanup of scattered files in $ProjectRoot" "INFO" -LogFile $LogFile
    
    # Get all fix scripts in the root directory
    $rootFixScripts = Get-ChildItem -Path $ProjectRoot -Filter "fix-*.ps1" -File
    $rootFixScripts += Get-ChildItem -Path $ProjectRoot -Filter "*fix*.ps1" -File
    $rootFixScripts += Get-ChildItem -Path (Join-Path $ProjectRoot "scripts") -Filter "fix-*.ps1" -File -Recurse
    
    # Filter out scripts from scripts/maintenance and scripts/validation
    $rootFixScripts = $rootFixScripts | Where-Object {
        -not ($_.FullName -like "*/scripts/maintenance/*" -or 
              $_.FullName -like "*/scripts/validation/*")
    }
    
    # Create archive directory if it doesn't exist
    $archiveDir = Join-Path $ProjectRoot "archive/fix-scripts"
    if (-not (Test-Path $archiveDir)) {
        if (-not $WhatIf) {
            New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
        }
        Write-PatchLog "Created archive directory: $archiveDir" "INFO" -LogFile $LogFile
    }
    
    # Archive each fix script
    $archivedCount = 0
    foreach ($script in $rootFixScripts) {
        $archiveTarget = Join-Path $archiveDir $script.Name
        
        # Check if archive already has this file
        if (Test-Path $archiveTarget) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $archiveTarget = Join-Path $archiveDir "$($script.BaseName)-$timestamp$($script.Extension)"
        }

        try {
            # Copy the file to archive
            Copy-Item -Path $script.FullName -Destination $archiveTarget -Force

            # Only delete the original if Force is specified
            if ($Force) {
                Remove-Item -Path $script.FullName -Force
                Write-PatchLog "Archived and removed: $($script.FullName) -> $archiveTarget" "SUCCESS" -LogFile $LogFile
            } else {
                Write-PatchLog "Archived (kept original): $($script.FullName) -> $archiveTarget" "INFO" -LogFile $LogFile
            }

            $archivedCount++
        } catch {
            Write-PatchLog "Failed to archive $($script.Name): $($_.Exception.Message)" "ERROR" -LogFile $LogFile
        }

        Write-PatchLog "Processed $archivedCount scattered fix scripts" "SUCCESS" -LogFile $LogFile

        # Migrate fix script functionality into PatchManager module
        if (-not $WhatIf) {
            try {
                # Basic test fixes
                $testFixPath = Join-Path $ProjectRoot "apply-basic-fixes.ps1"
                if (Test-Path $testFixPath) {
                    Write-PatchLog "Migrating test fix functionality from $testFixPath to module" "INFO" -LogFile $LogFile
                    Import-TestFixFunctions -Path $testFixPath -LogFile $LogFile
                }

                # Infrastructure fixes
                $infraFixPath = Join-Path $ProjectRoot "scripts" "maintenance" "fix-infrastructure-issues.ps1"
                if (Test-Path $infraFixPath) {
                    Write-PatchLog "Migrating infrastructure fix functionality from $infraFixPath to module" "INFO" -LogFile $LogFile
                    Import-InfrastructureFixFunctions -Path $infraFixPath -LogFile $LogFile
                }
            } catch {
                Write-PatchLog "Failed to migrate fix scripts: $($_.Exception.Message)" "ERROR" -LogFile $LogFile
            }
        }
    }
    
    # Return results
    $result = @{
        ArchivedCount = $archivedCount
        ArchiveDirectory = $archiveDir
        ProcessedFiles = $rootFixScripts | Select-Object FullName
    }
    
    Write-PatchLog "Cleanup complete: Archived $archivedCount scattered fix files" "SUCCESS" -LogFile $LogFile
    return $result
}

function Import-TestFixFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    if (-not (Test-Path $Path)) {
        Write-PatchLog "Path not found: $Path" "ERROR" -LogFile $LogFile
        return
    }
    
    try {
        # Import the content
        $content = Get-Content -Path $Path -Raw
        
        # Extract pattern fixes
        if ($content -match '#\s*Pattern\s+1\s*:.*?(?<pattern1>[-replace].*?)(?=#\s*Pattern|\z)' -and 
            $content -match '#\s*Pattern\s+2\s*:.*?(?<pattern2>[-replace].*?)(?=#\s*Pattern|\z)' -and
            $content -match '#\s*Pattern\s+3\s*:.*?(?<pattern3>[-replace].*?)(?=#\s*Pattern|\z)') {
            
            # Create or update Repair-TestFile.ps1 
            $repairTestPath = Join-Path (Split-Path $PSScriptRoot) "Private" "Repair-TestFile.ps1"
            
            $repairTestContent = @"
# This file was migrated from standalone fix scripts
function Repair-TestFile {
    [CmdletBinding()
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$Force,
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFile
    )
    
    if (-not (Test-Path `$FilePath)) {
        Write-PatchLog "File not found: `$FilePath" "ERROR" -LogFile `$LogFile
        return `$false
    }
    
    Write-PatchLog "Repairing test file: `$FilePath" "INFO" -LogFile `$LogFile
    
    try {
        `$content = Get-Content -Path `$FilePath -Raw
        `$originalContent = `$content
        
        # Pattern 1: Fix empty pipe elements
        `$content = `$content -replace '\s*\|\s*Should\s+-Not\s+-Throw\s*\n\s*\}\s*\n\s*_', '{ Test-Path `$script:ScriptPath } | Should -Not -Throw' + "`n        }`n        `n        It ''should follow naming conventions'' {`n            `$script:ScriptPath | Should -Match ''^.*[0-9]{4}_"
        
        # Pattern 2: Fix broken regex patterns
        `$content = `$content -replace '_\[A-Z\]\[a-zA-Z0-9-\]\+\\\.ps1\`$\|\^\[A-Z\]\[a-zA-Z0-9-\]\+\\\.ps1\`$', '[A-Z][a-zA-Z0-9-]+\.ps1`$|^[A-Z][a-zA-Z0-9-]+\.ps1`$'''
        
        # Pattern 3: Fix unterminated Context strings
        `$content = `$content -replace "Context\s+'([^']+)'\s*\{\s*~~~", "Context '`$1' {"
          # Check if anything changed
        $changed = $content -ne $originalContent
        
        if ($changed -or $Force) {
            Set-Content -Path `$FilePath -Value `$content -Encoding UTF8
            Write-PatchLog "✓ Applied fixes to: `$FilePath" "SUCCESS" -LogFile `$LogFile
            return `$true
        }
        else {
            Write-PatchLog "No changes needed for: `$FilePath" "INFO" -LogFile `$LogFile
            return `$false
        }
    }
    catch {
        Write-PatchLog "Error repairing `$FilePath: `$(`$_.Exception.Message)" "ERROR" -LogFile `$LogFile
        return `$false
    }
}
"@
            
            Set-Content -Path $repairTestPath -Value $repairTestContent -Force
            Write-PatchLog "Created/updated $repairTestPath with migrated fix functionality" "SUCCESS" -LogFile $LogFile
            
            # Also create a Public function to expose this functionality
            $invokeTestFixPath = Join-Path (Split-Path $PSScriptRoot) "Public" "Invoke-TestFileFix.ps1"
            
            $invokeTestFixContent = @"
function Invoke-TestFileFix {
    [CmdletBinding()
    param(
        [Parameter(Mandatory = `$false)]
        [string[]]`$TestFiles,
        
        [Parameter(Mandatory = `$false)]
        [string]`$TestDirectory = "tests",
        
        [Parameter(Mandatory = `$false)]
        [string]`$ProjectRoot = `$script:ProjectRoot,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$Force,
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFile
    )
    
    `$testsPath = Join-Path `$ProjectRoot `$TestDirectory
    
    if (-not (Test-Path `$testsPath)) {
        Write-PatchLog "Test directory not found: `$testsPath" "ERROR" -LogFile `$LogFile
        return `$null
    }
    
    Write-PatchLog "Running test file fixes in `$testsPath" "INFO" -LogFile `$LogFile
    
    `$results = @{
        ProcessedFiles = 0
        FixedFiles = 0
        FailedFiles = 0
        Details = @()
    }
    
    # Get files to process
    if (`$TestFiles -and `$TestFiles.Count -gt 0) {
        `$filesToProcess = @()
        foreach (`$file in `$TestFiles) {
            `$filePath = Join-Path `$testsPath `$file
            if (Test-Path `$filePath) {
                `$filesToProcess += Get-Item -Path `$filePath
            }
            else {
                Write-PatchLog "Test file not found: `$filePath" "WARNING" -LogFile `$LogFile
            }
        }
    }
    else {
        `$filesToProcess = Get-ChildItem -Path `$testsPath -Filter "*.Tests.ps1" -Recurse
    }
    
    # Process each file
    foreach (`$file in `$filesToProcess) {
        `$results.ProcessedFiles++
        
        try {
            `$fixed = Repair-TestFile -FilePath `$file.FullName -Force:`$Force -LogFile `$LogFile
            
            if (`$fixed) {
                `$results.FixedFiles++
                `$results.Details += @{
                    File = `$file.Name
                    Status = "Fixed"
                    Path = `$file.FullName
                }
            }
            else {
                `$results.Details += @{
                    File = `$file.Name
                    Status = "Unchanged"
                    Path = `$file.FullName
                }
            }
        }
        catch {
            `$results.FailedFiles++
            `$results.Details += @{
                File = `$file.Name
                Status = "Failed"
                Error = `$_.Exception.Message
                Path = `$file.FullName
            }
            Write-PatchLog "Failed to fix `$(`$file.Name): `$(`$_.Exception.Message)" "ERROR" -LogFile `$LogFile
        }
    }
    
    Write-PatchLog "Test fix summary: Processed `$(`$results.ProcessedFiles) files, Fixed `$(`$results.FixedFiles), Failed `$(`$results.FailedFiles)" "INFO" -LogFile `$LogFile
    
    return `$results
}
"@
            
            Set-Content -Path $invokeTestFixPath -Value $invokeTestFixContent -Force
            Write-PatchLog "Created/updated $invokeTestFixPath with public interface" "SUCCESS" -LogFile $LogFile
            
            return $true
        }
        else {
            Write-PatchLog "Failed to extract patterns from $Path" "ERROR" -LogFile $LogFile
            return $false
        }
    }
    catch {
        Write-PatchLog "Error importing test fix functions: $($_.Exception.Message)" "ERROR" -LogFile $LogFile
        return $false
    }
}

function Import-InfraFixFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    if (-not (Test-Path $Path)) {
        Write-PatchLog "Infrastructure fix path not found: $Path" "ERROR" -LogFile $LogFile
        return $false
    }
    
    try {
        # Check if Invoke-InfrastructureFix.ps1 already exists
        $targetPath = Join-Path (Split-Path $PSScriptRoot) "Public" "Invoke-InfrastructureFix.ps1"
        
        if (-not (Test-Path $targetPath)) {
            Write-PatchLog "Invoke-InfrastructureFix.ps1 not found, creating from $Path" "WARNING" -LogFile $LogFile
            Copy-Item -Path $Path -Destination $targetPath -Force
            
            # Convert script to function
            $content = Get-Content -Path $targetPath -Raw
            $content = $content -replace '^\s*param\s*\(', 'function Invoke-InfrastructureFix {
    [CmdletBinding()
    param('
            $content = $content + "`n}"
            
            Set-Content -Path $targetPath -Value $content -Force
            Write-PatchLog "Created Invoke-InfrastructureFix.ps1 from $Path" "SUCCESS" -LogFile $LogFile
        }
        else {
            Write-PatchLog "Invoke-InfrastructureFix.ps1 already exists, not overwriting" "INFO" -LogFile $LogFile
        }
        
        return $true
    }
    catch {
        Write-PatchLog "Error importing infrastructure fix functions: $($_.Exception.Message)" "ERROR" -LogFile $LogFile
        return $false
    }
}
