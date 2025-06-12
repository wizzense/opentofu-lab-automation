# Copilot Code Generation Instructions

- Always use concise, minimal diffs for code suggestions.
- When editing files, use `// ...existing code...` to indicate unchanged regions.
- For PowerShell, Python, and Markdown, start code blocks with a comment containing the filepath.
- Never repeat unchanged code; use comments to indicate context.
- Group changes by file and use clear headers.
- For new files, suggest a location under `/workspaces/opentofu-lab-automation/`.
- When generating tests, follow the project's Pester or pytest conventions.
- Use project-specific helpers and modules where available.
- For documentation, use Markdown formatting and keep instructions clear and actionable.
- Avoid including secrets, credentials, or sensitive data in any suggestion.