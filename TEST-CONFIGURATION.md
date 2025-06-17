# Test Configuration for OpenTofu Lab Automation

## Test Structure

### PowerShell Tests (Pester)
- **Location**: `tests/pester/`
- **Framework**: Pester v5.x
- **Files**:
  - `BasicTests.Tests.ps1` - Core PowerShell functionality and module loading
  - `ModuleTests.Tests.ps1` - Individual module testing (UnifiedMaintenance, TestingFramework, ScriptManager)
  - `PatchManagerTests.Tests.ps1` - PatchManager function validation and syntax checking

### Python Tests (pytest)
- **Location**: `tests/pytest/`
- **Framework**: pytest
- **Environment**: Python virtual environment (`.venv/`)
- **Files**:
  - `test_basic.py` - Basic Python functionality and module structure validation
  - `test_labctl.py` - Labctl module testing

## Test Coverage

### PowerShell Modules Tested
- PASS UnifiedMaintenance (`src/pwsh/modules/UnifiedMaintenance/`)
- PASS TestingFramework (`src/pwsh/modules/TestingFramework/`)
- PASS ScriptManager (`src/pwsh/modules/ScriptManager/`)
- PASS PatchManager Functions (`src/pwsh/modules/PatchManager/Public/`)

### Python Modules Tested
- PASS labctl package (`src/python/labctl/`)
- PASS powershell_executor (`src/python/powershell_executor.py`)
- PASS Basic Python environment and imports

## Running Tests

### All Tests
```powershell
.\Run-AllTests.ps1
```

### PowerShell Tests Only
```powershell
.\Run-AllTests.ps1 -TestSuite Pester
```

### Python Tests Only
```powershell
.\Run-AllTests.ps1 -TestSuite Python
```

### Detailed Output
```powershell
.\Run-AllTests.ps1 -Detailed
```

### Manual Test Execution

#### Pester Tests
```powershell
Invoke-Pester tests/pester/ -Output Detailed
```

#### Python Tests
```powershell
& "./.venv/Scripts/python.exe" -m pytest tests/pytest/ -v
```

## Test Results (Current)

### PowerShell (Pester): 31/31 PASSED PASS
- Core Module Loading: 3/3 passed
- PatchManager Functions: 3/3 passed  
- Basic PowerShell Functionality: 3/3 passed
- UnifiedMaintenance Module: 4/4 passed
- TestingFramework Module: 3/3 passed
- ScriptManager Module: 3/3 passed
- PatchManager Function Tests: 12/12 passed

### Python (pytest): 11/11 PASSED PASS
- Basic functionality: 5/5 passed
- Labctl module tests: 6/6 passed

**Total: 42/42 tests passing (100%)**

## Test Strategy

1. **Module Existence**: Verify all expected modules and files exist
2. **Import/Load Testing**: Ensure modules can be imported/loaded without errors
3. **Syntax Validation**: Check PowerShell syntax using PSParser
4. **Content Validation**: Verify files contain expected content and structure
5. **Basic Functionality**: Test core operations and error handling

## Next Steps for Test Expansion

1. **Functional Testing**: Add tests that actually execute module functions with various inputs
2. **Integration Testing**: Test interaction between modules
3. **Error Handling**: Test error conditions and edge cases
4. **Performance Testing**: Add timing and performance benchmarks
5. **Mock Testing**: Add mocked external dependencies for isolated testing

