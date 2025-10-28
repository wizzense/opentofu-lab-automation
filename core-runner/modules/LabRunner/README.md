# LabRunner Module

Comprehensive lab automation and script execution orchestration module for OpenTofu Lab Automation.

## Overview

The LabRunner module is the core execution engine that orchestrates all lab automation scripts. It provides script execution, configuration management, logging integration, and cross-platform compatibility for the entire automation framework.

## Features

- **Script execution orchestration** - Runs automation scripts with proper error handling
- **Configuration management** - Loads and manages lab configuration
- **Cross-platform support** - Windows, Linux, and macOS compatibility
- **Centralized logging** - Integrates with Logging module
- **Web request handling** - Download and HTTP operations
- **Archive extraction** - Handle ZIP, TAR, GZ files
- **Parallel execution support** - Run operations concurrently when possible
- **Platform detection** - Automatic platform-specific behavior

## Installation

The module is automatically available when you import it:

```powershell
Import-Module "./core-runner/modules/LabRunner" -Force
```

## Core Functions

### Invoke-LabStep

Executes a lab automation step with comprehensive error handling.

```powershell
# Execute a lab step
Invoke-LabStep -StepName "Install-Prerequisites" -ScriptBlock {
    # Your automation code
    Install-Package -Name "RequiredTool"
}

# Execute with custom parameters
Invoke-LabStep -StepName "Configure-System" -ScriptBlock {
    param($Config)
    # Use configuration
} -Parameters @{ Config = $labConfig }
```

### Invoke-LabDownload

Downloads files with retry logic and validation.

```powershell
# Download a file
Invoke-LabDownload -Url "https://example.com/file.zip" -Destination "./downloads/file.zip"

# Download with checksum validation
Invoke-LabDownload -Url "https://example.com/tool.exe" -Destination "./tools/tool.exe" -Checksum "abc123..."

# Download with custom headers
Invoke-LabDownload -Url "https://api.example.com/data" -Destination "./data.json" -Headers @{
    "Authorization" = "Bearer token123"
}
```

### Invoke-LabWebRequest

Makes web requests with proper error handling.

```powershell
# GET request
$response = Invoke-LabWebRequest -Uri "https://api.example.com/status" -Method "GET"

# POST request with body
$result = Invoke-LabWebRequest -Uri "https://api.example.com/data" -Method "POST" -Body @{
    name = "test"
    value = 123
}
```

### Write-CustomLog

Centralized logging function (from Logging module, exported by LabRunner).

```powershell
# Log information
Write-CustomLog -Level 'INFO' -Message 'Starting lab automation'

# Log success
Write-CustomLog -Level 'SUCCESS' -Message 'Configuration complete'

# Log warning
Write-CustomLog -Level 'WARN' -Message 'Optional component not found'

# Log error
Write-CustomLog -Level 'ERROR' -Message "Operation failed: $($_.Exception.Message)"
```

### Read-LoggedInput

Reads user input with logging.

```powershell
# Prompt for input
$username = Read-LoggedInput -Prompt "Enter username"

# Prompt with validation
$port = Read-LoggedInput -Prompt "Enter port number" -ValidateScript {
    $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le 65535
}
```

### Get-Platform

Detects the current platform.

```powershell
# Get platform
$platform = Get-Platform  # Returns: "Windows", "Linux", or "macOS"

# Use platform-specific logic
switch (Get-Platform) {
    "Windows" { 
        $separator = ";"
        $nullDevice = "NUL"
    }
    "Linux" { 
        $separator = ":"
        $nullDevice = "/dev/null"
    }
    "macOS" {
        $separator = ":"
        $nullDevice = "/dev/null"
    }
}
```

### Get-LabConfig

Loads lab configuration from JSON files.

```powershell
# Load default configuration
$config = Get-LabConfig

# Load custom configuration
$config = Get-LabConfig -ConfigPath "./configs/custom-config.json"

# Access configuration values
$repoUrl = $config.RepositoryUrl
$branch = $config.Branch
```

### Invoke-ParallelLabRunner

Runs multiple lab operations in parallel.

```powershell
# Run multiple scripts in parallel
$operations = @(
    @{ Name = "Install-Go"; Script = "./scripts/0007_Install-Go.ps1" }
    @{ Name = "Install-OpenTofu"; Script = "./scripts/0008_Install-OpenTofu.ps1" }
)

Invoke-ParallelLabRunner -Operations $operations -MaxThreads 4

# Run with custom configuration
Invoke-ParallelLabRunner -Operations $operations -ConfigPath "./custom-config.json"
```

