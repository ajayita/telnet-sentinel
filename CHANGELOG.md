# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added pre-flight reachability checks at the start of `TelnetAuditor` to fail fast and prevent infinite connect retry hangs.
- Added option negotiation rate-limiting (maximum 20 transitions/second per option) in `NegotiationStateManager` to protect against peer-initiated loop DoS attacks.
- Added timing (latency) and raw bytes historical tracking inside `AuditResult` and `TelnetTransport`.
- Added welcome-banner immunity tests, pre-flight failure check, raw bytes serialization, and FSM rate-limit tests in `test/self_tests/audit_remediation_test.dart`.
- Added ADR-0005 to record pre-publication adversarial audit remediations.
- Added programmatic package entry point `lib/telnet_sentinel.dart` to export the public API facade cleanly.

### Changed

- Added a high-level `TelnetAuditor` facade class to encapsulate socket connection lifecycle, sequential probe execution, connection teardown, and Sniffer hooks under a clean client API.
- Added new automated verification tests for all audit remediations, including memory ceiling limits (throwing `TelnetProtocolException`), true Q-method intermediate queue state transitions, and safe GMCP malformed UTF-8 parsing.
- Added ADR-0004 to record the findings remediation and the design of the `TelnetAuditor` facade.
- Added a GitHub Pages root landing page under `docs/` and a `.nojekyll` marker so the generated `docs/api/` documentation can be published cleanly.
- Added committed manual Telnet verification tooling for running the current full probe suite against a controlled local `127.0.0.1:2323` target.
- Added probe scenario self-tests with dedicated loopback `RawSocket` targets for AYT, handshake, GMCP, negotiation-loop, and malformed-IAC probe behavior.
- Added ADR-0003 to record that probe scenario tests complement, but do not replace, fixture-based transcript conformance tests.

### Changed

- Remediated low-level transport (`TelnetTransport`) buffer exhaustion (DoS) with a strict `64KB` size limit safeguard.
- Remediated socket event hangs by wrapping reading in a robust loop that fully drains all available data buffers.
- Remediated GMCP parser crash vulnerabilities by wrapping UTF-8 payload decoding in try-catch blocks and enabling `allowMalformed: true`.
- Remediated MCCP2 decompressor resource leak by retaining and explicitly closing the chunked conversion sink during transport shutdown.
- Remediated incomplete RFC 1143 Q-method implementation in the state manager by adding all six FSM states and the official state transition table.
- Remediated probe event listener crash risk (`StateError`) by adding safe completion checks to `HandshakeProbe` and `BinaryModeProbe`.
- Remediated GMCP subnegotiation byte corruption by unescaping raw double `255` IAC sequences inside subnegotiation payloads.
- Relocated the scratch diagnostic script `check_zlib.dart` to the manual verification tooling folder (`tool/manual_telnet_verification/`).
- Shifted `yaml` dependency in `pubspec.yaml` from standard `dependencies` to `dev_dependencies` to decrease transitive library footprint.
- Refactored CLI utility entry point (`bin/telnet_sentinel.dart`) to consume the high-level `TelnetAuditor` facade.
- Restored `origin/main` as the canonical baseline while preserving the divergent local self-test redesign on `backup/local-self-test-redesign`.
- Updated the testing handbook to distinguish fixture-based transcript tests from full probe scenario tests.

## [0.0.1]

### Added

- **Testing Infrastructure**:
    - Built a YAML fixture-based conformance suite for robust library self-tests.
    - Added `TranscriptRunner` for executing byte-level fixtures over real loopback sockets against mock targets.
    - Added `FixtureParser` to deserialize protocol fixtures and expected events.
    - Created deliberately broken mock servers (`BrokenIacServer`) for test framework mutation testing.
- **MUD Extensions**:
    - Added support for **MCCP2** (Zlib compression) decompression and auditing.
    - Added support for **GMCP** (Generic MUD Communication Protocol) parsing and auditing.
- **Exhaustive Core Telnet**:
    - Implemented full RFC 854 command handling (AYT, AO, IP, BRK, EL, EC).
    - Added **Binary Mode** support (RFC 856).
    - Added **Adversarial Probes** for malformed IAC sequences and negotiation loops.
- **UI & Reporting**:
    - Added **Sniffer Mode** (`--sniffer`) for real-time traffic visualization.
    - Added **JSON Output** (`--json`) for machine-readable reports.
- **Core Framework**:
    - Implemented `TelnetTransport` using `RawSocket` for byte-level control.
    - Implemented `NegotiationStateManager` with RFC 1143 Q-method loop prevention.
    - Established a plugin-based `Probe` architecture.
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
