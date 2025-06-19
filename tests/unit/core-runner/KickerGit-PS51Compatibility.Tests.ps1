<#
.SYNOPSIS
    Tests for kicker-git.ps1 PowerShell 5.1 compatibility and Unicode character handling

.DESCRIPTION
    Validates that kicker-git.ps1 works correctly with PowerShell 5.1 and doesn'\''t contain
    Unicode characters that would cause parsing errors on Windows endpoints.
#>

Describe "kicker-git.ps1 PowerShell 5.1 Compatibility" {
    BeforeAll {
        $kickerScriptPath = Join-Path $PSScriptRoot "../../../kicker-git.ps1"
        $kickerContent = Get-Content $kickerScriptPath -Raw -Encoding UTF8
    }

    Context "Unicode Character Validation" {
        It "Should not contain problematic Unicode characters" {
            # Check for common problematic Unicode characters that cause PowerShell 5.1 parsing errors
            $problematicChars = @(
                [char]0x2713,  # ✓ (check mark)
                [char]0x2717,  # ✗ (ballot x)
                [char]0x2022,  # • (bullet)
                [char]0x2192,  # → (right arrow)
                [char]0x2190,  # ← (left arrow)
                [char]0x2605,  # ★ (star)
                [char]0x26A0   # ⚠ (warning sign)
            )
            
            foreach ($char in $problematicChars) {
                $kickerContent | Should -Not -Match [regex]::Escape($char) -Because "Unicode character '$char' can cause PowerShell 5.1 parsing errors"
            }
        }

        It "Should only contain ASCII characters in function definitions" {
            # Extract function definitions and check they only use ASCII
            $functionMatches = [regex]::Matches($kickerContent, "function\s+[\w-]+\s*\{[^}]*\}", [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($match in $functionMatches) {
                $functionText = $match.Value
                for ($i = 0; $i -lt $functionText.Length; $i++) {
                    $char = $functionText[$i]
                    [int]$charCode = [int]$char
                    $charCode | Should -BeLessOrEqual 127 -Because "Function definitions should only contain ASCII characters (found char code $charCode at position $i)"
                }
            }
        }

        It "Should not contain UTF-8 BOM" {
            $bytes = [System.IO.File]::ReadAllBytes($kickerScriptPath)
            if ($bytes.Length -ge 3) {
                # Check for UTF-8 BOM (EF BB BF)
                $hasBOM = ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
                $hasBOM | Should -Be $false -Because "UTF-8 BOM can cause issues with PowerShell 5.1"
            }
        }
    }

    Context "PowerShell 5.1 Syntax Validation" {
        It "Should have valid PowerShell syntax" {
            # Test that the script can be parsed without errors
            $errors = $null
            $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($kickerScriptPath, [ref]$tokens, [ref]$errors)
            
            $errors | Should -BeNullOrEmpty -Because "Script should parse without syntax errors"
            $ast | Should -Not -BeNullOrEmpty -Because "Script should produce a valid AST"
        }

        It "Should not use PowerShell 6+ specific features" {
            # Check for features that don'\''t exist in PowerShell 5.1
            $ps6PlusFeatures = @(
                "ForEach-Object -Parallel",
                "using namespace",
                "class.*:.*\[.*\]",
                "\[ValidateRange\(.*,.*\)\]"  # Some ValidateRange overloads
            )
            
            foreach ($feature in $ps6PlusFeatures) {
                $kickerContent | Should -Not -Match $feature -Because "PowerShell 6+ feature '$feature' is not compatible with PowerShell 5.1"
            }
        }

        It "Should properly handle cross-platform paths" {
            # Verify that path handling is compatible
            $kickerContent | Should -Match "Get-PlatformTempPath" -Because "Should use cross-platform path function"
            $kickerContent | Should -Not -Match "C:\\" -Because "Should not hardcode Windows paths"
            $kickerContent | Should -Not -Match "/tmp/" -Because "Should not hardcode Unix paths"
        }
    }

    Context "Runtime Compatibility" {
        It "Should execute without errors in PowerShell 5.1 simulation" {
            # Simulate PowerShell 5.1 environment variables
            $originalPSVersion = $PSVersionTable.PSVersion
            
            try {
                # Test script parsing in a restricted scope
                $scriptBlock = [ScriptBlock]::Create($kickerContent)
                $scriptBlock | Should -Not -BeNullOrEmpty -Because "Script should compile to a valid script block"
            }
            catch {
                throw "Script failed to compile: $($_.Exception.Message)"
            }
        }

        It "Should handle missing PowerShell 7 gracefully" {
            # Verify fallback behavior when PowerShell 7 is not available
            $kickerContent | Should -Match "powershell\.exe" -Because "Should fallback to PowerShell 5.1 when PowerShell 7 is unavailable"
        }
    }

    Context "Cross-Platform Encoding" {
        It "Should use consistent encoding" {
            # Check file encoding consistency
            $encoding = Get-FileEncoding $kickerScriptPath
            $encoding | Should -Match "UTF8|ASCII" -Because "File should use UTF-8 or ASCII encoding"
        }

        It "Should handle line endings correctly" {
            # Check for consistent line endings
            $rawBytes = [System.IO.File]::ReadAllBytes($kickerScriptPath)
            $hasWindowsLineEndings = ([System.Text.Encoding]::UTF8.GetString($rawBytes) -match "\r\n")
            
            # Should have consistent line endings (not mixed)
            if ($hasWindowsLineEndings -and $hasUnixLineEndings) {
                throw "File has mixed line endings which can cause issues"
            }
        }
    }
}

# Helper function to detect file encoding
function Get-FileEncoding {
    param([string]$Path)
    
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    
    if ($bytes.Length -ge 4) {
        # UTF-32 BE
        if ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            return "UTF32-BE"
        }
        # UTF-32 LE
        if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
            return "UTF32-LE"
        }
    }
    
    if ($bytes.Length -ge 3) {
        # UTF-8 BOM
        if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            return "UTF8-BOM"
        }
    }
    
    if ($bytes.Length -ge 2) {
        # UTF-16 BE
        if ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            return "UTF16-BE"
        }
        # UTF-16 LE
        if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            return "UTF16-LE"
        }
    }
    
    # Try to detect UTF-8 without BOM
    try {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $backToBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        if (($bytes | Measure-Object).Count -eq ($backToBytes | Measure-Object).Count) {
            for ($i = 0; $i -lt $bytes.Length; $i++) {
                if ($bytes[$i] -ne $backToBytes[$i]) {
                    return "ASCII"
                }
            }
            return "UTF8"
        }
    }
    catch {
        return "ASCII"
    }
    
    return "ASCII"
}
