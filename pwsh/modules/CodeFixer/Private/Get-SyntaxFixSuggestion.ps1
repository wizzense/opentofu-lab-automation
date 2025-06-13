<#
.SYNOPSIS
Provides fix suggestions for common PowerShell syntax errors

.DESCRIPTION
This helper function analyzes PowerShell parse errors and provides
actionable fix suggestions for common syntax issues.

.PARAMETER Error
The parse error object from PowerShell AST parser

.EXAMPLE
Get-SyntaxFixSuggestion -Error $parseError
#>
function Get-SyntaxFixSuggestion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)






]
        [System.Management.Automation.Language.ParseError]$Error
    )
    
    $message = $error.Message.ToLower()
    
    switch -Regex ($message) {
        "missing closing.*quote" {
            return "Add missing closing quote character (') or (`")"
        }
        "missing closing.*brace" {
            return "Add missing closing brace (})"
        }
        "missing closing.*bracket" {
            return "Add missing closing bracket (])"
        }
        "missing closing.*parenthesis" {
            return "Add missing closing parenthesis ())"
        }
        "unexpected.*token" {
            return "Check for syntax errors near line $($Error.Extent.StartLineNumber)"
        }
        "missing.*comma" {
            return "Add missing comma (,) between parameters or array elements"
        }
        "the term.*is not recognized" {
            return "Check spelling or ensure cmdlet/function is available"
        }
        "cannot convert.*to.*type" {
            return "Check data type compatibility and casting"
        }
        default {
            return "Review syntax around line $($Error.Extent.StartLineNumber)"
        }
    }
}



