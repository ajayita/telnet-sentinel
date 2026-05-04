# Project Structure

This page describes the repository layout and the responsibilities of major folders.

## Repository Layout

```text
/
├── AGENTS.md             # Root instructions for AI assistants.
├── README.md             # Public entry point.
├── CHANGELOG.md          # Record of changes.
├── pubspec.yaml          # Project metadata and dependencies.
├── bin/                  # Application entry points.
│   └── telnet_sentinel.dart
├── docs/                 # Project documentation.
│   ├── handbook/         # Authoritative developer handbook.
│   ├── adr/              # Architecture Decision Records.
│   └── working-notes/    # Temporary/exploratory notes.
├── lib/                  # [TODO: Core library logic, once extracted from bin].
└── test/                 # Test suite.
```

## Folder Responsibilities

### `lib/`
The core of the framework.
- `lib/transport/`: `RawSocket` management and byte-level stream handling.
- `lib/state/`: The Negotiation State Manager and Telnet state machine logic.
- `lib/probes/`: The Probe Interface and RFC-specific implementations.
- `lib/models/`: Data models for audit reports and protocol states.

### `bin/`
Contains the CLI wrapper for the library. It is responsible for orchestrating audits in CI/CD environments and returning appropriate exit codes.

### `docs/`
The central hub for all project documentation. Follows the structure defined in [ADR-0001](../adr/0001-adopt-repository-documentation-architecture.md).

### `test/`
Contains unit and integration tests. Mirrors the structure of `lib/` (and `bin/` where appropriate).
