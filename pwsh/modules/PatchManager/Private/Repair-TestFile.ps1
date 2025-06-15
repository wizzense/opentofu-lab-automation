function Repair-TestFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("ParamError", "DotSourcing", "ExecutionPattern", "ModuleScope", "All")]
        [string]$FixType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-PatchLog "Test file not found: $FilePath" "ERROR" -LogFile $LogFile
        return $false
    }
    
    Write-PatchLog "Processing test file: $FilePath" "INFO" -LogFile $LogFile
    
    # Read the file content
    $content = Get-Content $FilePath -Raw
    $modified = $false
    
    # Apply different fixes based on the fix type
    if ($FixType -eq "All" -or $FixType -eq "ParamError") {
        # Fix Param is not recognized error
        $oldPattern = '{ & \$script:ScriptPath -Config \$config }'
        $newPattern = @'
$config = [pscustomobject]@{}
            $configJson = $config | ConvertTo-Json -Depth 5
            $tempConfig = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.Guid]::NewGuid()).json"
            $configJson | Set-Content -Path $tempConfig
            try {
                $pwsh = (Get-Command pwsh).Source
                { & $pwsh -NoLogo -NoProfile -File $script:ScriptPath -Config $tempConfig } | Should -Not -Throw
            } finally {
                Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
            }
'@
        
        if ($content -match $oldPattern) {
            $content = $content -replace $oldPattern, $newPattern
            $modified = $true
            Write-PatchLog "Fixed Param error execution pattern" "SUCCESS" -LogFile $LogFile
        }
    }
    
    if ($FixType -eq "All" -or $FixType -eq "DotSourcing") {
        # Fix dot-sourcing pattern
        $oldPattern = '\{ \. \$script:ScriptPath \} \| Should -Not -Throw'
        $newPattern = @'
$errors = $null
                [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$null, [ref]$errors) | Out-Null
                ($errors ? $errors.Count : 0) | Should -Be 0
'@
        
        if ($content -match $oldPattern) {
            $content = $content -replace $oldPattern, $newPattern
            $modified = $true
            Write-PatchLog "Fixed dot-sourcing pattern" "SUCCESS" -LogFile $LogFile
        }
    }
    
    if ($FixType -eq "All" -or $FixType -eq "ModuleScope") {
        # Fix InModuleScope wrappers
        if ($content -match 'InModuleScope (LabRunner|CodeFixer) \{' -and $content -match '\} # End InModuleScope') {
            $content = $content -replace 'InModuleScope (LabRunner|CodeFixer) \{\s*\n', ''
            $content = $content -replace '\s*\} # End InModuleScope', ''
            $modified = $true
            Write-PatchLog "Removed InModuleScope wrapper" "SUCCESS" -LogFile $LogFile
        }
    }
    
    if ($FixType -eq "All" -or $FixType -eq "ExecutionPattern") {
        # Fix script path construction
        $testFileName = [System.IO.Path]::GetFileName($FilePath)
        $scriptName = $testFileName -replace '\.Tests\.ps1$', '.ps1'
        $oldPathPattern = '\$scriptPath = Join-Path \$PSScriptRoot ''\.\.'' ''/[^'']+'''
        $newPathPattern = @"
# Get the script path using the LabRunner function  
        `$script:ScriptPath = Get-RunnerScriptPath '$scriptName'
        if (-not `$script:ScriptPath -or -not (Test-Path `$script:ScriptPath)) {
            throw "Script under test not found: $scriptName (resolved path: `$script:ScriptPath)"
        }
"@
        
        if ($content -match $oldPathPattern) {
            $content = $content -replace $oldPathPattern, $newPathPattern
            # Update scriptPath references
            $content = $content -replace '\$scriptPath(?!\w)', '$script:ScriptPath'
            $modified = $true
            Write-PatchLog "Fixed script path construction" "SUCCESS" -LogFile $LogFile
        }
    }
    
    # Save changes if any were made
    if ($modified) {
        if ($WhatIf) {
            Write-PatchLog "WhatIf: Would update test file $FilePath" "INFO" -LogFile $LogFile
        } else {
            Set-Content -Path $FilePath -Value $content
            Write-PatchLog "Updated test file $FilePath" "SUCCESS" -LogFile $LogFile
        }
        return $true
    } else {
        Write-PatchLog "No changes needed for $FilePath" "INFO" -LogFile $LogFile
        return $false
    }
}
