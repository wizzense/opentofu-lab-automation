@{
    # CPU-based parallel execution settings
    MaxParallelJobs = 4
    CpuCores = 12
    LogicalProcessors = 20
    
    # Test execution settings
    PesterSettings = @{
        Run = @{
            Exit = $false
            PassThru = $true
        }
        Output = @{
            Verbosity = 'Normal'
        }
        TestResult = @{
            Enabled = $true
            OutputFormat = 'NUnitXml'
            OutputPath = 'tests/results/pester-results.xml'
        }
        CodeCoverage = @{
            Enabled = $true
            OutputFormat = 'JaCoCo'
            OutputPath = 'tests/results/pester-coverage.xml'
            Path = @('src/pwsh/**/*.ps1', 'src/pwsh/**/*.psm1')
        }
    }
    
    # Python test settings
    PytestSettings = @{
        Parallel = @{
            Workers = 4
            Distribution = 'loadscope'
        }
        Coverage = @{
            Source = 'src/python'
            Format = @('xml', 'html', 'term')
            OutputDir = 'tests/results'
        }
        Output = @{
            JunitXml = 'tests/results/pytest-results.xml'
            Verbosity = 'normal'
        }
    }
    
    # Linting settings
    LintingSettings = @{
        PSScriptAnalyzer = @{
            Path = @('src/pwsh/**/*.ps1', 'src/pwsh/**/*.psm1')
            Settings = 'PSScriptAnalyzerSettings.psd1'
            Severity = @('Error', 'Warning')
            Recurse = $true
        }
        Python = @{
            Flake8 = @{
                Path = 'src/python'
                Config = '.flake8'
                MaxComplexity = 10
            }
            Pylint = @{
                Path = 'src/python'
                Config = '.pylintrc'
                FailUnder = 8.0
            }
            Black = @{
                Path = 'src/python'
                LineLength = 100
                Check = $true
            }
        }
    }
}
