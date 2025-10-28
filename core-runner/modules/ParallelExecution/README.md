# ParallelExecution Module

Parallel processing utilities for OpenTofu Lab Automation with runspace-based execution and PowerShell job management.

## Overview

The ParallelExecution module provides cross-platform parallel processing capabilities using PowerShell runspaces and jobs. It enables concurrent execution of tasks for improved performance in lab automation scenarios.

## Features

- **Runspace-based parallelism** - Efficient parallel execution
- **Job management** - Start, monitor, and wait for parallel jobs
- **Automatic throttling** - Control maximum concurrent operations
- **Cross-platform** - Works on Windows, Linux, and macOS
- **Test parallelization** - Parallel Pester test execution
- **Result merging** - Combine results from parallel operations

## Installation

```powershell
Import-Module "./core-runner/modules/ParallelExecution" -Force
```

## Functions

### Invoke-ParallelForEach

Executes a script block for each item in a collection in parallel.

```powershell
# Process items in parallel
$results = Invoke-ParallelForEach -Items @(1..10) -ScriptBlock {
    param($Item)
    # Process item
    $Item * 2
} -MaxThreads 4

# Process files in parallel
$files = Get-ChildItem "./data" -Filter "*.txt"
$results = Invoke-ParallelForEach -Items $files -ScriptBlock {
    param($File)
    Get-Content $File.FullName | Measure-Object -Line
} -MaxThreads 8
```

**Parameters:**
- **Items**: Collection to process
- **ScriptBlock**: Code to execute for each item
- **MaxThreads**: Maximum concurrent threads (default: CPU count)

### Start-ParallelJob

Starts a parallel job using runspaces.

```powershell
# Start multiple jobs
$jobs = @()
foreach ($server in $servers) {
    $job = Start-ParallelJob -ScriptBlock {
        param($ServerName)
        Test-Connection -ComputerName $ServerName -Count 1
    } -Parameters @{ ServerName = $server }
    
    $jobs += $job
}

# Wait for all jobs
Wait-ParallelJobs -Jobs $jobs
```

### Wait-ParallelJobs

Waits for parallel jobs to complete and collects results.

```powershell
# Start jobs
$jobs = 1..5 | ForEach-Object {
    Start-ParallelJob -ScriptBlock {
        param($Number)
        Start-Sleep -Seconds $Number
        return "Job $Number completed"
    } -Parameters @{ Number = $_ }
}

# Wait for completion
$results = Wait-ParallelJobs -Jobs $jobs -TimeoutSeconds 60

# Process results
$results | ForEach-Object {
    Write-Host "Result: $_"
}
```

**Parameters:**
- **Jobs**: Array of job objects
- **TimeoutSeconds**: Maximum wait time (optional)

### Invoke-ParallelPesterTests

Runs Pester tests in parallel for faster execution.

```powershell
# Run all unit tests in parallel
$results = Invoke-ParallelPesterTests -TestPath "./tests/unit" -MaxThreads 4

# Run specific test files in parallel
$testFiles = @(
    "./tests/unit/Module1.Tests.ps1"
    "./tests/unit/Module2.Tests.ps1"
    "./tests/unit/Module3.Tests.ps1"
)
$results = Invoke-ParallelPesterTests -TestFiles $testFiles -MaxThreads 3

# Display results
Write-Host "Total: $($results.TotalCount), Passed: $($results.PassedCount), Failed: $($results.FailedCount)"
```

### Merge-ParallelTestResults

Merges test results from parallel execution.

```powershell
# Run tests in parallel
$results1 = Invoke-PesterTests -Path "./tests/unit/Set1"
$results2 = Invoke-PesterTests -Path "./tests/unit/Set2"
$results3 = Invoke-PesterTests -Path "./tests/unit/Set3"

# Merge results
$mergedResults = Merge-ParallelTestResults -Results @($results1, $results2, $results3)

# Export merged results
$mergedResults | Export-Clixml -Path "./test-results/merged.xml"
```

## Usage Examples

### Parallel File Processing

```powershell
# Import module
Import-Module "./core-runner/modules/ParallelExecution" -Force

# Get files to process
$files = Get-ChildItem "./data" -Recurse -Filter "*.log"

# Process in parallel
$results = Invoke-ParallelForEach -Items $files -ScriptBlock {
    param($File)
    
    # Process file
    $content = Get-Content $File.FullName
    $errors = $content | Where-Object { $_ -match "ERROR" }
    
    [PSCustomObject]@{
        FileName = $File.Name
        ErrorCount = $errors.Count
        FileSize = $File.Length
    }
} -MaxThreads 8

# Display results
$results | Format-Table -AutoSize
```

### Parallel Web Requests

