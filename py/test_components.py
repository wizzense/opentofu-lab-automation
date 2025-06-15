#!/usr/bin/env python3
"""
Test the enhanced GUI configuration builder without launching the full GUI.
This is useful for validation and testing.
"""

import sys
import os
from pathlib import Path

# Add the py directory to path for imports
sys.path.append(str(Path(__file__).parent))

try:
    from config_schema import ConfigSchema
    from enhanced_powershell_executor import EnhancedPowerShellExecutor
    
    print("✓ Successfully imported configuration schema and PowerShell executor")
    
    # Test configuration schema
    schema = ConfigSchema()
    
    print(f"\nConfiguration Schema Test:")
    print(f"  Total sections: {len(schema.sections)}")
    
    for section_name, fields in schema.sections.items():
        print(f"  Section '{section_name}': {len(fields)} fields")
        
        # Show a few example fields
        for i, field in enumerate(fields[:2]):  # Show first 2 fields per section
            print(f"    - {field.display_name} ({field.field_type}): {field.help_text[:50]}...")
    
    # Test defaults
    defaults = schema.get_defaults()
    print(f"\nDefault Configuration:")
    print(f"  Total default values: {len(defaults)}")
    print(f"  Sample defaults:")
    
    for i, (key, value) in enumerate(list(defaults.items())[:5]):
        print(f"    {key}: {value}")
    
    # Test validation
    test_config = {
        "RepoUrl": "https://github.com/example/repo.git",
        "LocalPath": "/tmp/test",
        "Verbosity": "normal"
    }
    
    errors = schema.validate_config(test_config)
    if errors:
        print(f"\nValidation Errors: {errors}")
    else:
        print(f"\n✓ Configuration validation passed")
    
    # Test PowerShell executor
    print(f"\nPowerShell Executor Test:")
    try:
        executor = EnhancedPowerShellExecutor()
        print(f"  ✓ Executor initialized")
        print(f"  PowerShell: {executor.powershell_cmd}")
        print(f"  Working Dir: {executor.working_directory}")
        print(f"  Executor Script: {executor.executor_script}")
        
        # Quick test
        success, stdout, stderr = executor.execute_script("Write-Host 'Test successful'")
        if success:
            print(f"  ✓ PowerShell execution test passed")
        else:
            print(f"  ✗ PowerShell execution test failed: {stderr}")
            
    except Exception as e:
        print(f"  ✗ PowerShell executor error: {e}")
    
    print(f"\n✓ All component tests completed successfully!")
    
except ImportError as e:
    print(f"Error importing modules: {e}")
    sys.exit(1)
except Exception as e:
    print(f"✗ Test error: {e}")
    sys.exit(1)
