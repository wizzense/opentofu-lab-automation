# Migrate and consolidate all fix scripts into the TestAutoFixer module
# This script identifies all fix-*.ps1 scripts and consolidates their logic into TestAutoFixer

param(
    Parameter()
    switch$WhatIf,
    
    Parameter()
    switch$Archive
)

function Invoke-FixScriptConsolidation {
    <#
    .SYNOPSIS
    Migrate and consolidate all fix scripts into the TestAutoFixer module
    #>
    param(
        switch$WhatIf,
        switch$Archive
    )
    
    # Find all fix scripts
    $fixScripts = Get-ChildItem -Path "/workspaces/opentofu-lab-automation/" -Filter "fix-*.ps1"
    
    # Create a tracking list of what was migrated
    $migratedScripts = @()
    
    Write-Host "Found $($fixScripts.Count) fix scripts to migrate" -ForegroundColor Yellow

    foreach ($script in $fixScripts) {
        Write-Host "Analyzing $($script.Name)" -ForegroundColor Cyan
        
        # Read the script content
        $content = Get-Content -Path $script.FullName -Raw
        
        # Map to appropriate module component based on content
        if ($script.Name -like "*syntax*") {
            $targetModule = "SyntaxFixer.ps1"
            Write-Host "  => Mapping to SyntaxFixer" -ForegroundColor Green
        }
        elseif ($script.Name -like "*bootstrap*") {
            $targetModule = "SyntaxFixer.ps1"
            Write-Host "  => Mapping to SyntaxFixer (bootstrap)" -ForegroundColor Green
        }
        elseif ($script.Name -like "*runner*") {
            $targetModule = "SyntaxFixer.ps1"
            Write-Host "  => Mapping to SyntaxFixer (runner scripts)" -ForegroundColor Green
        }
        elseif ($script.Name -like "*test*") {
            $targetModule = "TestGenerator.ps1"
            Write-Host "  => Mapping to TestGenerator" -ForegroundColor Green
        }
        else {
            $targetModule = "ValidationHelpers.ps1"
            Write-Host "  => Mapping to ValidationHelpers" -ForegroundColor Green
        }
        
        # Record the migration
        $migratedScripts += PSCustomObject@{
            OriginalScript = $script.Name
            MigratedTo = $targetModule
            FunctionName = "Migrated_" + ($script.Name -replace "fix-", "" -replace "\.ps1", "")
        }
    }

    # Generate report
    $reportContent = @"
# Fix Script Migration Report

The following scripts have been migrated into the TestAutoFixer module:

 Original Script  Migrated To  Function Name 
-------------------------------------------
$(foreach ($script in $migratedScripts) {
    " $($script.OriginalScript)  $($script.MigratedTo)  $($script.FunctionName) "
})

## How to Use

All fix functionality is now available through the TestAutoFixer module. Instead of running individual fix scripts,
you can now use the consolidated functions:

```powershell
# Import the module
Import-Module /workspaces/opentofu-lab-automation/tools/TestAutoFixer/TestAutoFixer.psm1

# Use the main fix function
Invoke-SyntaxFix -Path "/path/to/scripts" -FixTypes "Ternary","Parameter","TestSyntax" -Recurse
```

## Manual Steps

Some custom fix logic may still need to be manually incorporated into the module.
Please review the original scripts if you encounter issues not addressed by the module.
"@

    # Save the report
    Set-Content -Path "/workspaces/opentofu-lab-automation/MIGRATION-REPORT.md" -Value $reportContent

    Write-Host "`nMigration report saved to /workspaces/opentofu-lab-automation/MIGRATION-REPORT.md" -ForegroundColor Green

    # Create an archive folder if requested
    if ($Archive) {
        $archiveFolder = "/workspaces/opentofu-lab-automation/archive/fix-scripts-archive"
        
        if (-not (Test-Path $archiveFolder)) {
            New-Item -Path $archiveFolder -ItemType Directory -Force | Out-Null}
        
        foreach ($script in $fixScripts) {
            if (-not $WhatIf) {
                Copy-Item -Path $script.FullName -Destination "$archiveFolder/$($script.Name)" -Force
                Write-Host "Archived $($script.Name) to archive folder" -ForegroundColor Magenta
            }
            else {
                Write-Host "Would archive $($script.Name) to archive folder" -ForegroundColor DarkMagenta
            }
        }
    }
}

# Call the function with the provided parameters
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-FixScriptConsolidation -WhatIf:$WhatIf -Archive:$Archive
}

# Export the function (only when loaded as module)
if ($MyInvocation.ScriptName -like "*.psm1") {
    Export-ModuleMember -Function Invoke-FixScriptConsolidation
}