### Test-ParallelRunnerSupport

Tests if parallel execution is supported on current platform.

```powershell
# Check support
if (Test-ParallelRunnerSupport) {
    Write-Host "Parallel execution supported"
    Invoke-ParallelLabRunner -Operations $ops
} else {
    Write-Host "Running sequentially"
    foreach ($op in $ops) {
        & $op.Script
    }
}
```

## Archive and Compression Functions

### Invoke-ArchiveDownload

Downloads and extracts archives.

```powershell
# Download and extract ZIP
Invoke-ArchiveDownload -Url "https://example.com/package.zip" -Destination "./extracted"

# Download and extract TAR.GZ
Invoke-ArchiveDownload -Url "https://example.com/package.tar.gz" -Destination "./tools"
```

### Expand-All

Extracts various archive formats.

```powershell
# Extract ZIP
Expand-All -Path "./downloads/package.zip" -Destination "./extracted"

# Extract TAR.GZ
Expand-All -Path "./downloads/package.tar.gz" -Destination "./tools"

# Extract with overwrite
Expand-All -Path "./package.zip" -Destination "./output" -Force
```

### Invoke-LabNpm

Manages npm operations in lab environment.

```powershell
# Install npm package
Invoke-LabNpm -Command "install" -Package "typescript" -Global

# Run npm script
Invoke-LabNpm -Command "run" -Script "build"
```

## Installation and Validation Functions

### Invoke-OpenTofuInstaller

Handles OpenTofu installation with verification.

```powershell
# Install OpenTofu
Invoke-OpenTofuInstaller -Version "1.6.0" -InstallPath "C:/tools/opentofu"

# Install with cosign verification
Invoke-OpenTofuInstaller -Version "1.6.0" -VerifySignature
```

## Utility Functions

### Resolve-ProjectPath

Resolves paths relative to project root.

```powershell
# Resolve relative path
$fullPath = Resolve-ProjectPath -RelativePath "configs/default-config.json"

# Returns absolute path from project root
```

### Get-GhDownloadArgs

Constructs GitHub download arguments.

```powershell
# Get download args for GitHub release
$args = Get-GhDownloadArgs -Repository "opentofu/opentofu" -Tag "v1.6.0" -Asset "opentofu_1.6.0_windows_amd64.zip"
```

### Initialize-StandardParameters

Initializes standard script parameters.

```powershell
# Initialize common parameters
$params = Initialize-StandardParameters -Verbosity "detailed" -NonInteractive $false

# Use standardized parameters in scripts
if ($params.Verbosity -eq 'detailed') {
    # Show detailed output
}
```

## Usage Examples

### Basic Lab Script Execution

```powershell
# Import module
Import-Module "./core-runner/modules/LabRunner" -Force

# Execute lab step
Invoke-LabStep -StepName "System-Preparation" -ScriptBlock {
    Write-CustomLog -Level 'INFO' -Message 'Preparing system...'
    
    # Install prerequisites
    $platform = Get-Platform
    Write-CustomLog -Level 'INFO' -Message "Detected platform: $platform"
    
    # Platform-specific setup
    switch ($platform) {
        "Windows" { 
            # Windows setup
        }
        "Linux" { 
            # Linux setup
        }
    }
    
    Write-CustomLog -Level 'SUCCESS' -Message 'System preparation complete'
}
```

### Download and Extract Tool

```powershell
# Download tool
$url = "https://releases.example.com/tool-v1.0.0.zip"
$downloadPath = "./downloads/tool.zip"
$extractPath = "./tools/tool"

Write-CustomLog -Level 'INFO' -Message "Downloading tool from $url"
Invoke-LabDownload -Url $url -Destination $downloadPath

Write-CustomLog -Level 'INFO' -Message "Extracting to $extractPath"
Expand-All -Path $downloadPath -Destination $extractPath

Write-CustomLog -Level 'SUCCESS' -Message 'Tool installation complete'
```

### Configuration-Driven Automation

```powershell
# Load configuration
$config = Get-LabConfig -ConfigPath "./configs/lab-config.json"

# Use configuration values
Invoke-LabStep -StepName "Clone-Repository" -ScriptBlock {
    param($RepoUrl, $Branch, $LocalPath)
    
    Write-CustomLog -Level 'INFO' -Message "Cloning $RepoUrl (branch: $Branch)"
    
    git clone --branch $Branch $RepoUrl $LocalPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-CustomLog -Level 'SUCCESS' -Message "Repository cloned to $LocalPath"
    } else {
        throw "Git clone failed with exit code $LASTEXITCODE"
    }
} -Parameters @{
    RepoUrl = $config.RepositoryUrl
    Branch = $config.Branch
    LocalPath = $config.LocalPath
}
```

