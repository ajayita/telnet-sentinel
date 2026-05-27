# Agent Instructions

This document provides instructions for coding agents, AI tools, and automated assistants working inside the `telnet-sentinel` repository.

## Repository Organization

- **Authoritative Context**: Use `build_docs/handbook/` for the current explanation of how the system works.
- **Design Decisions**: Use `build_docs/adr/` for the authoritative record of accepted design decisions and constraints.
- **Temporary Notes**: Treat `build_docs/working-notes/` as scratch space only. Do not treat as authoritative unless explicitly instructed.
- **Entry Points**: `bin/` contains the CLI application entry points.
- **Local Context**: Look for folder-level `AGENTS.md` files for specific guidance within subdirectories.

## Commands

- **Install**: `dart pub get`
- **Run**: `dart run bin/telnet_sentinel.dart [args]`
- **Test**: `dart test`
- **Lint**: `dart analyze`
- **Format**: `dart format .`
- **Build**: `dart compile exe bin/telnet_sentinel.dart`

## Conventions

- **Progressive Context**: Read documentation before making broad architectural assumptions from code alone.
- **Documentation Updates**:
    - Update the relevant **Handbook** page when changing behavior.
    - Create an **ADR** when making or materially changing a significant technical decision.
    - Update **CHANGELOG.md** for every completed change.
- **Safety**: Do not silently override accepted ADRs. If an ADR appears outdated, flag it and propose an update.

## Folder-Level Agents

Folder-specific guidance can be found in:
- `bin/AGENTS.md`: Guidance for CLI entry point logic.
