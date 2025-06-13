<#
.SYNOPSIS
Provides fix suggestions for common JSON syntax errors

.DESCRIPTION
This helper function analyzes JSON parsing errors and provides
actionable fix suggestions for common JSON syntax issues.

.PARAMETER ErrorMessage
The error message from JSON parsing

.EXAMPLE
Get-JsonFixSuggestion -ErrorMessage "Expected comma"
#>
function Get-JsonFixSuggestion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)



]
        [string]$ErrorMessage
    )
    
    $message = $ErrorMessage.ToLower()
    
    switch -Regex ($message) {
        "expected.*comma|missing.*comma" {
            return "Add missing comma (,) between JSON properties or array elements"
        }
        "unexpected.*token|invalid.*character" {
            return "Remove invalid characters or check for unescaped special characters"
        }
        "unterminated.*string|missing.*quote" {
            return "Add missing closing quote character for string value"
        }
        "comments.*not.*permitted|invalid.*comment" {
            return "Remove comments - JSON does not support comments"
        }
        "duplicate.*key|duplicate.*property" {
            return "Remove or rename duplicate property keys"
        }
        "expected.*}" {
            return "Add missing closing brace (}) for JSON object"
        }
        "expected.*]" {
            return "Add missing closing bracket (]) for JSON array"
        }
        "invalid.*escape.*sequence" {
            return "Fix invalid escape sequence in string (use \\\\ for backslash)"
        }
        "trailing.*comma" {
            return "Remove trailing comma after last JSON property or array element"
        }
        default {
            return "Check JSON syntax - use a JSON validator for detailed error location"
        }
    }
}


