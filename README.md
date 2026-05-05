# telnet-sentinel

**Telnet Sentinel** is a diagnostic and auditing framework designed to bridge the gap between ancient communication standards and modern software reliability. While the Telnet protocol is often dismissed as "legacy," it remains the backbone of the MUD (Multi-User Dungeon) gaming community and a critical interface for industrial IoT and high-end networking hardware.

## Project Vision

The primary objective of this tool is **Active Integrity Verification**. Unlike a standard Telnet client that simply tries to connect and display text, Telnet Sentinel acts as a "synthetic auditor." It systematically probes a server’s implementation of various protocol extensions to ensure they are stable, compliant, and secure.

## Who Is This For?

*   **MUD Developers**: To ensure that players using different clients (from 1990s software to modern mobile apps) all have a consistent, crash-free experience.
*   **IoT & Hardware Engineers**: To verify that the "hidden" Telnet interfaces on factory controllers or network switches are not vulnerable to protocol-level exploits.
*   **Quality Assurance (QA) Teams**: To automate "health checks" in production environments, ensuring that a server update hasn't accidentally broken communication standards.

## Project Status

- **Version**: 0.0.1
- **Status**: Core "Active Prober" framework complete.

## Key Features

- **Active Protocol Auditing**: Exhaustive RFC 854 compliance checks.
- **Adversarial Probing**: Tests for malformed IAC sequences and negotiation loops.
- **MUD Extensions**: Full support for **MCCP2** (Zlib compression) and **GMCP** (JSON out-of-band data).
- **Traffic Visualizer**: Real-time sniffer mode for debugging Telnet handshakes.
- **Machine-Readable Reports**: Native JSON output for CI/CD integration.

## Installation

```bash
dart pub get
```

## Usage

Run an audit against a target:
```bash
dart run bin/telnet_sentinel.dart <host> [port]
```

Run in **Sniffer Mode** to see live traffic:
```bash
dart run bin/telnet_sentinel.dart <host> --sniffer
```

Export results as **JSON**:
```bash
dart run bin/telnet_sentinel.dart <host> --json
```

## Documentation

This project uses a progressive context loading documentation architecture.

- [Developer Handbook](docs/handbook/index.md): Authoritative explanation of how the system works.
- [Architecture Decision Records (ADRs)](docs/adr/README.md): Record of significant design decisions.
- [Working Notes](docs/working-notes/README.md): Temporary and exploratory notes.
- [Changelog](CHANGELOG.md): Record of completed changes.
- [Agent Instructions](AGENTS.md): Guidance for AI assistants working in this repo.

## Development

See [Getting Started](docs/handbook/getting-started.md) in the handbook for setup and development commands.
