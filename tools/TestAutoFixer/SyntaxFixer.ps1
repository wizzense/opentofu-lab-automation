# SyntaxFixer.ps1
# Centralized syntax fixing functionality for the TestAutoFixer module

function Invoke-SyntaxFix {
    <#
    .SYNOPSIS
    Automatically detects and fixes common syntax issues in PowerShell scripts

    .DESCRIPTION
    This is the main entry point for fixing syntax issues. It combines all specialized fixers
    and applies them based on detected issues.

    .PARAMETER Path
    Path to a file or directory to fix

    .PARAMETER FixTypes
    Types of fixes to apply: Ternary, Parameter, TestSyntax, Bootstrap, RunnerScript

    .PARAMETER WhatIf
    Run in WhatIf mode to see what would be changed without making actual changes

    .PARAMETER Recurse
    Process directories recursively when Path is a directory

    .EXAMPLE
    Invoke-SyntaxFix -Path "tests" -FixTypes "Ternary","TestSyntax" -Recurse
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0)



]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet("Ternary", "Parameter", "TestSyntax", "Bootstrap", "RunnerScript", "All")]
        [string[]]$FixTypes = @("All"),
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    $isAllFixes = $FixTypes -contains "All"
    $files = @()
    
    # Resolve files to process
    if (Test-Path -Path $Path -PathType Container) {
        $filter = "*.ps1"
        if ($Recurse) {
            $files = Get-ChildItem -Path $Path -Filter $filter -Recurse
        } else {
            $files = Get-ChildItem -Path $Path -Filter $filter
        }
    } else {
        if (Test-Path -Path $Path -PathType Leaf) {
            $files = Get-Item -Path $Path
        } else {
            Write-Error "Path not found: $Path"
            return
        }
    }
    
    $results = @{
        TotalFiles = $files.Count
        FilesFixed = 0
        FixesByType = @{
            Ternary = 0
            Parameter = 0
            TestSyntax = 0
            Bootstrap = 0
            RunnerScript = 0
        }
    }
    
    foreach ($file in $files) {
        $fileFixed = $false
        Write-Verbose "Processing $($file.FullName)"
        
        # Apply selected fixes
        if ($isAllFixes -or $FixTypes -contains "Ternary") {
            $ternaryfixed = Fix-TernarySyntax -Path $file.FullName -WhatIf:$WhatIf
            if ($ternaryfixed) {
                $fileFixed = $true
                $results.FixesByType.Ternary++
            }
        }
        
        if ($isAllFixes -or $FixTypes -contains "Parameter") {
            $paramFixed = Fix-ParamSyntax -Path $file.FullName -WhatIf:$WhatIf
            if ($paramFixed) {
                $fileFixed = $true
                $results.FixesByType.Parameter++
            }
        }
        
        if ($isAllFixes -or $FixTypes -contains "TestSyntax") {
            if ($file.FullName -like "*Tests.ps1") {
                $testSyntaxFixed = Fix-TestSyntax -Path $file.FullName -WhatIf:$WhatIf
                if ($testSyntaxFixed) {
                    $fileFixed = $true
                    $results.FixesByType.TestSyntax++
                }
            }
        }
        
        if ($isAllFixes -or $FixTypes -contains "Bootstrap") {
            if ($file.Name -eq "kicker-bootstrap.ps1") {
                $bootstrapFixed = Fix-BootstrapScript -Path $file.FullName -WhatIf:$WhatIf
                if ($bootstrapFixed) {
                    $fileFixed = $true
                    $results.FixesByType.Bootstrap++
                }
            }
        }
        
        if ($isAllFixes -or $FixTypes -contains "RunnerScript") {
            if ($file.FullName -like "*runner*.ps1" -or $file.Directory -like "*runner_scripts*") {
                $runnerFixed = Fix-RunnerScriptIssues -Path $file.FullName -WhatIf:$WhatIf
                if ($runnerFixed) {
                    $fileFixed = $true
                    $results.FixesByType.RunnerScript++
                }
            }
        }
        
        if ($fileFixed) {
            $results.FilesFixed++
        }
    }
    
    if ($PassThru) {
        return $results
    }
}

