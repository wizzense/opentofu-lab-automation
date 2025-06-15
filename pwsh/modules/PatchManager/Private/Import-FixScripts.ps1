function Import-FixScripts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SourcePath = (Join-Path $script:ProjectRoot "archive/fix-scripts"),
        
        [Parameter(Mandatory = $false)]
        [string]$TargetPath = $PSScriptRoot,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if (-not (Test-Path $SourcePath)) {
        Write-PatchLog "Source path not found: $SourcePath" "ERROR" -LogFile $LogFile
        return $false
    }
    
    # Create directories if they don't exist
    $fixScriptsPrivatePath = Join-Path $TargetPath "FixScripts"
    if (-not (Test-Path $fixScriptsPrivatePath)) {
        New-Item -Path $fixScriptsPrivatePath -ItemType Directory -Force | Out-Null
        Write-PatchLog "Created directory: $fixScriptsPrivatePath" "INFO" -LogFile $LogFile
    }
    
    # Get all scripts from source
    $fixScripts = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse
    
    # Process each script
    $importedCount = 0
    foreach ($script in $fixScripts) {
        $scriptContent = Get-Content -Path $script.FullName -Raw
        
        # Convert script to function
        $functionName = "Fix-" + ($script.BaseName -replace "fix-|fix_", "" -replace "-|_", "")
        $functionContent = @"
function $functionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$false)]
        [string]`$ProjectRoot = `$script:ProjectRoot,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$WhatIf,
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFile
    )

    Write-PatchLog "Running $functionName from converted legacy script" "INFO" -LogFile `$LogFile
    
    # Original script content from $($script.Name)
$scriptContent
}
"@
        
        # Save as function file
        $targetFilePath = Join-Path $fixScriptsPrivatePath "$functionName.ps1"
        Set-Content -Path $targetFilePath -Value $functionContent -Force
        
        Write-PatchLog "Imported script $($script.Name) as function $functionName" "SUCCESS" -LogFile $LogFile
        $importedCount++
    }
    
    Write-PatchLog "Imported $importedCount fix scripts as functions" "SUCCESS" -LogFile $LogFile
    return $true
}
