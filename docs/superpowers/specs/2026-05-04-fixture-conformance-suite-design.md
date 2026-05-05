# Design Spec: Fixture-Based Conformance Suite (Library Self-Tests)

## Objective
Build a robust self-testing infrastructure for the Telnet/MUD testing library. This suite will use YAML-based "golden transcripts" to prove that the library's parsers, matchers, and execution engines correctly identify both valid and invalid protocol behaviors. It serves as the foundation for the protocol conformance tests that will eventually be exposed to users.

## 1. Architecture & Directory Structure
The self-test infrastructure will be organized within the `test/` directory to ensure clear separation of concerns:
- `test/golden/`: Stores the YAML transcript fixtures.
- `test/infrastructure/`: Contains the test harness logic (`FixtureParser`, `TranscriptRunner`).
- `test/fake_servers/`: Houses minimal Dart raw socket servers (both compliant and deliberately broken).
- `test/self_tests/`: Contains the `dart test` files that dynamically load fixtures and execute the verification logic.

## 2. Fixture Format (YAML)
Fixtures define the expected byte-level interactions and resulting states.

```yaml
name: "IAC Escaping Basic"
description: "Ensures parser correctly handles 0xFF 0xFF as a literal 0xFF."
steps:
  - client_sends: [0xFF, 0xFA, 0x18, 0x01, 0xFF, 0xFF, 0xFF, 0xF0] # SB TTYPE SEND IAC IAC IAC SE
  - expect_events:
      - type: "iac"
        bytes: [0xFF, 0xFA, 0x18, 0x01, 0xFF, 0xFF, 0xFF, 0xF0]
  - expect_state:
      ttype_negotiated: false
```

## 3. Test Components
- **FixtureParser**: A utility that deserializes YAML files into strongly-typed Dart models (e.g., `TranscriptFixture`, `TranscriptStep`, `ExpectedEvent`).
- **TranscriptRunner**: The execution engine that processes a `TranscriptFixture` against a target.
  - **Direct Parser Mode**: Feeds bytes directly into the `TelnetTransport` parser to assert output events and state changes.
  - **Socket Mode**: Connects to a socket target (e.g., a `FakeServer`), transmits bytes over the wire, and validates the parsed responses.
- **FakeServers**: Small, targeted servers used to validate the library's detection capabilities.
  - `GoodServer`: Complies strictly with Telnet/MUD protocols.
  - `BrokenIacServer`: Fails to escape IAC bytes properly.
  - `LoopingServer`: Induces infinite negotiation loops.

## 4. Self-Test Flow
The primary self-test suite (`test/self_tests/transcript_runner_test.dart`) will use Dart's dynamic test generation to:
1. Load all fixtures from `test/golden/`.
2. **Positive Validation**: Assert that fixtures pass when executed against the Direct Parser and the `GoodServer`.
3. **Negative Validation (Mutation Testing)**: Assert that specific fixtures fail with exact, expected error messages when executed against the deliberately broken servers, proving the library accurately detects protocol violations.
