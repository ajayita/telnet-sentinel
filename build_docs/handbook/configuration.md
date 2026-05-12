# Configuration

This page explains configuration, environment variables, and local setup assumptions.

## Runtime Configuration

The application is configured primarily through command-line arguments.

### CLI Flags

| Flag | Abbr | Description |
| :--- | :--- | :--- |
| `--help` | `-h` | Prints usage information. |
| `--verbose` | `-v` | Show additional command output during the audit. |
| `--version` | | Print the tool version. |
| `--json` | | Output the audit report as a machine-readable JSON object. |
| `--sniffer` | `-s` | Enable real-time traffic visualization during the audit. |

## Environment Variables

No environment variables are currently used. All target information (host, port) is provided via positional CLI arguments.

## Development Environment

- **Dart SDK**: ^3.11.5 is required.
- **Dependencies**: Uses `args` for CLI parsing and `test` for the test suite. No other external dependencies are required.
- **Zlib Support**: Uses `dart:io`'s native Zlib implementation for MCCP2 decompression.
