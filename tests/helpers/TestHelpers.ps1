
# Helper utilities for Pester tests.
# To avoid cross-test pollution, remove any mocked global functions in an AfterEach block.
# Example:
#     AfterEach { Remove-Item Function:npm -ErrorAction SilentlyContinue }

$SkipNonWindows = $IsLinux -or $IsMacOS

