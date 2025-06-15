# CodeFixer.psm1
# A PowerShell module for automatically detecting and fixing common code issues
# in PowerShell scripts, tests, and workflows.

# Get function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
Foreach($import in @($Public + $Private)) {
    Try {
        . $import.fullname
        Write-Verbose "Imported function: $($import.BaseName)"
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Ensure proper dot-sourcing of public functions
foreach ($import in $Public) {
    try {
        . $import.FullName
        Write-Verbose "Successfully imported: $($import.BaseName)"
    } catch {
        Write-Error "Failed to import: $($import.FullName) - $_"
    }
}

# Verify function accessibility
if (-not (Get-Command Invoke-ComprehensiveValidation -ErrorAction SilentlyContinue)) {
    Write-Error "Invoke-ComprehensiveValidation is not accessible after import. Check the function definition."
}

# Import TestAutoFixer functions (disabled temporarily due to auto-execution issues)
# $TestAutoFixerPath = Join-Path (Split-Path $PSScriptRoot -Parent) "../../tools/TestAutoFixer"
# if (Test-Path $TestAutoFixerPath) {
#     $TestAutoFixerFiles = @(Get-ChildItem -Path $TestAutoFixerPath\*.ps1 -ErrorAction SilentlyContinue)
#     Foreach($import in $TestAutoFixerFiles) {
#         Try {
#             . $import.fullname
#             Write-Verbose "Imported TestAutoFixer function: $($import.BaseName)"
#         }
#         Catch {
#             Write-Verbose "Could not import TestAutoFixer function $($import.fullname): $_"
#         }
#     }
# }

# Export all public functions
$PublicFunctions = @(
    'Invoke-PowerShellLint'
    'Invoke-AutoFix'
    'Invoke-ComprehensiveValidation'
    'Invoke-ComprehensiveAutoFix'
    'Invoke-ImportAnalysis'
    'Invoke-HereStringFix'
    'Invoke-TernarySyntaxFix'
    'Invoke-TestSyntaxFix'
    'Invoke-ScriptOrderFix'
    'Invoke-ResultsAnalysis'
    'Test-JsonConfig'
    'New-AutoTest'
    'Watch-ScriptDirectory'
    'Initialize-PSScriptAnalyzer'
    'Invoke-ParallelScriptAnalyzer'
    'Invoke-AutomaticFixCapture'
    'New-AutoFixRule'
    'Invoke-ParallelPesterTests'
    'Invoke-IntegrationTests'
    'Merge-TestResults'
    'Invoke-AutoFixCapture'
    'Export-FixPatterns'
    'Import-FixPatterns'
)

Export-ModuleMember -Function $PublicFunctions

Write-Verbose "CodeFixer module loaded with $($Public.Count) public functions and $($Private.Count) private functions"