```powershell
# URLs to check
$urls = @(
    "https://example.com"
    "https://google.com"
    "https://github.com"
    "https://microsoft.com"
)

# Check all URLs in parallel
$results = Invoke-ParallelForEach -Items $urls -ScriptBlock {
    param($Url)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing
        [PSCustomObject]@{
            Url = $Url
            StatusCode = $response.StatusCode
            Success = $true
        }
    } catch {
        [PSCustomObject]@{
            Url = $Url
            StatusCode = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
} -MaxThreads 4

# Show results
$results | Format-Table -AutoSize
```

### Parallel Module Tests

```powershell
# Discover all module test files
$moduleTests = Get-ChildItem "./tests/unit/modules" -Filter "*.Tests.ps1"

# Run in parallel
$results = Invoke-ParallelPesterTests -TestFiles $moduleTests.FullName -MaxThreads 6

# Report
Write-Host "`nTest Execution Summary:" -ForegroundColor Cyan
Write-Host "  Total Tests: $($results.TotalCount)"
Write-Host "  Passed: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Failed: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Duration: $($results.Duration)"
```

### Background Job Pattern

```powershell
# Start long-running jobs
$jobs = @()

foreach ($task in $tasks) {
    $job = Start-ParallelJob -ScriptBlock {
        param($TaskData)
        
        # Long-running operation
        Start-Sleep -Seconds 30
        
        # Return result
        "Task $($TaskData.Id) completed"
        
    } -Parameters @{ TaskData = $task }
    
    $jobs += $job
}

# Do other work while jobs run
Write-Host "Jobs started, doing other work..."

# Wait for all jobs with timeout
$results = Wait-ParallelJobs -Jobs $jobs -TimeoutSeconds 120

# Process results
if ($results) {
    $results | ForEach-Object {
        Write-Host "Job result: $_"
    }
}
```

## Performance Considerations

### Optimal Thread Count

```powershell
# Get CPU count
$cpuCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors

# Use CPU count for CPU-bound tasks
$maxThreads = $cpuCount

# Use higher count for I/O-bound tasks
$maxThreads = $cpuCount * 2
```

### Memory Management

```powershell
# For large datasets, process in batches
$allItems = 1..10000
$batchSize = 100

for ($i = 0; $i -lt $allItems.Count; $i += $batchSize) {
    $batch = $allItems[$i..([Math]::Min($i + $batchSize - 1, $allItems.Count - 1))]
    
    $results = Invoke-ParallelForEach -Items $batch -ScriptBlock {
        param($Item)
        # Process item
    } -MaxThreads 4
    
    # Process batch results
    $results | Export-Csv "./results.csv" -Append
}
```

## Error Handling

```powershell
# Parallel execution with error handling
$results = Invoke-ParallelForEach -Items $items -ScriptBlock {
    param($Item)
    
    try {
        # Risky operation
        $result = Invoke-RiskyOperation -Item $Item
        
        [PSCustomObject]@{
            Item = $Item
            Success = $true
            Result = $result
            Error = $null
        }
    } catch {
        [PSCustomObject]@{
            Item = $Item
            Success = $false
            Result = $null
            Error = $_.Exception.Message
        }
    }
} -MaxThreads 4

# Check for errors
$errors = $results | Where-Object { -not $_.Success }
if ($errors) {
    Write-Warning "Errors occurred in $($errors.Count) items"
    $errors | ForEach-Object {
        Write-Error "Item $($_.Item): $($_.Error)"
    }
}
```

## Integration with TestingFramework

```powershell
# ParallelExecution is used by TestingFramework
Import-Module "./core-runner/modules/TestingFramework" -Force

# Run tests in parallel (uses ParallelExecution)
Invoke-UnifiedTestExecution -TestSuite "All" -EnableParallel -MaxThreads 4
```

## Best Practices

1. **Choose appropriate thread count** based on workload type
2. **Handle errors** in parallel script blocks
3. **Limit memory usage** by processing in batches for large datasets
4. **Use timeouts** to prevent hung jobs
5. **Test sequential first** before parallelizing
6. **Monitor resource usage** during parallel execution
7. **Clean up jobs** properly after completion

## Troubleshooting

### Jobs hang or timeout
- Reduce MaxThreads to lower system load
- Implement proper timeouts in script blocks
- Check for deadlocks or resource contention

### Memory issues
- Process items in smaller batches
- Reduce MaxThreads
- Dispose of large objects in script blocks

### Inconsistent results
- Ensure script blocks don't depend on shared state
- Verify thread safety of operations
- Use proper synchronization if needed

## Version History

- **1.0.0**: Initial release with runspace-based parallel execution

## Related Modules

- [TestingFramework](../TestingFramework/) - Uses ParallelExecution for test parallelization
- [LabRunner](../LabRunner/) - Can use ParallelExecution for lab operations
- [Logging](../Logging/) - Thread-safe logging for parallel operations

## Contributing

When adding parallel execution features:

1. Ensure thread safety
2. Implement proper cleanup
3. Test with various thread counts
4. Include comprehensive error handling
5. Update this README with new functionality
