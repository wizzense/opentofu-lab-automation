






@{
    RootModule = 'TestAutoFixer.psm1'
    ModuleVersion = '0.1.0'
    GUID = '1a2b3c4d-e5f6-4a5b-9c8d-7e6f5d4c3b2a'
    Author = 'OpenTofu Lab Automation Team'
    CompanyName = 'OpenTofu'
    Copyright = '(c) OpenTofu. All rights reserved.'
    Description = 'Automated testing and fixing module for OpenTofu Lab Automation'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        # SyntaxFixer functions
        'Repair-PowerShellSyntax',
        'Fix-TernaryOperator',
        'Fix-ParameterSyntax',
        'Fix-TestSyntax',
        'Fix-BootstrapScript',
        'Fix-RunnerExecution',
        
        # TestGenerator functions
        'New-AutoTest',
        'Update-ExistingTest',
        'Add-AutoFixTrigger',
        'New-RunnerScriptTest',
        
        # ValidationHelpers functions
        'Get-TestFailures',
        'Get-LintIssues',
        'Invoke-ComprehensiveValidation',
        'Export-TestResults',
        'Import-TestResults'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Testing', 'Automation', 'OpenTofu')
            LicenseUri = 'https://github.com/opentofu/opentofu-lab-automation/blob/main/LICENSE'
            ProjectUri = 'https://github.com/opentofu/opentofu-lab-automation'
        }
    }
}