function Fix-TernarySyntax {
    <#
    .SYNOPSIS
    Fixes ternary operator and conditional syntax issues in PowerShell scripts
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }
    
    $content = Get-Content -Path $Path -Raw
    $originalContent = $content
    
    # Fix 1: Convert broken "if" ternary patterns
    $pattern1 = '\(if \(\$([^)]+)\) \{ ([^}]+) \} else \{ ([^}]+) \}\)'
    $replacement1 = '$$(if (1) { $2 } else { $3 })'
    $content = $content -replace $pattern1, $replacement1
    
    # Fix 2: Handle incorrect ternary operator patterns
    $pattern2 = '\(\$([^?]+)\s*\?\s*([^:]+)\s*:\s*([^)]+)\)'
    $replacement2 = '$$(if (1) { $2 } else { $3 })'
    $content = $content -replace $pattern2, $replacement2
    
    # Fix 3: Properly form if statements
    $pattern3 = 'if\s+([^\(\s][^{]*)\s*\{'
    $replacement3 = 'if ($1) {'
    $content = $content -replace $pattern3, $replacement3
    
    # Fix 4: Properly form if..else blocks
    $pattern4 = '\}\s*else\s*if\s+([^\(].*?)\s*\{'
    $replacement4 = '} elseif ($1) {'
    $content = $content -replace $pattern4, $replacement4
    
    # Apply changes if needed
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Fix ternary syntax issues")) {
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Fixed ternary syntax in $Path"
            return $true
        }
    }
    
    return $false
}

function Fix-TestSyntax {
    <#
    .SYNOPSIS
    Fixes common syntax issues in Pester test files
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }
    
    $content = Get-Content -Path $Path -Raw
    $originalContent = $content
    
    # Fix 1: Fix broken ternary-style "if" expressions
    $pattern1 = '\(if \(\$([^)]+)\) \{ ([^}]+) \} else \{ ([^}]+) \}\)'
    $replacement1 = '$$(if (1) { $2 } else { $3 })'
    $content = $content -replace $pattern1, $replacement1
    
    # Fix 2: Fix -Skip parameter without parentheses
    $pattern2 = '-Skip:\$([a-zA-Z0-9_]+)(?!\))'
    $replacement2 = '-Skip:($$$1)'
    $content = $content -replace $pattern2, $replacement2
    
    # Fix 3: Fix incorrect indentation for It blocks
    $pattern3 = '(\s+)}(\r?\n)\s+It '
    $replacement3 = '$1}$2        It '
    $content = $content -replace $pattern3, $replacement3
    
    # Fix 4: Fix missing closing braces in It blocks
    # Simplified pattern to avoid quote escaping issues
    $pattern4 = '([ \t]+)It (.+)\{(?!\s*\n\s+)'
    $replacement4 = '$1It $2{' + [Environment]::NewLine + '$1    '
    $content = $content -replace $pattern4, $replacement4
    
    # Apply changes if needed
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Fix test syntax issues")) {
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Fixed test syntax in $Path"
            return $true
        }
    }
    
    return $false
}

function Fix-ParamSyntax {
    <#
    .SYNOPSIS
    Fixes parameter declaration and usage issues in PowerShell scripts
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }
    
    $content = Get-Content -Path $Path -Raw
    $originalContent = $content
    
    # Fix 1: Fix Parameter attribute syntax
    $pattern1 = '\[Parameter\((Mandatory)=\$true\)\]'
    $replacement1 = '[Parameter($1=$true)]'
    $content = $content -replace $pattern1, $replacement1
    
    $pattern2 = '\[Parameter\((Mandatory)=\$false\)\]'
    $replacement2 = '[Parameter($1=$false)]'
    $content = $content -replace $pattern2, $replacement2
    
    # Fix 2: Ensure proper spacing in parameter declarations
    $pattern3 = 'param\s*\(\s*\[Parameter\('
    $replacement3 = 'param([Parameter('
    $content = $content -replace $pattern3, $replacement3
    
    # Fix 3: Fix incorrect Import-Module / Param order
    if ($content -match '^Import-Module.*LabRunner.*-Force' -and $content -match '^Param\(' -and $content -match '{##This}#Replace Import-Module/Param##') 



