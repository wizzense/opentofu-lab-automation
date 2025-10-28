@{
    # Agent Team Configuration for OpenTofu Lab Automation
    # This configuration is read by all custom agents on initialization
    
    # Team Metadata
    TeamName = 'OpenTofu Lab Automation Agent Team'
    TeamVersion = '1.0.0'
    LastUpdated = '2025-10-28'
    
    # Project Configuration
    Project = @{
        Name = 'OpenTofu Lab Automation'
        Description = 'Cross-platform PowerShell automation framework for OpenTofu/Terraform infrastructure management'
        Repository = 'https://github.com/wizzense/opentofu-lab-automation'
        PowerShellVersion = '7.0+'
        PrimaryLanguages = @('PowerShell', 'HCL', 'Terraform')
    }
    
    # Core Modules (What agents should be aware of)
    CoreModules = @(
        @{
            Name = 'Logging'
            Purpose = 'Enterprise-grade centralized logging system'
            PrimaryContact = 'PowerShellArchitect'
        }
        @{
            Name = 'PatchManager'
            Purpose = 'Git operations and patch management with automated workflows'
            PrimaryContact = 'DevOpsEngineer'
        }
        @{
            Name = 'LabRunner'
            Purpose = 'Lab automation orchestration and test execution'
            PrimaryContact = 'LabEnvironmentManager'
        }
        @{
            Name = 'BackupManager'
            Purpose = 'File backup, cleanup, and consolidation operations'
            PrimaryContact = 'LabEnvironmentManager'
        }
        @{
            Name = 'DevEnvironment'
            Purpose = 'Development environment preparation and validation'
            PrimaryContact = 'DevOpsEngineer'
        }
        @{
            Name = 'ParallelExecution'
            Purpose = 'Runspace-based parallel task execution'
            PrimaryContact = 'PerformanceOptimizer'
        }
        @{
            Name = 'ScriptManager'
            Purpose = 'Script repository management and template handling'
            PrimaryContact = 'PowerShellArchitect'
        }
        @{
            Name = 'TestingFramework'
            Purpose = 'Pester test wrapper with project-specific configurations'
            PrimaryContact = 'TestingGuardian'
        }
        @{
            Name = 'UnifiedMaintenance'
            Purpose = 'Unified entry point for all maintenance operations'
            PrimaryContact = 'DevOpsEngineer'
        }
    )
    
    # Agent Team Members
    Agents = @(
        @{
            Name = 'InfrastructureOrchestrator'
            DisplayName = 'Maya Rodriguez'
            Gender = 'Female'
            Role = 'Infrastructure Orchestrator'
            Specialization = 'OpenTofu/Terraform'
            Active = $true
        }
        @{
            Name = 'PowerShellArchitect'
            DisplayName = 'James Chen'
            Gender = 'Male'
            Role = 'PowerShell Architect'
            Specialization = 'Module Development'
            Active = $true
        }
        @{
            Name = 'TestingGuardian'
            DisplayName = 'Aisha Patel'
            Gender = 'Female'
            Role = 'Testing Guardian'
            Specialization = 'Quality Assurance'
            Active = $true
        }
        @{
            Name = 'DevOpsEngineer'
            DisplayName = 'Marcus Johnson'
            Gender = 'Male'
            Role = 'DevOps Engineer'
            Specialization = 'CI/CD & Automation'
            Active = $true
        }
        @{
            Name = 'SecurityAnalyst'
            DisplayName = 'Elena Kowalski'
            Gender = 'Female'
            Role = 'Security Analyst'
            Specialization = 'Security & Compliance'
            Active = $true
        }
        @{
            Name = 'DocumentationSpecialist'
            DisplayName = 'David Kim'
            Gender = 'Male'
            Role = 'Documentation Specialist'
            Specialization = 'Technical Writing'
            Active = $true
        }
        @{
            Name = 'PerformanceOptimizer'
            DisplayName = 'Sophia Andersson'
            Gender = 'Female'
            Role = 'Performance Optimizer'
            Specialization = 'Code Optimization'
            Active = $true
        }
        @{
            Name = 'LabEnvironmentManager'
            DisplayName = 'Carlos Martinez'
            Gender = 'Male'
            Role = 'Lab Environment Manager'
            Specialization = 'Lab Configuration'
            Active = $true
        }
    )
    
    # Operational Standards
    Standards = @{
        CodeStyle = 'OTBS (One True Brace Style)'
        PathSeparator = '/' # Cross-platform forward slashes
        ErrorHandling = 'Comprehensive try-catch with logging'
        LoggingModule = 'Write-CustomLog'
        TestingFramework = 'Pester 5.0+'
        MinimalChanges = $true
        SecurityFirst = $true
    }
    
    # Communication Protocols
    Communication = @{
        PreferredChannels = @('GitHub Issues', 'Pull Requests', 'Code Reviews')
        ResponseTime = 'Within 24 hours for standard requests'
        EscalationPath = 'Team Lead -> Project Manager'
        CollaborationStyle = 'Pair programming encouraged'
    }
    
    # Key Directories (Agents should be aware of these)
    ProjectStructure = @{
        CoreRunner = './core-runner'
        Modules = './core-runner/modules'
        Scripts = './core-runner/core_app/scripts'
        Configs = './configs'
        Tests = './tests'
        Docs = './docs'
        Tools = './tools'
        OpenTofu = './opentofu'
        Logs = './logs'
    }
    
    # Configuration Files (Agents read these)
    ConfigurationFiles = @{
        CoreRunnerConfig = './configs/core-runner-config.json'
        DefaultConfig = './configs/default-config.json'
        FullConfig = './configs/full-config.json'
        RecommendedConfig = './configs/recommended-config.json'
    }
    
    # Team Values
    Values = @(
        'Quality over speed'
        'Security is non-negotiable'
        'Cross-platform compatibility always'
        'Comprehensive testing required'
        'Clear documentation mandatory'
        'Collaboration and knowledge sharing'
        'Continuous improvement mindset'
        'User experience matters'
    )
}
