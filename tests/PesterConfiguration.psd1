



@{ 

    Run = @{ Path = 'tests' }
    CodeCoverage = @{ 
        Path = @('pwsh/runner_scripts','pwsh/lab_utils')
        OutputFormat = 'JaCoCo' 
        Enabled = $true 
        OutputPath = 'coverage/coverage.xml' 

    }
    TestResult = @{ 
        Enabled = $true 
        OutputFormat = 'NUnitXml' 
        OutputPath = 'coverage/testResults.xml' 
    }
}


