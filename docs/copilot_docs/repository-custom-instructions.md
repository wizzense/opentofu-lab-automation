# Repository Custom Instructions for GitHub Copilot

This guide explains how to provide GitHub Copilot with additional context for this repository.

## Overview

Repository custom instructions let you store project guidelines in `.github/copilot-instructions.md`. These instructions are automatically included with Copilot Chat prompts on GitHub.com, Visual Studio, and VS Code.

## Creating the instructions file

1. In the root of the repository, create `.github/copilot-instructions.md`.
2. Add short, self-contained instructions in Markdown.
3. Save the file to immediately enable the instructions for Copilot.

### Example

```
We use Bazel instead of Maven, so reference Bazel commands for Java builds.
Use double quotes and tabs for JavaScript code samples.
All tasks are tracked in Jira.
```

## Tips for writing instructions

- Keep each instruction concise and avoid conflicting guidelines.
- Avoid large external references for complex repositories.
- Use blank lines to improve readability; whitespace is ignored.

For more background see GitHub's "Adding repository custom instructions for GitHub Copilot" documentation.

## Using Repository Instructions

You can toggle repository instructions in Copilot Chat. Click the **gear** icon in the chat panel and choose **Enable custom instructions** or **Disable custom instructions**. When enabled, the contents of `.github/copilot-instructions.md` are automatically appended to your prompts so Copilot responds with project-specific guidance.
