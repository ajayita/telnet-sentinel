# Bin Agent Instructions

This folder contains the application entry points and CLI-specific logic.

## Responsibility

- Command-line argument definition and parsing.
- Environment setup and error handling for the CLI interface.
- Coordination of high-level application flow.

## Conventions

- Keep `main()` concise; delegate business logic to `lib/` (once established).
- Use the `args` package for all CLI interactions.
- Ensure `--help`, `--version`, and `--verbose` flags are consistently supported.
- Provide clear, user-friendly error messages for `FormatException`.

## Boundaries

- Avoid implementing core business logic directly in `bin/`.
- Do not perform direct file system or network operations here if they can be abstracted into a service in `lib/`.
