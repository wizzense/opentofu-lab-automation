# labctl Python CLI

The `labctl` command line tool exposes cross-platform helpers written in Python. It reads its settings from a JSON or YAML configuration file, loading `config_files/default-config.json` when no explicit path is given.

## Subcommands

### `hv facts`
Display the Hyper-V section from the configuration file:

```bash
poetry run labctl hv facts
```

Specify an alternative config file with `--config`:

```bash
poetry run labctl hv facts --config my-config.yaml
```

### `hv deploy`
Simulate deploying using the Hyper-V configuration:

```bash
poetry run labctl hv deploy
```

Provide a custom configuration path the same way:

```bash
poetry run labctl hv deploy --config path/to/config.json
```

Both commands simply parse the configuration and print details to the console at this stage.

