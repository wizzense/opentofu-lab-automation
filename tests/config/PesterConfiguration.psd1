@{
    # Fixed Pester 5.x Configuration for VS Code Integration
    Run = @{
        Path = @('tests/unit', 'tests/integration', 'tests/pester')
        Exit = $false
        PassThru = $true
        Throw = $false
    }
    
    Filter = @{
        ExcludeTag = @('Slow', 'Integration', 'E2E')
        Tag = @()
    }
    
    Output = @{
        Verbosity = 'Normal'
        CIFormat = 'None'
    }
    
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = 'tests/results/TestResults.xml'
        TestSuiteName = 'OpenTofu Lab Automation'
    }
    
    CodeCoverage = @{
        Enabled = $false  # Disable for now to prevent hangs
        Path = @('core-runner/modules', 'core-runner/core_app')
        OutputFormat = 'JaCoCo'
        OutputPath = 'tests/results/coverage.xml'
        OutputEncoding = 'UTF8'
    }
    
    Should = @{
        ErrorAction = 'Continue'
    }
    
    Debug = @{
        ShowFullErrors = $true
        WriteDebugMessages = $false
        WriteDebugMessagesFrom = @()
        ReturnRawResultObject = $false
    }
}



