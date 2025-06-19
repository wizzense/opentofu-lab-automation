---
mode: 'agent'
tools: ['codebase']
description: 'Guide for running comprehensive tests in the project'
---

Provide guidance for running the bulletproof test suite based on the current context and files.

Available test commands:
- `pwsh ./tests/Run-BulletproofTests.ps1 -TestSuite Quick` - 5 minute smoke tests
- `pwsh ./tests/Run-BulletproofTests.ps1 -TestSuite Core` - 10 minute core functionality
- `pwsh ./tests/Run-BulletproofTests.ps1 -TestSuite All` - 30+ minute comprehensive testing
- `pwsh ./test-noninteractive-fix.ps1 -TestMode All` - Non-interactive mode validation

Test suites available:
- **Quick**: Essential smoke tests (5 minutes)
- **Core**: Core functionality tests (10 minutes)
- **Modules**: Module-specific tests (15 minutes)
- **Integration**: Cross-component testing (20 minutes)
- **Performance**: Performance benchmarks (25 minutes)
- **All**: Complete system validation (30+ minutes)
- **NonInteractive**: Non-interactive mode validation (3 minutes)

Based on the current context, recommend:
1. Which test suite to run
2. Any specific parameters needed
3. Expected execution time
4. Where to find results

Reference [testing-workflows.instructions.md](../instructions/testing-workflows.instructions.md) for detailed testing patterns.
