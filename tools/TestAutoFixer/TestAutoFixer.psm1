



# TestAutoFixer.psm1
# PowerShell module that combines test generation, fix scripts, and automated validation
# for OpenTofu Lab Automation

# Import all nested modules/functions
. $PSScriptRoot\SyntaxFixer.ps1
. $PSScriptRoot\TestGenerator.ps1
. $PSScriptRoot\ValidationHelpers.ps1
. $PSScriptRoot\ResultAnalyzer.ps1

# Export module members
Export-ModuleMember -Function @(
    # Syntax fixing
    'Invoke-SyntaxFix',
    'Fix-TernarySyntax',
    'Fix-TestSyntax',
    'Fix-ParamSyntax',
    'Test-SyntaxValidity',
    
    # Test generation
    'New-TestFromScript',
    'Add-AutoFixTrigger',
    'Update-ExistingTests',
    'New-FixWorkflow',
    
    # Validation
    'Get-TestFailures',
    'Get-LintIssues',
    'Invoke-ValidationChecks',
    'Show-ValidationSummary',
    
    # Result analysis
    'Get-TestStatistics',
    'Analyze-TestResults',
    'Format-TestResultsReport',
    'Export-TestResults'
)


