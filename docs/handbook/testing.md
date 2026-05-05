# Testing

This page explains the testing strategy and commands for `telnet-sentinel`.

## Strategy

- **Unit Tests**: Test individual state transitions and byte-parsing logic.
- **Adversarial Testing**: Specifically test how the state machine and probes handle malformed `IAC` sequences or unexpected sub-negotiations.
- **Compliance Testing**: Use the Plugin-Based Probing architecture to verify RFC compliance against mock servers.

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

## Running Tests

Run the full suite (52+ tests):

```bash
dart test
```

## Writing Tests

- Use the `test` package.
- **TDD Requirement**: For every new feature or bug fix, a failing test must be written first.
- **Mocking**: Use `RawServerSocket` or mock socket implementations to simulate server behavior.
- **Standardized Imports**: Always use package-level imports (e.g., `import 'package:telnet_sentinel/...'`) in test files to avoid type identity issues.
