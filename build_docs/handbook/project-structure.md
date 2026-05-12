# Project Structure

This page describes the repository layout and the responsibilities of major folders.

## Repository Layout

```text
/
├── AGENTS.md             # Root instructions for AI assistants.
├── README.md             # Public entry point and project overview.
├── CHANGELOG.md          # Record of changes and milestones.
├── TODO.md               # Tracking of implementation progress (Phase 1-7 COMPLETE).
├── pubspec.yaml          # Project metadata and dependencies.
├── bin/                  # Application entry points.
│   ├── telnet_sentinel.dart # Main CLI wrapper.
│   └── AGENTS.md         # CLI-specific agent instructions.
├── docs/                 # Project documentation hub.
│   ├── handbook/         # Authoritative developer handbook.
│   ├── adr/              # Architecture Decision Records.
│   ├── working-notes/    # Exploratory and planning notes.
│   └── superpowers/      # Detailed implementation plans.
├── lib/                  # Core framework library.
│   ├── models/           # Data models for events, results, and reports.
│   ├── probes/           # Active auditing probes and interfaces.
│   ├── state/            # Negotiation state machine logic.
│   └── transport/        # Low-level socket and protocol parsing.
└── test/                 # Comprehensive test suite (Unit and Integration).
```

## Folder Responsibilities

### `lib/`
The core framework, designed with a library-first approach.
- `lib/transport/`: Manages `RawSocket` events and parses the byte stream into `TelnetEvent` objects. Includes specialized parsers for GMCP.
- `lib/state/`: Implements the Telnet negotiation state machine (RFC 1143).
- `lib/probes/`: Contains the `Probe` interface and implementations for various audits (Handshake, MCCP, GMCP, etc.).
- `lib/models/`: Defines the data structures used throughout the application.

### `bin/`
Contains the CLI wrapper for the library. It is responsible for orchestrating audits in CI/CD environments and returning appropriate exit codes.

### `docs/`
The central hub for all project documentation. Follows the structure defined in [ADR-0001](../adr/0001-adopt-repository-documentation-architecture.md).

### `test/`
Contains unit and integration tests. Mirrors the structure of `lib/` (and `bin/` where appropriate).
