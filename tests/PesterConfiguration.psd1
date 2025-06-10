@{ 

    Run = @{ Path = 'tests' }
    CodeCoverage = @{ 
        Path = @('runner_scripts','lab_utils') 
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
