---
applyTo: "**/*.py"
---
# Python Coding Standards

Apply the [general coding guidelines](./general-coding.instructions.md) to all code.

- Use type hints for all function signatures.
- Use `logging` for all log output.
- Follow PEP8 and use `ruff` for linting.
- Use `pytest` for tests and prefer fixtures for setup/teardown.
- Use Poetry for dependency management.
- Place CLI entry points in `labctl/cli.py`.
