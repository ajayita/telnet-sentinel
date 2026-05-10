# Testing

This page explains the testing strategy and commands for `telnet-sentinel`.

## Important Testing Distinction

There are two different kinds of tests involved in this project:

1. **Library self-tests**: These test the correctness of this repository’s own code (parsers, byte fixtures, transcript runners, assertion helpers, fake clients, state machines, etc.).
2. **Protocol conformance tests**: These are the tests that this library exposes to users so they can validate an external Telnet/MUD server implementation.

When adding or improving byte-level self-tests, we use a **Fixture-Based Conformance Suite**. This suite uses YAML fixtures (in `test/golden/`) run via `TranscriptRunner` against mock targets (in `test/fake_servers/`). This ensures the library correctly detects valid and invalid protocol behavior (mutation testing).

Probe-level self-tests use a separate **Probe Scenario** layer. These tests run full probes through `TelnetTransport` against realistic loopback `RawSocket` targets. Probe scenarios validate end-to-end probe behavior; they do not replace YAML fixtures, transcript assertions, or mutation servers.

## Strategy

- **Unit Tests**: Test individual state transitions and byte-parsing logic.
- **Adversarial Testing**: Specifically test how the state machine and probes handle malformed `IAC` sequences or unexpected sub-negotiations.
- **Compliance Testing**: Use the Plugin-Based Probing architecture to verify RFC compliance against mock servers.
- **Fixture-Based Transcript Testing**: Treat YAML fixtures, `FixtureParser`, and `TranscriptRunner` as the canonical path for byte-level parser and conformance harness behavior.
- **Probe Scenario Testing**: Use named probe scenario servers for reusable end-to-end checks of active probes against loopback targets.

## Integration Testing
Verification that the CLI correctly reports protocol violations and exits with non-zero codes for failed audits.

## Test Categories

### 1. Transport Layer Tests
Verify byte-level parsing, sub-negotiation boundaries, and Zlib decompression.
- `test/transport/telnet_transport_test.dart`
- `test/transport/mccp_transport_test.dart`
- `test/transport/gmcp_parser_test.dart`

### 2. State Management Tests
Ensure RFC-compliant negotiation transitions and loop prevention.
- `test/state/negotiation_state_manager_test.dart`

### 3. Probe Tests
Verify the logic of each active auditing module against mock servers.
- `test/probes/handshake_probe_test.dart`
- `test/probes/ayt_probe_test.dart`
- `test/probes/binary_mode_probe_test.dart`
- `test/probes/mccp_probe_test.dart`
- `test/probes/gmcp_probe_test.dart`
- `test/probes/malformed_iac_probe_test.dart`
- `test/probes/negotiation_loop_probe_test.dart`

### 4. Model Tests
Verify data consistency and serialization.
- `test/models/audit_report_test.dart`
- `test/models/json_serialization_test.dart`

### 5. Fixture-Based Conformance Tests
Verify exact byte transcripts and fixture infrastructure behavior.
- `test/infrastructure/fixture_parser_test.dart`
- `test/infrastructure/transcript_runner_test.dart`
- `test/fake_servers/server_test.dart`
- `test/golden/iac_escape.yaml`

### 6. Probe Scenario Tests
Verify full probe behavior against realistic loopback targets without redefining fixture semantics.
- `test/self_tests/probe_scenario_test.dart`
- `test/fake_servers/probe_scenario_servers.dart`

## Running Tests

Run the full suite:

```bash
dart test
```

## Writing Tests

- Use the `test` package.
- **TDD Requirement**: For every new feature or bug fix, a failing test must be written first.
- **Mocking**: Use `RawServerSocket` or mock socket implementations to simulate server behavior.
- **Standardized Imports**: Always use package-level imports (e.g., `import 'package:telnet_sentinel/...'`) in test files to avoid type identity issues.
- Keep fixture servers focused on transcript conformance. Add or update probe scenario servers only when the assertion is about full probe behavior.