### Parallel Operations

```powershell
# Define parallel operations
$operations = @(
    @{
        Name = "Download-ISO"
        Script = {
            Invoke-LabDownload -Url $isoUrl -Destination "./isos/server.iso"
        }
    },
    @{
        Name = "Download-Tools"
        Script = {
            Invoke-LabDownload -Url $toolsUrl -Destination "./tools/tools.zip"
        }
    },
    @{
        Name = "Update-Packages"
        Script = {
            if (Get-Platform -eq "Linux") {
                sudo apt-get update
            }
        }
    }
)

# Execute in parallel
if (Test-ParallelRunnerSupport) {
    Invoke-ParallelLabRunner -Operations $operations -MaxThreads 3
}
```

## Integration with Core Runner

LabRunner is the execution engine for core-runner.ps1:

```powershell
# Core runner uses LabRunner for all script execution
./core-runner.ps1 -NonInteractive -Scripts "0006,0007,0008" -Verbosity detailed
```

## Error Handling

All functions include comprehensive error handling:

```powershell
try {
    Invoke-LabStep -StepName "Critical-Operation" -ScriptBlock {
        # Critical operation that might fail
        Invoke-SomeOperation
    }
} catch {
    Write-CustomLog -Level 'ERROR' -Message "Operation failed: $($_.Exception.Message)"
    
    # Cleanup or rollback
    Invoke-Cleanup
    
    throw
}
```

## Cross-Platform Compatibility

LabRunner handles platform differences automatically:

```powershell
# Automatic path handling
$path = Join-Path $baseDir $fileName  # Works on all platforms

# Platform detection
$platform = Get-Platform

# Platform-specific commands
if ($platform -eq "Windows") {
    $result = & cmd.exe /c "dir"
} else {
    $result = & ls -la
}
```

## Configuration Files

LabRunner uses these configuration files:

- `./configs/default-config.json` - Default configuration
- `./configs/core-runner-config.json` - Core runner settings
- `./core-runner/core_app/default-config.json` - Application defaults

## Log Integration

LabRunner integrates with the Logging module:

- All operations logged with appropriate levels
- Performance tracing for long operations
- Debug context for troubleshooting
- Centralized log files in `./logs/`

## Best Practices

1. **Always use Write-CustomLog** for output instead of Write-Host in automation scripts
2. **Leverage platform detection** with Get-Platform for cross-platform scripts
3. **Use Invoke-LabStep** for major operations to ensure proper error handling
4. **Load configuration** with Get-LabConfig for flexibility
5. **Implement parallel execution** where possible for performance
6. **Handle archives** with Expand-All for consistency
7. **Validate downloads** with checksums when available

## Testing Integration

Test LabRunner functionality:

```powershell
# Run LabRunner tests
pwsh -File "./tests/unit/modules/LabRunner.Tests.ps1"

# Test parallel execution
pwsh -File "./tests/integration/ParallelExecution.Tests.ps1"
```

## Troubleshooting

### Script execution fails
- Check verbosity level: Use `-Verbosity detailed`
- Review logs in `./logs/automation-*.log`
- Verify script syntax with `pwsh -NoProfile -File script.ps1`

### Downloads fail
- Verify URL is accessible
- Check network connectivity
- Review proxy settings if behind firewall
- Ensure destination directory exists and is writable

### Platform detection issues
- Verify PowerShell version: `$PSVersionTable`
- Check `$IsWindows`, `$IsLinux`, `$IsMacOS` built-in variables
- Review platform-specific code paths

## Version History

- **0.1.0**: Initial release with core lab automation functionality

## Related Modules

- [Logging](../Logging/) - Centralized logging used by all LabRunner operations
- [ParallelExecution](../ParallelExecution/) - Advanced parallel processing
- [PatchManager](../PatchManager/) - Code patching and Git operations
- [TestingFramework](../TestingFramework/) - Test execution and validation

## Contributing

When adding new LabRunner features:

1. Maintain cross-platform compatibility
2. Integrate with Logging module for all output
3. Follow error handling patterns with try-catch
4. Include comprehensive help documentation
5. Test on Windows, Linux, and macOS
6. Update this README with new functionality
