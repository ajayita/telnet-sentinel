# Security

This page documents security rules and operational cautions for `telnet-sentinel`.

## Core Security Rules

1.  **Secret Management**: NEVER commit secrets, API keys, or credentials to the repository.
2.  **Input Validation**: All external input (CLI arguments, files, network data) must be validated and sanitized before use.
3.  **Least Privilege**: The application should only require permissions necessary for its specific tasks.

## Sensitive Files

- `pubspec.yaml`: Contains dependency information. The project currently only depends on standard Dart libraries (`args`, `test`).
- `test/`: Contains the "adversarial payloads" used for probing; these should be handled with care when auditing production systems.

## Data Safety

- **Local Execution**: The application processes all Telnet traffic locally and does not transmit data to external third-party services.
- **Protocol Integrity**: Telnet Sentinel does not store user credentials or passwords. It focus solely on protocol-level auditing.
- **Adversarial Safety**: While adversarial probes are designed to test server stability, they should be used with caution against mission-critical hardware, as malformed Telnet sequences can trigger bugs in poorly implemented firmware.

## Security Audits

The framework includes built-in security probes:
- **`MalformedIacProbe`**: Tests for server-side vulnerabilities to unclosed or invalid IAC sequences.
- **`NegotiationLoopProbe`**: Audits for resource exhaustion through recursive protocol negotiations.
