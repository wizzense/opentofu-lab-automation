# GitHub Environment Variables

This page summarizes useful environment variables that GitHub Actions exposes during a workflow run. These variables help actions and scripts locate the repository files and communicate between steps.

| Variable | Purpose |
|---------|---------|
| `GITHUB_WORKSPACE` | Absolute path to the checked-out repository. Use this to resolve files regardless of the current working directory. |
| `GITHUB_ACTION` | Name of the currently running action. |
| `GITHUB_ACTION_PATH` | Filesystem path to the action if running a composite or JavaScript action. |
| `GITHUB_ENV` | File path for appending environment variables that subsequent steps can read. |
| `GITHUB_OUTPUT` | File path for writing action output parameters. |
| `GITHUB_STEP_SUMMARY` | Markdown summary file for the current step. |
| `GITHUB_REF` | Branch or tag ref that triggered the run. |
| `GITHUB_SHA` | Commit SHA associated with the triggering event. |
| `RUNNER_OS` | Operating system of the runner (`Linux`, `Windows`, or `macOS`). |

To define an output variable from a script, write to `GITHUB_OUTPUT`:

```bash
echo "artifact-path=$GITHUB_WORKSPACE/out" >> "$GITHUB_OUTPUT"
```

To persist new environment variables for later steps:

```bash
echo "MY_CACHE=$RUNNER_TEMP/cache" >> "$GITHUB_ENV"
```

GitHub updates these files automatically so subsequent steps can reference the values using the `$MY_CACHE` syntax.
