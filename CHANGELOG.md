# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Engineering Design Integration**: Formalized the core architecture based on the Engineering Design Document.
    - Added **ADR-0002**: Standardized on `RawSocket` for byte-level protocol control.
    - Defined the **State-Machine Framework** for negotiation management.
    - Implemented a **Plugin-Based Probing Architecture** for RFC-specific modules.
    - Adopted a **Library-First** project structure to support CLI and future GUI consumers.
- **Core Project Documentation**: Integrated high-level project vision, "Active Prober" architectural model, and target audience definitions into the README and Handbook.
- **Documentation Architecture**: Implemented a progressive context loading architecture.
    - Added `AGENTS.md` for AI assistant instructions.
    - Added `docs/handbook/` for authoritative developer guidance.
    - Added `docs/adr/` for recording architectural decisions.
    - Added `docs/working-notes/` for exploratory notes.
    - Added folder-level `AGENTS.md` in `bin/`.
- **Initial ADR**: Created `ADR-0001` to record the adoption of the documentation architecture.

### Changed

- Updated `README.md` to reflect the new documentation structure and project status.
- Updated `CHANGELOG.md` to follow the "Keep a Changelog" format.
