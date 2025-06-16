function Test-AutomaticVariables {
    <#
    .SYNOPSIS
    Detects assignments to PowerShell automatic variables
    
    .DESCRIPTION
    Identifies and reports when code attempts to assign values to PowerShell automatic variables
    like $error, $_, $PSItem, etc. which should not be modified directly.
    
    .PARAMETER ScriptPath
    Path to the PowerShell script to analyze
    
    .PARAMETER Content
    Script content as string to analyze
    
    .EXAMPLE
    Test-AutomaticVariables -ScriptPath "script.ps1"
    #>
    CmdletBinding()
    param(
        Parameter(Mandatory = $true, ParameterSetName = 'Path')
        string$ScriptPath,
        
        Parameter(Mandatory = $true, ParameterSetName = 'Content')
        string$Content
    )
    
    # PowerShell automatic variables that should not be assigned to
    $automaticVariables = @(
        'error', '_', 'PSItem', 'args', 'consolefilename', 'event', 'eventargs',
        'eventsubscriber', 'executioncontext', 'false', 'foreach', 'home', 'host',
        'input', 'lastexitcode', 'matches', 'myinvocation', 'nestedpromptlevel',
        'null', 'pid', 'profile', 'psboundparameters', 'pscmdlet', 'pscommandpath',
        'psculture', 'psdebugcontext', 'pshome', 'psitem', 'psscriptroot',
        'psuiculture', 'psversiontable', 'sender', 'shellid', 'stacktrace',
        'switch', 'this', 'true'
    )
    
    try {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            if (-not (Test-Path $ScriptPath)) {
                throw "Script file not found: $ScriptPath"
            }
            $Content = Get-Content -Path $ScriptPath -Raw
        }
        
        # Parse the script content
        $tokens = $null
        $parseErrors = $null
        $ast = System.Management.Automation.Language.Parser::ParseInput(
            $Content, ref$tokens, ref$parseErrors
        )
        
        $issues = System.Collections.ArrayList::new()
        
        # Find assignment expressions
        $assignments = $ast.FindAll({
            param($node)
            $node -is System.Management.Automation.Language.AssignmentStatementAst
        }, $true)
        
        foreach ($assignment in $assignments) {
            $leftSide = $assignment.Left
            
            # Check if assigning to a variable
            if ($leftSide -is System.Management.Automation.Language.VariableExpressionAst) {
                $varName = $leftSide.VariablePath.UserPath.ToLower()
                
                if ($varName -in $automaticVariables) {
                    $issue = PSCustomObject@{
                        RuleName = 'AutomaticVariableAssignment'
                        Severity = 'Error'
                        ScriptName = if ($ScriptPath) { Split-Path $ScriptPath -Leaf } else { '<Content>' }
                        Line = $assignment.Extent.StartLineNumber
                        Column = $assignment.Extent.StartColumnNumber
                        Message = "Assignment to automatic variable '\$$varName' is not allowed"
                        Extent = $assignment.Extent
                        SuggestedCorrection = "Use a different variable name, e.g. '\$my$($varName)' or '\$result$($varName)'"
                    }
                    void$issues.Add($issue)
                }
            }
        }
        
        return $issues
        
    } catch {
        Write-Error "Failed to analyze script for automatic variables: $($_.Exception.Message)"
        return @()
    }
}
