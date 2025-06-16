# Base64 PowerShell Integration Strategy for OpenTofu Lab Automation

## Overview
This document outlines the comprehensive strategy for integrating base64 encoding throughout the OpenTofu Lab Automation project to eliminate syntax, encoding, and execution issues permanently.

## Current Infrastructure

### Existing Base64 Components
1. **CrossPlatformExecutor.ps1** - Core base64 encoding/execution engine
2. **CrossPlatformExecutor_Enhanced.ps1** - Enhanced version with working directory support
3. **enhanced_powershell_executor.py** - Python wrapper for cross-platform execution
4. **powershell_executor.py** - Python integration for base64 PowerShell execution

### Proven Success Areas
- **GitHub Actions workflows** - Successfully using base64 for complex script execution
- **Python integration** - Reliable cross-platform PowerShell execution
- **Cross-platform compatibility** - Windows/Linux/macOS execution consistency

## Integration Strategy

### Phase 1: Core Infrastructure Fixes (Immediate)

#### 1.1 Fix Critical Scripts Using Base64
**Target Scripts:**
- `infrastructure-health-check.ps1` - Complex string handling, HERE-strings
- `unified-maintenance.ps1` - Multiple nested function calls
- `fix-infrastructure-issues.ps1` - Parameter validation issues

**Implementation:**
```powershell
# Instead of direct execution:
./scripts/maintenance/infrastructure-health-check.ps1 -Mode "All"

# Use base64 encoding:
$encodedScript = ./pwsh/CrossPlatformExecutor.ps1 -Action encode -ScriptPath "./scripts/maintenance/infrastructure-health-check.ps1" -Parameters @{Mode="All"}
./pwsh/CrossPlatformExecutor.ps1 -Action execute -EncodedScript $encodedScript
```

#### 1.2 Create Base64 Wrapper Functions
```powershell
function Invoke-ScriptSafely {
    param(
        string$ScriptPath,
        hashtable$Parameters = @{},
        switch$ValidateOnly
    )
    
    $executor = "$PSScriptRoot/../pwsh/CrossPlatformExecutor.ps1"
    
    if ($ValidateOnly) {
        & $executor -Action validate -ScriptPath $ScriptPath -Parameters $Parameters
    } else {
        $encoded = & $executor -Action encode -ScriptPath $ScriptPath -Parameters $Parameters -CI
        $result = $encoded  ConvertFrom-Json
        & $executor -Action execute -EncodedScript $result.EncodedScript -CI
    }
}
```

### Phase 2: Maintenance Script Integration (Week 1)

#### 2.1 Update Unified Maintenance System
**File:** `scripts/maintenance/unified-maintenance.ps1`

**Changes:**
- Replace direct script calls with base64 execution
- Add validation before execution
- Implement rollback capability

#### 2.2 Health Check System Enhancement
**Files:**
- `infrastructure-health-check.ps1`
- `comprehensive-health-check.ps1`
- All health monitoring scripts

**Benefits:**
- Eliminate string termination issues
- Solve HERE-string corruption
- Prevent encoding problems

#### 2.3 CodeFixer Module Integration
**File:** `pwsh/modules/CodeFixer/`

**Integration Points:**
```powershell
# Add to CodeFixer module
function Invoke-PowerShellLintSafe {
    param(string$Files, switch$AutoFix)
    
    # Use base64 execution for complex linting operations
    $lintScript = "$PSScriptRoot/../../scripts/linting/comprehensive-lint.ps1"
    Invoke-ScriptSafely -ScriptPath $lintScript -Parameters @{
        Files = $Files -join ","
        AutoFix = $AutoFix.IsPresent
    }
}
```

### Phase 3: Test Framework Integration (Week 2)

#### 3.1 Pester Test Execution
**Target:** All `.Tests.ps1` files

**Implementation:**
- Encode test scripts before execution
- Prevent nested container issues
- Solve syntax validation problems

#### 3.2 Test Helper Enhancement
**File:** `tests/helpers/TestHelpers.ps1`

**New Functions:**
```powershell
function Invoke-TestSafely {
    param(string$TestPath, hashtable$Parameters = @{})
    
    # Execute tests using base64 encoding
    Invoke-ScriptSafely -ScriptPath $TestPath -Parameters $Parameters
}

function Test-ScriptSyntaxSafely {
    param(string$ScriptPath)
    
    # Validate syntax using base64 approach
    Invoke-ScriptSafely -ScriptPath $ScriptPath -ValidateOnly
}
```

### Phase 4: CI/CD Integration (Week 3)

#### 4.1 GitHub Actions Enhancement
**Files:** `.github/workflows/*.yml`

**Updates:**
- Replace complex PowerShell inline scripts with base64 calls
- Add pre-validation steps
- Implement error recovery

