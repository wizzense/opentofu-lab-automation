function Repair-AutomaticVariables {
    <#
    .SYNOPSIS
    Automatically fixes assignments to PowerShell automatic variables
    
    .DESCRIPTION
    Replaces assignments to automatic variables with safer alternatives
    
    .PARAMETER ScriptPath
    Path to the PowerShell script to fix
    
    .PARAMETER WhatIf
    Show what would be changed without making changes
    
    .EXAMPLE
    Repair-AutomaticVariables -ScriptPath "script.ps1"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [switch]$WhatIf
    )
    
    if (-not (Test-Path $ScriptPath)) {
        throw "Script file not found: $ScriptPath"
    }
      $content = Get-Content -Path $ScriptPath -Raw
    $changesMade = 0
    
    # Get automatic variable issues
    $issues = Test-AutomaticVariables -ScriptPath $ScriptPath
    
    if ($issues.Count -eq 0) {
        Write-Host "No automatic variable assignments found in $ScriptPath" -ForegroundColor Green
        return @{
            ChangesMade = 0
            FilePath = $ScriptPath
            Success = $true
        }
    }
    
    # Sort issues by line number (descending) to avoid offset issues when replacing
    $issues = $issues | Sort-Object Line -Descending
    
    foreach ($issue in $issues) {
        $extent = $issue.Extent
        $originalText = $extent.Text
        
        # Extract variable name and create safe replacement
        if ($originalText -match '\$(\w+)\s*=') {
            $varName = $matches[1].ToLower()
            $safeVarName = switch ($varName) {
                'error' { 'errorResult' }
                '_' { 'currentItem' }
                'psitem' { 'currentItem' }
                default { "my$varName" }
            }
            
            $newText = $originalText -replace "\`$$varName", "`$$safeVarName"
            
            if ($WhatIf) {
                Write-Host "Would change line $($issue.Line): '$originalText' -> '$newText'" -ForegroundColor Yellow
            } else {
                # Replace the content
                $beforeExtent = $content.Substring(0, $extent.StartOffset)
                $afterExtent = $content.Substring($extent.EndOffset)
                $content = $beforeExtent + $newText + $afterExtent
                
                Write-Host "Fixed line $($issue.Line): '$originalText' -> '$newText'" -ForegroundColor Green
                $changesMade++
            }
        }
    }
    
    # Write the fixed content back to file
    if ($changesMade -gt 0 -and -not $WhatIf) {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Fix automatic variable assignments")) {
            Set-Content -Path $ScriptPath -Value $content -Encoding UTF8
            Write-Host "Successfully fixed $changesMade automatic variable assignments in $ScriptPath" -ForegroundColor Green
        }
    }
    
    return @{
        ChangesMade = $changesMade
        FilePath = $ScriptPath
        Success = $true
        Issues = $issues
    }
}
