# Testing

This page explains the testing strategy and commands for `telnet-sentinel`.

## Strategy

- **Unit Tests**: Test individual state transitions and byte-parsing logic.
- **Adversarial Testing**: Specifically test how the state machine and probes handle malformed `IAC` sequences or unexpected sub-negotiations.
- **Compliance Testing**: Use the Plugin-Based Probing architecture to verify RFC compliance against mock servers.

## Integration Testing
Verification that the CLI correctly reports protocol violations and exits with non-zero codes for failed audits.

## Running Tests

Run all tests:

```bash
dart test
```

## Test Location

Tests are located in the `test/` directory.

[TODO: List specific test files once created.]

## Writing Tests

- Use the `test` package.
- Follow the naming convention `*_test.dart`.
- Group related tests using `group()`.
- Ensure each test is independent and idempotent.