{
        $importLine = [regex]::Match($content, '^Import-Module.*LabRunner.*-Force.*?\r?\n').Value
        $paramBlock = [regex]::Match($content, '^Param\(.*?\).*?\r?\n', [System.Text.RegularExpressions.RegexOptions]::Singleline).Value
        
        # Generate replacement with Param before Import
        $replacement = $paramBlock + $importLine
        $content = $content -replace "(?ms)^Import-Module.*LabRunner.*-Force.*?\r?\n.*?^Param\(.*?\).*?\r?\n", $replacement
    }
    
    # Apply changes if needed
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Fix parameter syntax issues")) {
            # Remove any placeholder content
            $content = $content -replace '{##.*?##}', ''
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Fixed parameter syntax in $Path"
            return $true
        }
    }
    
    return $false
}

function Test-SyntaxValidity {
    <#
    .SYNOPSIS
    Tests if a PowerShell script has valid syntax
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }
    
    try {
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors)
        
        if ($errors -and $errors.Count -gt 0) {
            return $false
        }
        
        return $true
    }
    catch {
        Write-Error "Error checking syntax: $_"
        return $false
    }
}

function Fix-BootstrapScript {
    <#
    .SYNOPSIS
    Fixes specific issues in the bootstrap script
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    # Implementation of bootstrap script fixes
    # Adapted from fix-bootstrap-script.ps1
    # This is a specialized fixer for the kicker-bootstrap.ps1 file
    
    if (-not (Test-Path $Path)) {
        Write-Error "Bootstrap script not found: $Path"
        return $false
    }
    
    $content = Get-Content $Path -Raw
    $originalContent = $content
    
    # Fix 1: Remove duplicate prompt definition and standardize prompting
    $oldPromptSection = @'
$prompt = "`n<press any key to continue>`n"


function Write-Continue($prompt) {
  [Console]::Write($prompt + '  ')
  Read-LoggedInput -Prompt $prompt | Out-Null
}
'@

    $newPromptSection = @'
function Write-Continue {
    param([string]$Message = "Press any key to continue...")
    



Write-Host $Message -ForegroundColor Yellow -NoNewline
    $null = Read-Host
}
'@

    $content = $content -replace [regex]::Escape($oldPromptSection), $newPromptSection
    
    # Fix 2: Fix variable escaping in string expressions
    $content = $content -replace '\$repoPath:', '${repoPath}:'
    
    # Fix 3: Improve error handling
    $oldErrorSection = 'throw "Failed to locate the runner script"'
    $newErrorSection = @'
$errorMsg = "Failed to locate the runner script at $runnerScriptPath"
Write-Error $errorMsg
throw $errorMsg
'@
    $content = $content -replace [regex]::Escape($oldErrorSection), $newErrorSection
    
    # Apply changes if needed
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Fix bootstrap script issues")) {
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Fixed bootstrap script issues in $Path"
            return $true
        }
    }
    
    return $false
}

function Fix-RunnerScriptIssues {
    <#
    .SYNOPSIS
    Fixes common issues in runner scripts
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)



]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "File not found: $Path"
        return $false
    }
    
    $content = Get-Content -Path $Path -Raw
    $originalContent = $content
    
    # Fix parameter issues
    if (($Path -match "runner\.ps1" -or $Path -match "runner_scripts") -and 
        $content -match "Import-Module.*LabRunner") {
        
        # Fix import-module/param order
        if ($content -match "^Import-Module.*LabRunner.*-Force" -and 
            $content -match "^Param\(" -and 
            [regex]::Matches($content, "^Import-Module").Count -eq 1 -and 
            [regex]::Match($content, "^Import-Module.*\r?\n.*^Param\(").Success) {
            
            $importLine = [regex]::Match($content, "^Import-Module.*LabRunner.*-Force.*?\r?\n").Value
            $paramBlock = [regex]::Match($content, "^Param\(.*?\).*?\r?\n", [System.Text.RegularExpressions.RegexOptions]::Singleline).Value
            
            # Generate replacement with Param before Import
            $replacement = $paramBlock + $importLine
            $content = $content -replace "(?ms)^Import-Module.*LabRunner.*-Force.*?\r?\n.*?^Param\(.*?\).*?\r?\n", $replacement
        }
    }
    
    # Apply changes if needed
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($Path, "Fix runner script issues")) {
            Set-Content -Path $Path -Value $content -NoNewline
            Write-Verbose "Fixed runner script issues in $Path"
            return $true
        }
    }
    
    return $false
}


