<#
.SYNOPSIS
Repairs common PowerShell syntax errors

.DESCRIPTION
This helper function attempts to automatically fix common PowerShell syntax errors
by analyzing the parse error and applying appropriate corrections to the content.

.PARAMETER Content
The file content as a string

.PARAMETER Error
The parse error object

.EXAMPLE
Repair-SyntaxError -Content $fileContent -Error $parseError
#>
function Repair-SyntaxError {
    CmdletBinding()
    param(
        Parameter(Mandatory)







        string$Content,
        
        Parameter(Mandatory)
        System.Management.Automation.Language.ParseError$Error
    )
    
    $result = @{
        Fixed = $false
        Content = $Content
        Description = ""
    }
    
    $lines = $Content -split "`r?`n"
    $errorLine = $Error.Extent.StartLineNumber - 1  # Convert to 0-based index
    $errorColumn = $Error.Extent.StartColumnNumber - 1
    $errorMessage = $Error.Message.ToLower()
    
    try {
        # Ensure we have a valid line number
        if ($errorLine -lt 0 -or $errorLine -ge $lines.Count) {
            return $result
        }
        
        $currentLine = $lines$errorLine
        
        switch -Regex ($errorMessage) {
            # Missing closing quote
            "missing closing.*quoteunclosed.*quote" {
                if ($currentLine -match '^(.*"^"*)"?$' -and -not ($currentLine -match '^.*"^"*".*$')) {
                    $lines$errorLine = $currentLine + '"'
                    $result.Fixed = $true
                    $result.Description = "Added missing closing double quote"
                } elseif ($currentLine -match "^(.*'^'*)'?$" -and -not ($currentLine -match "^.*'^'*'.*$")) {
                    $lines$errorLine = $currentLine + "'"
                    $result.Fixed = $true
                    $result.Description = "Added missing closing single quote"
                }
                break
            }
            
            # Missing closing brace
            "missing closing.*braceexpected.*}" {
                # Look for the corresponding opening brace
                $braceCount = 0
                for ($i = $errorLine; $i -ge 0; $i--) {
                    $lineText = $lines$i
                    $openBraces = ($lineText.ToCharArray() | Where-Object{ $_ -eq '{' }).Count
                    $closeBraces = ($lineText.ToCharArray() | Where-Object{ $_ -eq '}' }).Count
                    $braceCount += ($openBraces - $closeBraces)
                    
                    if ($braceCount -gt 0) {
                        # Add closing brace at the end of the file or after the last line with content
                        $lastContentLine = $lines.Count - 1
                        while ($lastContentLine -gt $errorLine -and string::IsNullOrWhiteSpace($lines$lastContentLine)) {
                            $lastContentLine--
                        }
                        if ($lastContentLine -ge $errorLine) {
                            $lines$lastContentLine += "`n}"
                            $result.Fixed = $true
                            $result.Description = "Added missing closing brace"
                        }
                        break
                    }
                }
                break
            }
            
            # Missing closing parenthesis
            "missing closing.*parenthesisexpected.*\)" {
                if ($currentLine -match '^(.*\(^)*)\)?$' -and -not ($currentLine -match '^.*\(^)*\).*$')) {
                    $lines$errorLine = $currentLine + ')'
                    $result.Fixed = $true
                    $result.Description = "Added missing closing parenthesis"
                }
                break
            }
            
            # Missing comma
            "expected.*commamissing.*comma" {
                # This is tricky - we need to analyze the context
                if ($currentLine -match '(\s*\.*?\)\s*(\.*?\)') {
                    # Between parameter attributes
                    $lines$errorLine = $currentLine -replace '(\s*\.*?\)\s*(\.*?\)', '$1,`n    $2'
                    $result.Fixed = $true
                    $result.Description = "Added missing comma between parameters"
                } elseif ($currentLine -match '("^"*")\s*("^"*")') {
                    # Between string literals
                    $lines$errorLine = $currentLine -replace '("^"*")\s*("^"*")', '$1, $2'
                    $result.Fixed = $true
                    $result.Description = "Added missing comma between string literals"
                }
                break
            }
            
            # Missing closing bracket
            "missing closing.*bracketexpected.*\" {
                if ($currentLine -match '^(.*\^\*)\?$' -and -not ($currentLine -match '^.*\^\*\.*$')) {
                    $lines$errorLine = $currentLine + ''
                    $result.Fixed = $true
                    $result.Description = "Added missing closing bracket"
                }
                break
            }
            
            default {
                # Cannot automatically fix this error
                return $result
            }
        }
        
        if ($result.Fixed) {
            $result.Content = $lines -join "`n"
        }
        
    } catch {
        # If anything goes wrong, don't apply the fix
        $result.Fixed = $false
        Write-Verbose "Error applying fix: $($_.Exception.Message)"
    }
    
    return $result
}



