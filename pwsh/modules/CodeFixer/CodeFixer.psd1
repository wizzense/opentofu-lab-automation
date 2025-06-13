



# Module manifest for CodeFixer module
@{
    RootModule = 'CodeFixer.psm1'
    ModuleVersion = '0.1.0'
    GUID = '67af2e23-ccb5-4a4a-9d27-c8f7992d1234'
    Author = 'OpenTofu Lab Automation'
    CompanyName = 'OpenTofu'
    Copyright = '(c) OpenTofu Lab Automation'
    Description = 'Tools for automatically detecting and fixing common code issues'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        # Core PowerShell linting and fixing
        'Invoke-PowerShellLint',
        'Invoke-AutoFix',
        'Invoke-ComprehensiveValidation',
        'Invoke-ComprehensiveAutoFix',
        'Invoke-ImportAnalysis',
        'Invoke-HereStringFix',
        'Invoke-TernarySyntaxFix',
        'Invoke-TestSyntaxFix',
        'Invoke-ScriptOrderFix',
        'Invoke-ResultsAnalysis',
        'Invoke-ParallelScriptAnalyzer',
        'Invoke-AutomaticFixCapture',
        'New-AutoFixRule',
        'Invoke-ParallelPesterTests',
        'Invoke-IntegrationTests',
        'Merge-TestResults',
        'Invoke-AutoFixCapture',
        'Export-FixPatterns',
        'Import-FixPatterns',
        
        # Config and JSON validation
        'Test-JsonConfig',
        
        # Testing and generation
        'New-AutoTest',
        
        # Directory watching
        'Watch-ScriptDirectory'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    FileList = @(
        'CodeFixer.psm1',
        'Public\Invoke-PowerShellLint.ps1',
        'Public\Invoke-AutoFix.ps1',
        'Public\Invoke-ComprehensiveValidation.ps1',
        'Public\Invoke-ImportAnalysis.ps1',
        'Public\Test-JsonConfig.ps1',
        'Private\Get-SyntaxFixSuggestion.ps1',
        'Private\Get-JsonFixSuggestion.ps1',
        'Private\Repair-SyntaxError.ps1'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('CodeFix', 'Testing', 'Automation', 'Syntax', 'PowerShell')
            ProjectUri = 'https://github.com/opentofu/opentofu-lab-automation'
        }
    }
}