**Example Workflow Step:**
```yaml
- name: "Execute Maintenance Scripts Safely"
  shell: pwsh
  run: 
    $executor = "./pwsh/CrossPlatformExecutor.ps1"
    $encoded = & $executor -Action encode -ScriptPath "./scripts/maintenance/unified-maintenance.ps1" -Parameters @{Mode="All"; AutoFix=$true} -CI
    $result = $encoded  ConvertFrom-Json
    & $executor -Action execute -EncodedScript $result.EncodedScript -CI
```

#### 4.2 Cross-Platform Validation
**Integration Points:**
- Windows PowerShell 5.1 compatibility
- PowerShell 7+ on Linux/macOS
- Python wrapper integration

### Phase 5: Advanced Features (Week 4)

#### 5.1 Intelligent Script Caching
```powershell
function Get-CachedEncodedScript {
    param(string$ScriptPath, hashtable$Parameters = @{})
    
    $cacheKey = Get-FileHash $ScriptPath  Select-Object -ExpandProperty Hash
    $cacheFile = "$env:TEMP/ps-cache-$cacheKey.txt"
    
    if (Test-Path $cacheFile) {
        $cached = Get-Content $cacheFile  ConvertFrom-Json
        if ($cached.Parameters -eq ($Parameters  ConvertTo-Json)) {
            return $cached.EncodedScript
        }
    }
    
    # Generate new encoded script
    $encoded = Invoke-ScriptSafely -ScriptPath $ScriptPath -Parameters $Parameters -ValidateOnly
    @{
        EncodedScript = $encoded
        Parameters = ($Parameters  ConvertTo-Json)
        Timestamp = Get-Date
    }  ConvertTo-Json  Set-Content $cacheFile
    
    return $encoded
}
```

#### 5.2 Rollback and Recovery
```powershell
function Invoke-ScriptWithRollback {
    param(
        string$ScriptPath,
        hashtable$Parameters = @{},
        scriptblock$RollbackAction
    )
    
    $backupState = Get-ProjectState
    
    try {
        Invoke-ScriptSafely -ScriptPath $ScriptPath -Parameters $Parameters
    }
    catch {
        Write-Warning "Script execution failed, initiating rollback..."
        if ($RollbackAction) {
            & $RollbackAction
        }
        Restore-ProjectState -State $backupState
        throw
    }
}
```

## Implementation Priority

### Immediate (This Week)
1. **Fix infrastructure-health-check.ps1** using base64 encoding
2. **Update unified-maintenance.ps1** to use safe execution
3. **Create base64 wrapper functions** in LabRunner module

### Short Term (Next 2 Weeks)
1. **Integrate all maintenance scripts** with base64 execution
2. **Update test framework** to use safe execution
3. **Enhance GitHub Actions workflows** with base64 support

### Medium Term (Next Month)
1. **Add intelligent caching** for frequently executed scripts
2. **Implement comprehensive rollback** system
3. **Create monitoring and alerting** for execution failures

## Benefits

### Immediate Benefits
- **Eliminate syntax errors** caused by string escaping
- **Solve encoding issues** across platforms
- **Prevent HERE-string corruption**
- **Enable reliable cross-platform execution**

### Long-term Benefits
- **Reduce maintenance overhead** for script fixes
- **Improve CI/CD reliability** with consistent execution
- **Enable advanced features** like caching and rollback
- **Provide foundation** for future automation enhancements

## Testing Strategy

### Validation Steps
1. **Syntax validation** before encoding
2. **Cross-platform testing** on Windows/Linux/macOS
3. **Performance benchmarking** vs. direct execution
4. **Error handling validation** for edge cases

### Success Metrics
- **Zero syntax errors** in critical maintenance scripts
- **100% cross-platform compatibility** for core operations
- **< 10% performance overhead** from base64 encoding
- **Zero manual intervention** required for routine maintenance

## Migration Plan

### Week 1: Core Infrastructure
-   Fix infrastructure-health-check.ps1 using base64
-   Update unified-maintenance.ps1 integration
-   Create base64 wrapper functions
-   Test core functionality

### Week 2: Maintenance Scripts
-   Migrate all scripts in /scripts/maintenance/
-   Update LabRunner module integration
-   Enhance error handling and logging
-   Test maintenance workflows

### Week 3: Test Framework
-   Migrate Pester test execution
-   Update TestHelpers.ps1 functions
-   Enhance test validation
-   Test complete test suite

### Week 4: CI/CD and Advanced Features
-   Update GitHub Actions workflows
-   Implement caching system
-   Add rollback capabilities
-   Performance optimization

This strategy will eliminate the root causes of syntax and encoding issues while providing a robust foundation for future enhancements.
