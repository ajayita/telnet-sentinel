# telnet_sentinel

A diagnostic and auditing framework designed to bridge the gap between ancient communication standards and modern software reliability. While the Telnet protocol is often dismissed as "legacy," it remains the backbone of the MUD (Multi-User Dungeon) gaming community and a critical interface for industrial IoT and high-end networking hardware.

## What the package does

*   **Active Protocol Auditing**: Systematically probes a server’s implementation of various protocol extensions (RFC 854) to ensure they are stable, compliant, and secure.
*   **Adversarial Probing**: Tests for malformed IAC sequences and negotiation loops.
*   **MUD Extensions**: Provides support for MCCP2 (Zlib compression) and GMCP (JSON out-of-band data).
*   **Traffic Visualizer**: Offers a real-time sniffer mode for debugging Telnet handshakes.
*   **Machine-Readable Reports**: Outputs native JSON reports for CI/CD integration.

## What the package does not do

*   It is not a standard interactive Telnet client for human users to play games or manage systems.
*   It does not handle terminal emulation or ANSI color code rendering.
*   It does not automatically fix server-side protocol bugs.

## Installation

```yaml
dependencies:
  telnet_sentinel:
    path: .
```

## Basic Usage

Run an audit against a target:
```bash
dart run bin/telnet_sentinel.dart example.com 23
```

Run in **Sniffer Mode** to see live traffic:
```bash
dart run bin/telnet_sentinel.dart example.com --sniffer
```

Export results as **JSON**:
```bash
dart run bin/telnet_sentinel.dart example.com --json
```

Using the library programmatically:

```dart
import 'dart:io';
import 'package:telnet_sentinel/transport/telnet_transport.dart';
import 'package:telnet_sentinel/probes/handshake_probe.dart';

Future<void> main() async {
  final socket = await RawSocket.connect('example.com', 23);
  final transport = TelnetTransport(socket);
  final probe = HandshakeProbe();

  final result = await probe.run(transport);
  print('Result: ${result.status}');

  await transport.close();
}
```

## Error handling

`telnet_sentinel` gracefully catches connection errors, malformed packets, and execution failures, returning an `AuditResult` with a `fail` status rather than crashing. Ensure you check the `hasFailures` flag in the `AuditReport`.

## Testing

Run tests with:

```bash
dart test
```

## Analysis and formatting

```bash
dart analyze
dart format .
```

## Security Note

This package handles raw network traffic, which may include sensitive data like credentials or proprietary information. Be cautious when using the `--sniffer` mode in production or logging raw protocol bytes, as they are not encrypted. Prefer analyzing JSON reports over inspecting raw packet streams manually.

## Documentation

This project uses a progressive context loading documentation architecture.

- [Developer Handbook](docs/handbook/index.md): Authoritative explanation of how the system works.
- [Architecture Decision Records (ADRs)](docs/adr/README.md): Record of significant design decisions.
- [Working Notes](docs/working-notes/README.md): Temporary and exploratory notes.
- [Changelog](CHANGELOG.md): Record of completed changes.
- [Agent Instructions](AGENTS.md): Guidance for AI assistants working in this repo.
